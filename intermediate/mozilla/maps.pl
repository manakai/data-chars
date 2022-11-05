use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/imz');
my $Data = {};

for (
  ['b5-1984.txt', 'moztw:Big5-1984'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $rel_type = $_->[1];
  for (split /[\x0D\x0A]/, $path->slurp) {
    if (/^0x([0-9A-F]+)\s+(?:0x|U\+)([0-9A-F]+)\s*(?:#|$)/) {
      my $c1 = sprintf ':b5-%x', hex $1;
      my $c2 = u_chr hex $2;
      if (is_private $c2) {
        die;
      }
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^0x([0-9A-F]+)\s+(?:0x|U\+)([0-9A-F]+)\s+(?:0x|U\+)([0-9A-F]+)\s*(?:#|$)/) {
      my $c1 = sprintf ':b5-%x', hex $1;
      my $c2 = u_chr hex $3;
      if (is_private $c2) {
        die;
      }
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die "$path: |$_|";
    }
  }
}

my $PUA = {};
{
  my $path = $ThisPath->parent->child ('misc/b5-map-1.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^([0-9A-F]+)\t([0-9A-F]+)$/) {
      $PUA->{hex $1} = hex $2;
    } elsif (/\S/) {
      die $_;
    }
  }
}

for (
  ['b5-uao250.txt', 'moztw:UAO 2.50'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $rel_type = $_->[1];
  for (split /[\x0D\x0A]/, $path->slurp) {
    if (/^0x([0-9A-F]+)\s+(?:0x|U\+)([0-9A-F]+)\s*(?:#|$)/) {
      my $b5 = hex $1;
      my $c1 = is_b5_variant $b5 ? sprintf ':b5-uao-%x', $b5,
                                 : sprintf ':b5-%x', $b5;
      my $c2 = u_chr hex $2;
      my $c1_0 = $c1;
      $c1_0 =~ s/^:b5-uao-/:b5-/g;
      my $key = get_vkey $c2;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-uao-%x', ord $c2;
        $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
      unless ($c1 eq $c1_0) {
        $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      }
      if ($PUA->{$b5}) {
        my $c2_p0 = sprintf ':u-bigfive-%x', $PUA->{$b5};
        unless ($c1 eq $c1_0) {
          my $c2_p = sprintf ':u-uao-%x', $PUA->{$b5};
          $Data->{$key}->{$c1}->{$c2_p}->{'manakai:same'} = 1;
        }
      }
    } elsif (/^0x([0-9A-F]+)\s+0x([0-9A-F]+)\+0x([0-9A-F]+)\s*#/) {
      my $b5 = hex $1;
      my $c1 = is_b5_variant $b5 ? sprintf ':b5-uao-%x', $b5,
                                 : sprintf ':b5-%x', $b5;
      my $c2 = u_chr hex $3;
      my $c1_0 = $c1;
      $c1_0 =~ s/^:b5-uao-/:b5-/g;
      my $key = get_vkey $c2;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-uao-%x', ord $c2;
        $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
      unless ($c1 eq $c1_0) {
        $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      }
      if ($PUA->{$b5}) {
        my $c2_p0 = sprintf ':u-bigfive-%x', $PUA->{$b5};
        unless ($c1 eq $c1_0) {
          my $c2_p = sprintf ':u-uao-%x', $PUA->{$b5};
          $Data->{$key}->{$c1}->{$c2_p}->{'manakai:same'} = 1;
        }
      }
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die "$path: |$_|";
    }
  }

}

print_rel_data $Data;

## License: Public Domain.
