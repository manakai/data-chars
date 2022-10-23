use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $Data = {};

my $IsHan = {};
## <https://wiki.suikawiki.org/n/ARIB%E5%A4%96%E5%AD%97>
{
  use utf8;
  $Data->{hans}->{":jis-arib-1-92-26"}->{"氏"}->{'arib:70%'} = 1;
  $Data->{hans}->{":jis-arib-1-92-27"}->{"副"}->{'arib:70%'} = 1;
  $Data->{hans}->{":jis-arib-1-92-28"}->{"元"}->{'arib:70%'} = 1;
  $Data->{hans}->{":jis-arib-1-92-29"}->{"故"}->{'arib:70%'} = 1;
  $Data->{hans}->{":jis-arib-1-92-30"}->{"前"}->{'arib:70%'} = 1;
  $Data->{hans}->{":jis-arib-1-92-31"}->{"新"}->{'arib:70%'} = 1;
  $IsHan->{$_} = 1 for qw(
    :jis-arib-1-92-26 :jis-arib-1-92-27 :jis-arib-1-92-28
    :jis-arib-1-92-29 :jis-arib-1-92-30 :jis-arib-1-92-31
    :jis-arib-1-92-7 :jis-arib-1-92-8 :jis-arib-1-92-9 :jis-arib-1-92-10
  );
  delete $Data->{hans}->{":jis1-47-52"}->{":u-arib-e7f4"};
  $Data->{hans}->{":jis1-47-52"}->{":u-aribold-e7f4"}->{"arib:ucs"} = 1;
  $Data->{hans}->{"\x{e7f4}"}->{":u-aribold-e7f4"}->{"manakai:private"} = 1;
}
{
  my $path = $ThisPath->child ('aribchars.txt');
  for (split /\n/, $path->slurp) {
    if (/^(\d+)-(\d+)-(\d+)\t([0-9A-F]+)$/) {
      my $c1 = $1 ? (sprintf ':jis%d-%d-%d', $1, $2, $3) :
                    (sprintf ':jis-arib-1-%d-%d', $2, $3);
      my $c1_0 = sprintf ':jis1-%d-%d', $2, $3;
      my $c2 = chr hex $4;
      my $key = 'variants';
      $key = 'hans' if is_han $c2 or $IsHan->{$1, $2, $3} or is_han $c1;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-arib-%x', ord $c2;
        $key = 'hans' if is_han $c2;
        $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
      if ($1 == 0) {
        $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      }
      $IsHan->{$1, $2, $3} = 1 if $key eq 'hans';
      $Data->{$key}->{$c1}->{$c2}->{'arib:ucs'} = 1;
    } elsif (/^(\d+)-(\d+)\t(->|)(\d+)-(\d+)-(\d+)$/) {
      my $c1 = sprintf ':jis-arib-1-%d-%d', $1, $2;
      my $c2 = $4 eq "0212" ? (sprintf ':jis2-%d-%d', $5, $6)
                          : (sprintf ':jis%d-%d-%d', $4, $5, $6);
      my $key = 'hans';
      my $rel_type = $4 eq "0212" ? 'arib:jisx0212'
                                : 'arib:jisx0213';
      $rel_type .= ':variant' if $3;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^(\d+)-(\d+)\t(->|)([0-9A-F]+) # (JIS X 0221|ISO\/IEC 10646)$/) {
      my $c1 = sprintf ':jis-arib-1-%d-%d', $1, $2;
      my $c2 = chr hex $4;
      my $key = 'hans';
      my $rel_type = $5 eq 'JIS X 0221' ? 'arib:jisx0221'
                                        : 'arib:isoiec10646';
      $rel_type .= ':variant' if $3;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^(\d+)-(\d+)\t([0-9A-F]+)\t=\t(\d+)-(\d+)\t([0-9A-F]+)$/) {
      my $c1 = sprintf ':jis-arib-1-%d-%d', $1, $2;
      my $c2 = sprintf ':jis-arib-1-%d-%d', $4, $5;
      my $c3 = chr hex $3;
      my $c4 = chr hex $6;
      $c3 = sprintf ':u-arib-%x', ord $c3 if is_private $c3;
      $c4 = sprintf ':u-arib-%x', ord $c4 if is_private $c4;
      my $key = ($1 < 90 or is_han $c4 or $IsHan->{$c4}) ? 'hans' : 'variants';
      $c2 =~ s/-arib-// if $4 < 60;
      $Data->{$key}->{$c1}->{$c2}->{'arib:duplicate'} = 1;
      $Data->{$key}->{$c3}->{$c4}->{'arib:duplicate'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path2 = $ThisPath->child ('aribothers.txt');
  my $file2 = $path2->openr;
  while (<$file2>) {
    if (/^0-(\d+)-(\d+)\t(.+)$/) {
      my $c1 = sprintf ':jis-arib-1-%d-%d', $1, $2;
      for (split / /, $3) {
        my $c2 = chr hex $_;
        my $key = 'variants';
        $key = 'hans' if $IsHan->{$c1};
        if (is_private $c2) {
          $Data->{$key}->{$c2}->{$c1}->{'manakai:private'} = 1;
        } else {
          $Data->{$key}->{$c1}->{$c2}->{'manakai:private'} = 1;
        }
      }
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  ## <https://wiki.suikawiki.org/n/hngl>
  my $path = $ThisPath->child ('hngl.txt');
  for (split /\n/, $path->slurp) {
    my @s = split /\s+/, $_;
    my $c1 = sprintf ':ak1-%d', shift @s;
    for (@s) {
      my $c2 = sprintf ':ak1-%d', $_;
      $Data->{variants}->{$c1}->{$c2}->{"opentype:hngl"} = 1;
    }
  }
}
{
  ## <https://wiki.suikawiki.org/n/Adobe-Korea1>
  my $path = $ThisPath->child ('ak1.txt');
  for (split /\n/, $path->slurp) {
    my @s = split /\s+/, $_;
    my $c1 = join '', map { sprintf ':ak1-%d', $_ } split /:/, shift @s;
    for (@s) {
      my $c2 = join '', map { sprintf ':ak1-%d', $_ } split /:/, $_;
      $Data->{variants}->{$c1}->{$c2}->{"manakai:related"} = 1;
    }
  }
}

## <https://wiki.suikawiki.org/n/Big5>
for (
  ['b5-map-2.txt', 'manakai:related', ':b5-hkscs-'],
  ['b5-map-3.txt', 'manakai:related', ':b5-uao-'],
  ['b5-map-4.txt', 'manakai:private', ':b5-uao-'],
  ['b5-map-5.txt', 'manakai:private', ':b5-'],
  ['b5-map-6.txt', 'manakai:private', ':b5-'],
  ['b5-map-7.txt', 'manakai:related', ':b5-'],
) {
  my $path = $ThisPath->child ($_->[0]);
  my $rel_type = $_->[1];
  my $prefix = $_->[2];
  my $file = $path->openr;
  while (<$file>) {
    if (/^([0-9A-F]+)\t([0-9A-F]+(?::[0-9A-F]+)*(?: [0-9A-F]+(?::[0-9A-F]+)*)*)$/) {
      my $c1 = sprintf '%s%x', $prefix, hex $1;
      for (split / /, $2) {
        my $c2 = join '', map { chr hex $_ } split /:/, $_;

        my $key = 'variants';
        if ($c2 =~ /^\p{Ideographic_Description_Characters}/) {
          $c2 = ":" . $c2;
          $key = 'hans';
        }
        $key = 'hans' if is_han $c2 > 0;
        $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
      }
    } elsif (/\S/) {
      die $_;
    }
  }
}

## <https://wiki.suikawiki.org/n/CCCII>
{
  my $path = $ThisPath->child ('ccciim.txt');
  for (split /\n/, $path->slurp) {
    if (/^([0-9]+)-([0-9]+)-([0-9]+)\t([0-9A-F]+(?: [0-9A-F]+)*)$/) {
      my $c1 = sprintf ':cccii%d-%d-%d', $1, $2, $3;
      $c1 = chr ($2 * 0x100 + $3) if $1 == 95;
      my $cs = $4;
      for (split / /, $cs) {
        my $c2 = chr hex $_;
        my $key = 'variants';
        $key = 'hans' if is_han $c2 > 0;
        die if is_private $c2;
        $Data->{$key}->{$c1}->{$c2}->{'manakai:related'} = 1;
      }
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $ThisPath->child ('ccciiv.txt');
  for (split /\n/, $path->slurp) {
    if (/^([0-9]+)-([0-9]+)-([0-9]+)\t([0-9]+)-([0-9]+)-([0-9]+)$/) {
      my $c1 = sprintf ':cccii%d-%d-%d', $1, $2, $3;
      $c1 = chr ($2 * 0x100 + $3) if $1 == 95;
      my $c2 = sprintf ':cccii%d-%d-%d', $4, $5, $6;
      $c2 = chr ($5 * 0x100 + $6) if $4 == 95;
      die if is_private $c1 or is_private $c2;
      my $key = 'hans';
      my $rel_type = 'manakai:related';
      if ($2 == $5 and $3 == $6 and (($1-$4) % 6) == 0) {
        $rel_type = 'cccii:layer';
      }
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

for my $c1 (keys %{$Data->{variants}}) {
  delete $Data->{variants}->{$c1}->{$c1};
  delete $Data->{variants}->{$c1} unless keys %{$Data->{variants}->{$c1}};
}
for my $c1 (keys %{$Data->{hans}}) {
  delete $Data->{hans}->{$c1}->{$c1};
  delete $Data->{hans}->{$c1} unless keys %{$Data->{hans}->{$c1}};
}

print_rel_data $Data;

## License: Public Domain.
