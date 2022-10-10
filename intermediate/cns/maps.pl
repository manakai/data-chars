use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

BEGIN {
  require (path (__FILE__)->parent->parent->parent->child ('intermediate/vgen/chars.pl')->stringify);
}

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/icns');

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
      my $plane = $1;
      my $c1 = sprintf ':cns%d-%d-%d',
          $plane, (hex $2) - 0x20, (hex $3) - 0x20;
      my $c2 = u_chr hex $4;
      if (is_private $c2) {
        my $c2_0 = $c2;
        $c2 = sprintf ':u-cns-%x', ord $c2;
        my $key = 'variants';
        if ($plane >= 3 or
            ($c1 =~ /^:cns1-/ and $c2 =~ /^:u-cns-f[^9][0-9a-f]{3}$/)) {
          $key = 'hans';
        }
        $Data->{$key}->{$c1}->{$c2}->{'cns:unicode'} = 1;
        $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      } else {
        my $key = 'variants';
        if (is_han $c2 > 0) {
          $key = 'hans';
        }
        $Data->{$key}->{$c1}->{$c2}->{'cns:unicode'} = 1;
      }
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
