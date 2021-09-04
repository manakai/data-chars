use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iuc');

my $Data = {};

my $path = $TempPath->child ('Unihan_Variants.txt');
for (split /\x0D?\x0A/, $path->slurp) {
  if (/^U\+([0-9A-F]+)\s+(\w+)\s+(.+)$/) {
    my $c1 = hex $1;
    my $type = 'unihan:' . $2;
    my $v = $3;
    for (split /\s+/, $v) {
      s/<.+//;
      if (/^U\+([0-9A-F]+)$/) {
        my $c2 = hex $1;
        $Data->{variants}->{chr $c1}->{chr $c2}->{$type} = 1;
      } else {
        die "Bad char |$_|";
      }
    }
  }
}

{
  my $path = $TempPath->child ('IVD_Sequences.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([0-9A-F]+) ([0-9A-F]+);/) {
      my $c1 = chr hex $1;
      my $c2 = chr hex $2;
      $Data->{variants}->{$c1.$c2}->{$c1}->{"ivd:base"} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $TempPath->child ('EquivalentUnifiedIdeograph.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([0-9A-F]+)\s*;\s*([0-9A-F]+)\s*#/) {
      my $c1 = chr hex $1;
      my $c2 = chr hex $2;
      $Data->{variants}->{$c1}->{$c2}->{"ucd:Equivalent_Unified_Ideograph"} = 1;
    } elsif (/^([0-9A-F]+)\.\.([0-9A-F]+)\s*;\s*([0-9A-F]+)\s*#/) {
      my $cc11 = hex $1;
      my $cc12 = hex $2;
      my $c2 = chr hex $3;
      for ($cc11..$cc12) {
        my $c1 = chr $_;
        $Data->{variants}->{$c1}->{$c2}->{"ucd:Equivalent_Unified_Ideograph"} = 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

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
        $Data->{variants}->{$c1}->{$c2}->{$vtype} = 1 unless $c1 eq $c2;
      }
    }
  }
}

for (
  ['unihan-krname.txt', 'krname', 'unihan:koreanname:variant'],
) {
  my ($fname, $key, $vtype) = @$_;
  my $path = $TempPath->child ($fname);
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\s+\S+\s+([0-9]+)(?::U\+([0-9A-F]+)|)/) {
      my $c = chr hex $1;
      my $value = $2;
      $Data->{sets}->{$key}->{$c} = 1;
      if (defined $3) {
        my $c2 = chr hex $3;
        $Data->{variants}->{$c}->{$c2}->{$vtype} = 1;
      }
    }
  }
}

{
  my $path = $RootPath->child ('local/unicode/latest/StandardizedVariants.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F]+) ([0-9A-F]+)\s*;\s*CJK COMPATIBILITY IDEOGRAPH-([0-9A-F]+);/) {
      my $c1 = (chr hex $1) . (chr hex $2);
      my $c2 = chr hex $3;
      $Data->{variants}->{$c2}->{$c1}->{'unicode:svs'} = 1;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
