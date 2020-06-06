#! /usr/bin/perl
#
# vhostquery by Uwe Gehring <adspectus@fastmail.com>
# is based upon:
#
# a2query - Apache2 helper to retrieve configuration informations
# Copyright (C) 2012 Arno Töll <debian@toell.net>
#
# This program is licensed at your choice under the terms of the GNU General
# Public License version 2+ or under the terms of the Apache Software License
# 2.0.
#
# For GPL-2+:
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
# USA.
#
# For ASF 2.0:
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

use strict;
use Getopt::Std;

=head1 NAME

vhostquery - retrieve user specific runtime configuration from a local Apache 2 HTTP server

=cut

our $CONFIG_DIR   = $ENV{HOME}."/apache2";
our $QUIET        = 0;
our $E_OK         = '0';
our $E_NOTFOUND   = '1';
our @RETVALS      = ( $E_OK, $E_NOTFOUND );
our @CONFS        = ();
our @SITES        = ();
our @HELP         = ();

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

=head1 EXIT CODES

B<vhostquery> returns with a zero (S<0>) exit status if the requested operation was effectuated successfully and with a non-zero status otherwise.

=head1 SEE ALSO

L<a2query>(1), L<apache2ctl>(8), L<apache2>(8), L<perl>(1)

=head1 AUTHOR

This manual and L<vhostquery> was written by Uwe Gehring (adspectus@fastmailcom) based upon L<a2query> and the manual by Arno Toell <debian@toell.net>.

=cut

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

  $pattern =~ s/\.conf//;
  my @candidates;

  if ($pattern) { @candidates = grep { $_ eq $pattern } @{ $listref } }
  else { @candidates = @{ $listref } }

  my $matches = 0;
  foreach my $module (@candidates) {
    output("$module\n");
    $matches++;
  }

  if (!$matches) {
    my $reason = "No $type matches $pattern";
    my $retval = $E_NOTFOUND;
    fail($reason, $retval);
  }
}
