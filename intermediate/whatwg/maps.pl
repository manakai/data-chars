use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwh');
my $Data = {};

sub p2b ($) {
  my $p = shift;
  my $b1 = int ($p / 157) + 0x81;
  my $b2 = $p % 157;
  $b2 += 0x40;
  $b2 += 0x22 if $b2 >= 0x7F;
  return ($b1, $b2);
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

{
  my $path = $TempPath->child ('index-big5.txt');
  my $B5 = [];
  for (split /[\x0D\x0A]/, $path->slurp) {
    if (/^\s*([0-9]+)\s*0x([0-9A-F]+)/) {
      my $u = hex $2;
      my $p = $1;
      my ($b1, $b2) = p2b $p;
      push @$B5, [$b1, $b2, u_chr $u];
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
  push @$B5, [p2b (1133), "\x{00CA}\x{0304}"];
  push @$B5, [p2b (1135), "\x{00CA}\x{030C}"];
  push @$B5, [p2b (1164), "\x{00EA}\x{0304}"];
  push @$B5, [p2b (1166), "\x{00EA}\x{030C}"];

  for (@$B5) {
    my $b5 = $_->[0] * 0x100 + $_->[1];
    my $c1 = is_b5_variant $b5 ? sprintf ':b5-hkscs-%x', $b5,
                               : sprintf ':b5-%x', $b5;
    my $c1_0 = $c1;
    $c1_0 =~ s/^:b5-hkscs-/:b5-/g;
    my $c2 = $_->[2];
    my $key = get_vkey $c2;
    my $c2_0 = $c2;
    if (is_private $c2) {
      die;
      $c2 = sprintf ':u-hkscs-%x', ord $c2;
      $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    }
    my $rel_type = 'encoding:decode:big5';
    $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    unless ($c1 eq $c1_0) {
      $Data->{codes}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
    }

    if ($PUA->{$b5}) {
      my $c2_p0 = sprintf ':u-b5-%x', $PUA->{$b5};
      if ($c1 eq $c1_0) {
        $Data->{$key}->{$c1_0}->{$c2_p0}->{'manakai:same'} = 1;
      } else {
        my $c2_p = sprintf ':u-hkscs-%x', $PUA->{$b5};
        $Data->{$key}->{$c1}->{$c2_p}->{'manakai:same'} = 1;
        $Data->{$key}->{$c1_0}->{$c2_p0}->{'manakai:same'} = 1;
      }
      delete $PUA->{$b5};
    }
  }
}

for my $b5 (keys %$PUA) {
  my $c1 = sprintf ':b5-%x', $b5;
  my $c2 = sprintf ':u-b5-%x', $PUA->{$b5};
  my $key = 'variants';
  $Data->{$key}->{$c1}->{$c2}->{'manakai:same'} = 1;
}

print_rel_data $Data;

## License: Public Domain.
