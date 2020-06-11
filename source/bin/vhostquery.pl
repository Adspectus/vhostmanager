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
# Credits: vhostquery is based upon a2query by Arno Töll <debian@toell.net>

use strict;
use Getopt::Std;

=head1 NAME

vhostquery - retrieve user specific runtime configuration from a local Apache 2 HTTP server

=head1 SYNOPSIS

B<vhostquery>  [S<-q>] [S<-c> [I<CONF>]] [S<-s> [I<SITE>]]

B<vhostquery>  [S<-h>]

=head1 DESCRIPTION

B<vhostquery> is a program designed to retrieve user specific configuration values from a locally available Apache 2 HTTP web server. 

=head1 OPTIONS

=over 4

=item S<-q>

Suppress any output. This is useful to invoke vhostquery from another script, and if only the return code is of interest.

=item S<-c> [I<CONF>]

Checks whether the configuration I<CONF> is enabled. If no argument was given, all enabled configuration files are being returned. I<CONF> is compared by string comparison by ignoring a '.conf' suffix.

=item S<-s> [I<SITE>]

Checks whether the site I<SITE> is enabled, The argument is interpreted in the same way, as for configuration files queried by the S<-c> switch.

=item S<-h>

Displays a brief summary how the program can be called and exits.

=back

=head1 ENVIRONMENT

B<vhostquery> require the user specific apache2 base directory to be F<$HOME/apache2>.

=begin comment

 However, if this does not reflect your setup, you can configure your personal apache2 directory with an environment variable named B<APACHE2USERDIR>, which is always relative to $HOME, i.e. if you put this in your .bashrc:

  export APACHE2USERDIR="some/dir"

your apache2 base directory is F<$HOME/some/dir>

=end comment

Note that the structure beneath this directory must always include the subdirectories F<conf-available>, F<conf-enabled>, F<sites-available>, and F<sites-enabled>.

=head1 EXIT CODES

B<vhostquery> returns with a zero (S<0>) exit status if the requested operation was effectuated successfully and with a non-zero status otherwise.

=head1 BUGS

Currently the user specific apache2 configuration must be located in F<$HOME/apache2>.

=head1 SEE ALSO

L<vhostmanager(1)>, L<a2query(1)>

=head1 AUTHOR

L<vhostquery> and this documentation was written by Uwe Gehring (adspectus@fastmailcom) based upon L<a2query(1)> and the manual by Arno Toell <debian@toell.net>.

=head1 CREDITS

Arno Toell <debian@toell.net> for his L<a2query(1)> program.

=cut

our $CONFIG_DIR   = $ENV{HOME} . "/" . ($ENV{APACHE2USERDIR} || "apache2");
our $QUIET        = 0;
our $E_OK         = '0';
our $E_NOTFOUND   = '1';
our @RETVALS      = ( $E_OK, $E_NOTFOUND );
our @CONFS        = ();
our @SITES        = ();
our @HELP         = ();


my %opts;
my $help = 1;
getopts('s:c:hq', \%opts);

push @HELP, ["q", "suppress any output. Useful for invocation from scripts"];
if (exists $opts{'q'}) {
  --$help;
  $QUIET=1;
}

push @HELP, ["c [CONF]", "checks whether the configuration CONF is enabled, lists all configurations if no argument was given"];
if (exists $opts{'c'}) {
  --$help;
  load_conf();
  query_state('conf', $opts{'c'}, \@CONFS);
}

push @HELP, ["s [SITE]", "checks whether the site SITE is enabled, lists all sites if no argument was given"];
if (exists $opts{'s'}) {
  --$help;
  load_sites();
  query_state('site', $opts{'s'}, \@SITES);
}

push @HELP, ["h", "display this help"];
if (exists $opts{'h'} or $help == 1) {
  my $usage = "$0 ";
  map { $usage .= "-$_->[0] " } @HELP;
  print("Usage: $usage\n");
  my $switch_name;
  my $description;
  format STDOUT =
@<<<<<<<<<<<<	^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"-$switch_name",        $description,
~~	        ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      $description,
.
  foreach my $switch (@HELP) {
    ($switch_name, $description) = ($switch->[0], $switch->[1]);
    write STDOUT;
  }
  exit $E_OK;
}

exit $E_OK;

sub output {
  print @_ unless $QUIET;
}

sub warning {
  print STDERR @_ unless $QUIET;
}

sub fail {
  die('usage: fail($reason, $retval)') if @_ != 2;
  my $reason = shift;
  my $retval = shift;
  warning "$reason\n";
  exit $retval;
}

sub load_conf {
  return if ($#CONFS >= 0);
  my $conf_dir = $CONFIG_DIR . "/conf-enabled";
  opendir(DIR, $conf_dir) || fail("$conf_dir: $!", 1);
  while ( readdir(DIR) ) {
    my $file = $_;
    next if $file !~ m/\.conf$/;
    $file =~ s/\.conf$//;
    push @CONFS, $file;
  }
  closedir(DIR);
}

sub load_sites {
  return if ($#SITES >= 0);
  my $conf_dir = $CONFIG_DIR . "/sites-enabled";
  opendir(DIR, $conf_dir) || fail("$conf_dir: $!", 1);
  while ( readdir(DIR) ) {
    my $file = $_;
    next if $file !~ m/\.conf$/;
    $file =~ s/\.conf$//;
    push @SITES, $file;
  }
  closedir(DIR);
}

sub query_state {
  my $type    = shift;
  my $pattern = shift;
  my $listref = shift;

  my @candidates;

  if ($pattern) {
    $pattern =~ s/\.conf//;
    @candidates = grep { $_ eq $pattern } @{ $listref }
  }
  else {
    @candidates = @{ $listref };
  }

  if (scalar(@candidates)) {
    output("$_\n") foreach (@candidates);
  }
  else {
    fail("No $type matches $pattern",$E_NOTFOUND);
  }
}
