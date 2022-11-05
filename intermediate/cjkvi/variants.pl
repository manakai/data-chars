use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/icjkvi');

my $Data = {};

sub wrap ($) {
  my $s = shift;
  $s = ':cjkvi:'.$s
      if $s =~ /\p{Ideographic_Description_Characters}|\[/;
  return $s;
} # wrap

sub bad ($) {
  my $s = shift;
  return 1 if $s eq "\x{FFFD}";
  return 1 if $s =~ /[\x{FF00}-\x{FF5F}]/;
  return 0;
} # bad

{
  my $path = $TempPath->child ('variants.txt');
  my $vtype = 'cjkvi:variants';
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    if (/^(\w)(\w)$/) {
      die unless is_han $1;
      die unless is_han $2;
      $Data->{hans}->{$1}->{$2}->{$vtype} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $TempPath->child ('repo', 'jp-old-style.txt');
  my $vtype = 'cjkvi:jp-old-style';
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^(\w+)\t(\w+)$/) {
      die unless is_han $1;
      die unless is_han $2;
      $Data->{hans}->{$1}->{$2}->{$vtype} = 1;
    } elsif (/^(\w+)\t(\w+)\t(\w+)$/) {
      die unless is_han $1;
      die unless is_han $2;
      die unless is_han $3;
      $Data->{hans}->{$1}->{$2}->{$vtype} = 1;
      $Data->{hans}->{$1}->{$3}->{"$vtype:compatibility"} = 1;
    } elsif (/^(\w+)\t\t\t# (\w+)$/) {
      die unless is_han $1;
      die unless is_han $2;
      $Data->{hans}->{$1}->{$2}->{"$vtype:comment"} = 1;
    } elsif (/^(\w+)\t(\w+)\t\t# \x{2605}$/) {
      die unless is_han $1;
      die unless is_han $2;
      $Data->{hans}->{$1}->{$2}->{$vtype} = 1;
    } elsif (/^(\w+)\t(\w+)\t\t# ([\w\p{Ideographic_Description_Characters}]+)$/) {
      die unless is_han $1;
      die unless is_han $2;
      $Data->{hans}->{$1}->{$2}->{$vtype} = 1;
      $Data->{hans}->{$1}->{wrap $3}->{"$vtype:comment"} = 1;
    } elsif (/^(\w+)\t\t\t# ([\x{2605}\x{2606}])$/) {
      $Data->{hans}->{$1}->{":cjkvi:$2$1"}->{$vtype} = 1;
    } elsif (/\S/) {
      warn join " ", map { sprintf "%04X", ord $_ } split //, $_;
      die "Bad line |$_|";
    }
  }
}

for (
  ['duplicate-chars.txt'],
  ['non-cjk.txt'],
  ['non-cognates.txt'],
  ['ucs-scs.txt'],
  ['jisx0212-variants.txt'],
  ['jisx0213-variants.txt'],
  ['x0212-x0213-variants.txt'],
  ['joyo-variants.txt'],
  ['jinmei-variants.txt'],
  ['hyogai-variants.txt'],
  ['jp-borrowed.txt'],
  ['dypytz-variants.txt'],
  ['hydzd-borrowed.txt'],
  ['hydzd-variants.txt'],
  ['koseki-variants.txt'],
  ['twedu-variants.txt'],
  ['sawndip-variants.txt'],
  ['numeric-variants.txt'],
  ['radical-variants.txt'],
  ['cjkvi-variants.txt'],
  ['cjkvi-simplified.txt'],
) {
  my ($fname) = @$_;
  my $path = $TempPath->child ('repo', $fname);
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^#/) {
      #
    } elsif (m{^([^,\s]+),([a-z0-9/-]+),([^,\s]+)\s*$}) {
      my $c1 = wrap $1;
      my $c2 = wrap $3;
      next if bad $c2;
      my $vtype = "cjkvi:$2";
      die unless is_han $c1;
      if (is_private $c2) {
        my $c2_1 = $c2;
        $c2 = sprintf ':cjkvi:u%x', ord $c2;
        $Data->{hans}->{$c1}->{$c2}->{$vtype} = 1;
        $Data->{hans}->{$c2_1}->{$c2}->{'manakai:private'} = 1;
      } elsif ($vtype =~ /non-cjk|non-cognate/ and is_kana $c2 > 0) {
        my $key = 'kanas';
        $Data->{$key}->{$c1}->{$c2}->{$vtype} = 1;
      } else {
        insert_rel $Data,
            $c1, $c2, $vtype,
            'auto';
      }
    } elsif (m{^([^,\s]+),(hydcd/borrowed),([^,\s]+),[0-9]+$}) {
      my $c1 = wrap $1;
      my $c2 = wrap $3;
      next if bad $c2;
      my $vtype = "cjkvi:$2";
      die unless is_han $c1;
      die unless is_han $c2;
      $Data->{hans}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (m{^([^,\s]+),([a-z0-9/]+),([^,\s]+)[, ]\[}) {
      my $c1 = wrap $1;
      my $c2 = wrap $3;
      next if bad $c2;
      my $vtype = "cjkvi:$2";
      die unless is_han $c1;
      die unless is_han $c2;
      $Data->{hans}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (m{^([^,\s]+),([a-z0-9/-]+),([^,\s]+),([^,\s]+|JIS X 0213:2004)\s*$}) {
      my $c1 = wrap $1;
      my $c2 = wrap $3;
      next if bad $c2;
      my $vtype = "cjkvi:$2:$4";
      $vtype =~ s/ /-/g;
      die unless is_han $c1;
      die unless is_han $c2;
      $Data->{hans}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (/^[a-z]/) {
      #
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $TempPath->child ('gb2ucs.txt');
  my $vtype = 'cjkvi:variants';
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    if (/^G([24K])-([0-9]{2})([0-9]{2})\s+(U\+[0-9A-Fa-f]+|[\p{Ideographic_Description_Characters}\p{CJK_Radicals_Supplement}\p{Private_Use}\w]+)(?:\s*#.+|)$/) {
      my $pp = $1;
      my $p = {
        2 => 2,
        4 => 4,
        K => 10 + ((ord 'K') - (ord 'A')),
      }->{$pp};
      my $c1 = sprintf ':gb%d-%d-%d', $p, $2, $3;
      my $c2;
      if ((substr $4, 0, 2) eq 'U+') {
        $c2 = chr hex substr $4, 2;
        die $c2 unless is_han $c2;
      } else {
        $c2 = wrap $4;
      }
      my $vtype = 'cjkvi:gb2ucs:'.$pp;
      $Data->{hans}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
