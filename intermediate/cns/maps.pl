use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/icns');

sub u_chr ($) {
  if ($_[0] <= 0x1F or (0x7F <= $_[0] and $_[0] <= 0x9F)) {
    return sprintf ':u%x', $_[0];
  }
  my $c = chr $_[0];
  if ($c eq ":" or $c eq "." or
      $c =~ /\p{Non_Character_Code_Point}|\p{Surrogate}/) {
    return sprintf ':u%x', $_[0];
  } else {
    return $c;
  }
} # u_chr

my $Data = {};

for (
  ['cns-0.txt'],
  ['cns-2.txt'],
  ['cns-15.txt'],
) {
  my $name = $_->[0];
  my $path = $TempPath->child ($name);
  for (split /\x0A/, $path->slurp) {
    if (/^([0-9]+)-([0-9A-F]{2})([0-9A-F]{2})\s+([0-9A-F]+)$/) {
      my $c1 = sprintf ':cns%d-%d-%d',
          $1, (hex $2) - 0x20, (hex $3) - 0x20;
      my $c2 = u_chr hex $4;
      $Data->{variants}->{$c1}->{$c2}->{'cns:unicode'} = 1;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
