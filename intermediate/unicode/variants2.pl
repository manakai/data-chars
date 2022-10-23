use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' }

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iuc');

my $IVDVersion = $ENV{IVD_VERSION} || die "No |IVD_VERSION|";

my $Data = {};

my $path = $TempPath->child ('Unihan_Variants.txt');
for (split /\x0D?\x0A/, $path->slurp) {
  if (/^U\+([0-9A-F]+)\s+(\w+)\s+(.+)$/) {
    my $c1 = chr hex $1;
    my $type = 'unihan:' . $2;
    my $v = $3;
    for (split /\s+/, $v) {
      s/<.+//;
      if (/^U\+([0-9A-F]+)$/) {
        my $c2 = chr hex $1;
        my $key = is_han $c1 > 0 ? 'hans' : 'variants';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      } else {
        die "Bad char |$_|";
      }
    }
  }
}

{
  my $path = $TempPath->child ($IVDVersion . '/IVD_Sequences.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([0-9A-F]+) ([0-9A-F]+);/) {
      my $c1 = chr hex $1;
      my $c2 = chr hex $2;
      my $key = is_han $c1 > 0 ? 'hans' : 'variants';
      $Data->{$key}->{$c1.$c2}->{$c1}->{"ivd:base"} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $TempPath->child ($IVDVersion . '/IVD_Stats.txt');
  my $in_scope = 0;
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^# Duplicate Sequence Identifiers: /) {
      $in_scope = 1;
    } elsif ($in_scope and /^# \S+ \([^:\s]+: <([0-9A-F]+),([0-9A-F]+)>, <([0-9A-F]+),([0-9A-F]+)>\)$/) {
      my $c1 = (chr hex $1) . (chr hex $2);
      my $c2 = (chr hex $3) . (chr hex $4);
      $Data->{hans}->{$c1}->{$c2}->{"ivd:duplicate"} = 1;
    } elsif ($in_scope and /^# Shared IVSes: /) {
      $in_scope = 0;
    #} elsif ($in_scope and /^#/) {
    #  warn "<$_>";
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
      $Data->{hans}->{$c1}->{$c2}->{"ucd:Equivalent_Unified_Ideograph"} = 1;
    } elsif (/^([0-9A-F]+)\.\.([0-9A-F]+)\s*;\s*([0-9A-F]+)\s*#/) {
      my $cc11 = hex $1;
      my $cc12 = hex $2;
      my $c2 = chr hex $3;
      for ($cc11..$cc12) {
        my $c1 = chr $_;
        $Data->{hans}->{$c1}->{$c2}->{"ucd:Equivalent_Unified_Ideograph"} = 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

for (
  ['unihan-k0.txt', 'unihan:kKSC0', ':ks0'],
  ['unihan-k1.txt', 'unihan:kKSC1', ':ks1'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $rel_type = $_->[1];
  my $prefix = $_->[2];
  my $dups = {};
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\s+\S+\s+([0-9]{2})([0-9]{2})/) {
      my $c1 = chr hex $1;
      my $ku = 0+$2;
      my $ten = 0+$3;
      my $c2 = sprintf '%s-%d-%d', $prefix, $ku, $ten;
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
    }
  }
}

{
  my $path = $RootPath->child ('local/unicode/latest/StandardizedVariants.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F]+) ([0-9A-F]+)\s*;\s*CJK COMPATIBILITY IDEOGRAPH-([0-9A-F]+);/) {
      my $c1 = (chr hex $1) . (chr hex $2);
      my $c2 = chr hex $3;
      $Data->{hans}->{$c2}->{$c1}->{'unicode:svs:cjk'} = 1;
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
