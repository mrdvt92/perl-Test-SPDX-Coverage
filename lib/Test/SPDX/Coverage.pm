package Test::SPDX::Coverage;
use strict;
use warnings;
use License::SPDX;
use Test::Builder;
use base qw{Exporter};

# SPDX-License-Identifier: MIT

our $VERSION = '0.01';
our @EXPORT  = qw{spdx_coverage_ok};

=head1 NAME

Test::SPDX::Coverage - Perl Test Harness to verify all matched files in Manifest have a SPDX-License-Identifier

=head1 SYNOPSIS

  #File: t/spdx-coverage.t
  use Test::More;
  eval "use Test::SPDX::Coverage";
  plan skip_all => "Test::SPDX::Coverage required for testing SPDX-License-Identifier coverage" if $@;
  spdx_coverage_ok();

=head1 DESCRIPTION

Test::SPDX::Coverage reads your manifest for all .pm, .pl, .cgi files than searches for a SPDX-License-Identifier.  Once found, the License specified on the SPDX-License-Identifier line is extracted and verified against the L<License::SPDX> database.

For Perl source code, the SPDX-License-Identifier must be formatted like this:

  # SPDX-License-Identifier: LICENSE

Examples:

  # SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later
  # SPDX-License-Identifier: MIT

Essentially, this is a wrapper around License::SPDX->new->check_license($license_string, {check_type => "name"}) for all Perl files in your MANIFEST.

=head2 EXPORT

=head3 spdx_coverage_ok

  spdx_coverage_ok();
  spdx_coverage_ok({diag => 99}); #diag level 0-9
  spdx_coverage_ok({manifest => "MANIFEST", match=>qr/\.(?:pm|pl|cgi)\Z/, lines=>500, diag => 0}); #defaults 

=cut

sub spdx_coverage_ok {
  my $opt = shift    || {};
  die("Syntax: spdx_coverage_ok() or spdx_coverage_ok({})") unless ref($opt) eq 'HASH';

  $opt->{'manifest'} ||= "MANIFEST";
  die(sprintf('Error: option "manifest" invalid. File "%s" not found.'   , $opt->{'manifest'})) unless -f $opt->{'manifest'};
  die(sprintf('Error: option "manifest" invalid. File "%s" not readable.', $opt->{'manifest'})) unless -r $opt->{'manifest'};

  my $match = $opt->{'match'} ||= qr/\.(?:pm|pl|cgi)\Z/;
  die(sprintf('Error: option "match" invalid. Value "%s" must be a regular expression (e.g., qr//).', $match)) unless ref($match) eq "Regexp";

  my $lines = $opt->{'lines'} ||= 500; #the identifier is susposed to be in the "header" comments
  $lines   += 0;
  die(sprintf('Error: option "lines" invalid. Value "%s" must be greater than zero.', $lines)) unless $lines > 0;

  my $diag = $opt->{'diag'} ||= 0; $diag+=0;
  my $Test = $opt->{'builder'} ||= Test::Builder->new;
  $Test->diag("Start") if $diag > 0;
  my @filenames = ();
  $Test->diag(sprintf("Opening manifest file: %s", $opt->{'manifest'})) if $diag > 0;
  #TODO: Use a package to read MANIFEST e.g. Module::Manifest
  { #gather files for test plan count
    my $fh;
    open($fh, '<', $opt->{'manifest'}) or die(sprintf('Error: option "manifest" invalid. File "%s" could not be opened.', $opt->{'manifest'}));
    $Test->diag(qq{Reading manifest file}) if $diag > 0;
    while (my $entry = <$fh>) {
      $entry =~ s/\A\s*//; #ltrim - is this valid?
      next if $entry =~ m/\A#/; #comments
      $entry =~ s/\s*\Z//; #rtrim - instead of chomp for cross platform file support
      $entry =~ s/\s.*\Z//; #strip comments - format is filename {whitespace} comment - #TODO: support quoted filenames with whitespace
      $Test->diag("Filename: $entry") if $diag > 0;
      if ($entry =~ $match) {
        $Test->diag("Filename: $entry, File matches regular expression.") if $diag > 0;
        push @filenames, $entry;
      } else {
        $Test->diag("Filename: $entry, File does not match regular expression. Skipping.") if $diag > 0;
      }
    }
    close($fh);
  }
  $Test->diag(sprintf("Files: %s", scalar(@filenames))) if $diag > 0;
  my $test_count = 2;
  $Test->plan(tests => $test_count * @filenames);
  my $license_spdx = License::SPDX->new;
  foreach my $filename (@filenames) {
    $Test->diag("Filename: $filename") if $diag > 0;
    my $found;
    { #scope for $fh
      my $fh;
      open($fh, '<', $filename) or die(sprintf('Error: File "%s" could not be opened for read', $filename));
      my $line_number  = 0;
      foreach my $line_text (<$fh>) {
        $line_number++;
        $line_text =~ s/[\n\r]+\Z//; #chompish
        if ($line_text =~ m/\A\s*#\s*SPDX-License-Identifier:\s*([a-zA-Z0-9 ()+.-]+)\s*\Z/) { #TODO: add c or xml capability i.e. //, /* */, <!-- -->
          my $license = $1;
          $found      = {filename=>$filename, line_number=>$line_number, line_text=> $line_text , license=> $license};
          $Test->diag(qq{Filename: $filename, Line Number: $line_number, Line Text: "$line_text", License: "$license"}) if $diag > 0;
        }
        last if $found;
        last if $line_number >= $lines;
      }
      close($fh);
    }
    if ($found) {
      $Test->ok(1, "SPDX-License-Identifier Found");
      my $license      = $found->{'license'};
      my $test_license = 0;
      if ($license_spdx->check_license($license)) {
        $test_license = 1;
      }
      $Test->diag("License: $license");
      $Test->ok($test_license, "License: $license, SPDX-License-Identifier license valid.");
    } else {
      $Test->ok(0, "SPDX-License-Identifier found.");
      $Test->ok(0, "SPDX-License-Identifier license valid.");
    }
  }
  $Test->diag("Finish") if $diag > 0;
}

=head1 SEE ALSO

L<License::SPDX>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Michael Davis

MIT

=cut
1;
