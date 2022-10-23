use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/icns');

my $Data1 = {};
my $Data2 = {};
my $IsHan = {};

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
      my $data = $plane >= 10 ? $Data2 : $Data1;
      if (is_private $c2) {
        my $c2_0 = $c2;
        $c2 = sprintf ':u-cns-%x', ord $c2;
        my $key = 'variants';
        if ($plane >= 3 or
            ($c1 =~ /^:cns1-/ and $c2 =~ /^:u-cns-f[^9][0-9a-f]{3}$/)) {
          $key = 'hans';
        }
        $data->{$key}->{$c1}->{$c2}->{'cns:unicode'} = 1;
        $data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      } else {
        my $key = 'variants';
        if (is_han $c2 > 0) {
          $key = 'hans';
          $IsHan->{$c1} = 1;
        }
        $data->{$key}->{$c1}->{$c2}->{'cns:unicode'} = 1;
      }
    }
  }
}

for (
  ['cnsb5-0.txt', ''],
  ['cnsb5-1.txt', ':符號'],
  ['cnsb5-2.txt', ':七個倚天外字'],
) {
  my $name = $_->[0];
  my $suffix = $_->[1];
  my $path = $TempPath->child ($name);
  for (split /\x0A/, $path->slurp) {
    if (/^([0-9]+)-([0-9A-F]{2})([0-9A-F]{2})\s+([0-9A-F]+)$/) {
      my $plane = $1;
      my $c1 = sprintf ':cns%d-%d-%d',
          $plane, (hex $2) - 0x20, (hex $3) - 0x20;
      my $c2 = sprintf ':b5-%x', hex $4;
      my $key = 'variants';
      if ($IsHan->{$c1}) {
        $key = 'hans';
      }
      my $data = $plane >= 10 ? $Data2 : $Data1;
      $data->{$key}->{$c1}->{$c2}->{'cns:big5'.$suffix} = 1;
    }
  }
}

write_rel_data $Data1 => $ThisPath->child ('maps.list');
write_rel_data $Data2 => $ThisPath->child ('maps2.list');

## License: Public Domain.
