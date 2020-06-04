#!/usr/bin/perl -w
#
# VHostManage by Uwe Gehring <uwe@imap.cc>
# is based upon
#
# a2enmod by Stefan Fritsch <sf@debian.org>
# Licensed under Apache License 2.0
#

use strict;
use Cwd 'realpath';
use File::Spec;
use File::Basename;
use File::Path;
use 5.014;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';


my $basename       = basename($0);
$basename          =~ /^VHost(Manage|Enable|Disable)((?:-.+)?)$/ or die "$basename call name unknown\n";
my $act            = $1;
my $obj            = "site";
my $name           = ucfirst($obj);
my $dir            = 'sites';
my $sffx           = '.conf';
my $confdir        = "/home/uwe/.apache2";
my $availdir       = "$confdir/$dir-available";
my $enabldir       = "$confdir/$dir-enabled";
my $choicedir      = $act eq 'Enable' ? $availdir : $enabldir;
my $linkdir        = File::Spec->abs2rel( $availdir, $enabldir );
my $request_reload = 0;
my $rc             = 0;

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
      if ( $act eq 'Disable' ) {
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

  if ( $act eq 'Enable' ) {
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
