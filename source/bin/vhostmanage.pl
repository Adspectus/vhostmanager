#!/usr/bin/perl -w
#
# Copyright 2020 Uwe Gehring <adspectus@fastmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Credits: vhostmanage is based upon a2enmod by Stefan Fritsch <sf@debian.org>

use strict;
use Cwd 'realpath';
use File::Spec;
use File::Basename;
use 5.014;

=head1 NAME

vhostenconf, vhostdisconf - enable or disable a user specific apache2 configuration

vhostensite, vhostdissite - enable or disable a user specific apache2 site/virtual host

=head1 SYNOPSIS

B<vhostenconf>  [I<CONF>]

B<vhostdisconf>  [I<CONF>]

B<vhostensite>  [I<SITE>]

B<vhostdissite>  [I<SITE>]

=head1 DESCRIPTION

B<vhostenconf>, B<vhostdisconf>, B<vhostensite>, and B<vhostdissite> are programs designed to enable or disable user specific apache2 configurations or user specific apache2 sites (which contains a <VirtualHost> block).

The B<vhosten*> programs do this by creating symlinks within F<$HOME/apache2/{conf,sites}-enabled> directories to the real files in F<$HOME/apache2/{conf,sites}-available> directories. Likewise, the B<vhostdis*> programs remove those symlinks.

It  is  not  an  error to enable a conf or site which is already enabled, or to disable one which is already disabled.

Thus, the meaning of these programs are much the same as their L<a2enconf(1)>, L<a2disconf(1)>, L<a2ensite(1)>, L<a2dissite(1)> counterparts from the apache2 package, except that they do their work in F<$HOME/apache2> instead of F</etc/apache2>. There is no B<vhostenmod> and B<vhostdismod> program, as it would not make sense for a user to enable or disable apache2 modules.

=head1 OPTIONS

=over 4

=item [I<CONF>]

Enables or disables the configuration I<CONF>.

=item [I<SITE>]

Enables or disables the site I<SITE>.

=back

If no configuration or site was given, all programs show the possible configuration(s) or site(s) to enable or disable. You can also use the <TAB> completion feature by the shell.

=head1 ENVIRONMENT

B<vhostenconf>, B<vhostdisconf>, B<vhostensite>, and B<vhostdissite> require the user specific apache2 base directory to be F<$HOME/apache2>.

=begin comment

 However, if this does not reflect your setup, you can configure your personal apache2 directory with an environment variable named B<APACHE2USERDIR>, which is always relative to $HOME, i.e. if you put this in your .bashrc:

  export APACHE2USERDIR="some/dir"

your apache2 base directory is F<$HOME/some/dir>

=end comment

Note that the structure beneath this directory must always include the subdirectories F<conf-available>, F<conf-enabled>, F<sites-available>, and F<sites-enabled>.

=head1 FILES

There is only one perl script named F<vhostmanage.pl> in F</usr/share/vhostmanager> directory to which the programs B<vhostenconf>, B<vhostdisconf>, B<vhostensite>, and B<vhostdissite> are symlinked to. This is almost similar to the B<a2*> programs, which are symlinks to the F<a2enmod> perl script.

=head1 BUGS

Currently the user specific apache2 configuration must be located in F<$HOME/apache2>.

=head1 SEE ALSO

L<a2enconf(1)>, L<a2disconf(1)>, L<a2ensite(1)>, and L<a2dissite(1)>

=head1 AUTHOR

F<vhostmanage.pl> and this documentation was written by Uwe Gehring (adspectus@fastmailcom) based upon F<a2enmod> and the manual by Stefan Fritsch <sf@debian.org>.

=head1 CREDITS

Stefan Fritsch <sf@debian.org> for his L<a2enmod(1)> program.

=cut


my $basename       = basename($0);
$basename          =~ /^vhost(en|dis)(site|conf)((?:-.+)?)$/ or die "$basename call name unknown\n";
my $act            = $1 . 'able';
my $obj            = $2;
my $confdir        = $ENV{HOME} . "/" . ($ENV{APACHE2USERDIR} || "apache2");
my $name           = ucfirst($obj);
my $sffx           = '.conf';
my $reload         = 'reload';
my $request_reload = 0;
my $rc             = 0;
my $dir            = $obj;
$dir = 'sites' if ($obj eq 'site');
my $availdir       = "$confdir/$dir-available";
my $enabldir       = "$confdir/$dir-enabled";
my $choicedir      = $act eq 'enable' ? $availdir : $enabldir;
my $linkdir        = File::Spec->abs2rel( $availdir, $enabldir );

if ( !scalar @ARGV ) {
  my @choices = myglob('*');
  print "Your choices are: @choices\n";
  print "Which ${obj}(s) do you want to $act (wildcards ok)?\n";
  my $input = <>;
  @ARGV = split /\s+/, $input;
}

