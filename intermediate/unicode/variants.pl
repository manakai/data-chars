use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' }

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iuc');

my $Data = {};

for (
  ['unihan-tghz2013.txt', 'cn', ''],
  ['unihan-hkg.txt', 'hk', 'unihan:hkglyph'],
  ['unihan-k0.txt', 'k0'],
  ['unihan-g1.txt', 'g1'],
) {
  my ($fname, $key, $vtype) = @$_;
  my $path = $TempPath->child ($fname);
  my $dups = {};
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\s+\S+\s+(\S+)/) {
      my $c = chr hex $1;
      my $value = $2;
      $Data->{sets}->{$key}->{$c} = 1;
      $dups->{$value}->{$c} = 1;
    }
  }
  for (sort { $a cmp $b } keys %$dups) {
    my @c = keys %{$dups->{$_}};
    next unless @c > 1;
    for my $c1 (@c) {
      for my $c2 (@c) {
        $Data->{hans}->{$c1}->{$c2}->{$vtype} = 1 unless $c1 eq $c2;
      }
    }
  }
}

for (
  ['unihan-krname.txt', 'krname', undef],
  ['unihan13-krname.txt', undef, 'unihan:koreanname:variant'],
) {
  my ($fname, $key, $vtype) = @$_;
  my $path = $TempPath->child ($fname);
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\s+\S+\s+([0-9]+)(?::U\+([0-9A-F]+)|)/) {
      my $c = chr hex $1;
      my $value = $2;
      $Data->{sets}->{$key}->{$c} = 1 if defined $key;
      if (defined $3 and defined $vtype) {
        my $c2 = chr hex $3;
        $Data->{hans}->{$c}->{$c2}->{$vtype} = 1;
      }
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