my @objs;
foreach my $arg (@ARGV) {
  $arg =~ s/${sffx}$//;
  my @glob = myglob($arg);
  if ( !@glob ) {
    error("No $obj found matching $arg!\n");
    $rc = 1;
  }
  else {
    push @objs, @glob;
  }
}

foreach my $acton (@objs) {
  doit($acton) or $rc = 1;
}

my $apache_reload = "";
if (is_systemd()) {
  $apache_reload = "  systemctl reload apache2\n";
} else {
  $apache_reload = "  service apache2 reload\n";
}
info("To activate the new configuration, you need to run:\n" . $apache_reload) if $request_reload;

exit($rc);

##############################################################################

sub myglob {
  my $arg = shift;

  my @glob = map {
    s{^$choicedir/}{};
    s{$sffx$}{};
    $_
  } glob("$choicedir/$arg$sffx");

  return @glob;
}

sub doit {
  my $acton = shift;
  my ( $conftgt, $conflink );

  my $tgt  = "$availdir/$acton$sffx";
  my $link = "$enabldir/$acton$sffx";

  if ( !-e $tgt ) {
    if ( -l $link && !-e $link ) {
      if ( $act eq 'disable' ) {
        info("removing dangling symlink $link\n");
        unlink($link);

        # force a .conf path. It may exist as dangling link, too
        $conflink = "$enabldir/$acton.conf";

        if ( -l $conflink && !-e $conflink ) {
            info("removing dangling symlink $conflink\n");
            unlink($conflink);
        }

        return 1;
      }
      else {
        error("$link is a dangling symlink!\n");
      }
    }

    error("$name $acton does not exist!\n");
    return 0;
  }

  if ( $act eq 'enable' ) {
    my $check = check_link( $tgt, $link );
    if ( $check eq 'ok' ) {
      if ($conflink) {
        # handle .conf file
        my $confcheck = check_link( $conftgt, $conflink );
        if ( $confcheck eq 'ok' ) {
          info("$name $acton already enabled\n");
          return 1;
        }
        elsif ( $confcheck eq 'missing' ) {
          print "Enabling config file $acton.conf.\n";
          add_link( $conftgt, $conflink ) or return 0;
        }
        else {
          error("Config file $acton.conf not properly enabled: $confcheck\n");
          return 0;
        }
      }
      else {
        info("$name $acton already enabled\n");
        return 1;
      }
    }
    elsif ( $check eq 'missing' ) {
      if ($conflink) {
        # handle .conf file
        my $confcheck = check_link( $conftgt, $conflink );
        if ( $confcheck eq 'missing' ) {
          add_link( $conftgt, $conflink ) or return 0;
        }
        elsif ( $confcheck ne 'ok' ) {
          error("Config file $acton.conf not properly enabled: $confcheck\n");
          return 0;
        }
      }

      print "Enabling $obj $acton.\n";
      return add_link( $tgt, $link );
    }
    else {
      error("$name $acton not properly enabled: $check\n");
      return 0;
    }
  }
  else {
    if ( -e $link || -l $link ) {
      remove_link($link);
      if ( $conflink && -e $conflink ) {
        remove_link($conflink);
      }
      print "$name $acton disabled.\n";
    }
    elsif ( $conflink && -e $conflink ) {
      print "Disabling stale config file $acton.conf.\n";
      remove_link($conflink);
    }
    else {
      info("$name $acton already disabled\n");
      return 1;
    }
  }
  return 1;
}

sub add_link {
  my ( $tgt, $link ) = @_;
  # create relative link
  if ( !symlink( File::Spec->abs2rel( $tgt, dirname($link) ), $link ) ) {
    die("Could not create $link: $!\n");
  }
  $request_reload = 1;
  return 1;
}

sub check_link {
  my ( $tgt, $link ) = @_;
  if ( !-e $link ) {
    if ( -l $link ) {
      # points to nowhere
      info("Removing dangling link $link");
      unlink($link) or die "Could not remove $link\n";
    }
    return 'missing';
  }

  return "$link is a real file, not touching it" if ( -e $link && !-l $link );
  return "$link exists but does not point to $tgt, not touching it" if (realpath($link) ne realpath($tgt));
  return 'ok';
}

sub remove_link {
  my ($link) = @_;
  if ( -l $link ) {
    unlink($link) or die "Could not remove $link: $!\n";
  }
  elsif ( -e $link ) {
    error("$link is not a symbolic link, not deleting\n");
    return 0;
  }
  $request_reload = 1;
  return 1;
}

sub info {
  print @_;
}

sub error {
  print STDERR 'ERROR: ', @_;
}

sub warning {
  print STDERR 'WARNING: ', @_;
}

sub is_systemd {
  my $init = readlink("/proc/1/exe") || "";
  return scalar $init =~ /systemd/;
}
