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
  return wrap_ids ($s, ':cjkvi:') // $s;
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
  my $path = $TempPath->child ('cjkvi-variants', 'jp-old-style.txt');
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
  my $path = $TempPath->child ('cjkvi-variants', $fname);
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^#/) {
      #
    } elsif (m{^([^,\s]+),([a-z0-9/-]+),([^,\s]+)\s*$}) {
      my $c1 = wrap $1;
      my $c2 = wrap $3;
      next if bad $c2;
      my $vtype = "cjkvi:$2";
      if (is_ids $c1) {
        my $c1_2 = ':' . $c1;
        $Data->{idses}->{$c1_2}->{$c1}->{'manakai:ids'} = 1;
        $c1 = $c1_2;
      }
      if (is_ids $c2) {
        my $c2_2 = ':' . $c2;
        $Data->{idses}->{$c2_2}->{$c2}->{'manakai:ids'} = 1;
        $c2 = $c2_2;
     }
      die "Bad input |$c1|" unless is_han $c1;
      if (is_private $c2) {
        my $c2_1 = $c2;
        $c2 = sprintf ':cjkvi:u%x', ord $c2;
        $Data->{hans}->{$c1}->{$c2}->{$vtype} = 1;
        $Data->{codes}->{$c2_1}->{$c2}->{'manakai:private'} = 1;
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
  my $path = $TempPath->child ('cjkvi-data/gb2ucs.txt');
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    if (/^G([24K])-([0-9]{2})([0-9]{2})\s+(U\+[0-9A-Fa-f]+|[\p{Ideographic_Description_Characters}\p{CJK_Radicals_Supplement}\p{Private_Use}\w]+)(?:\s*#\s*(.+)|)$/) {
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
      my $note = $5;
      my $vtype = 'cjkvi:gb2ucs:'.$pp;
      my $vsuffix = '';
      my $vkey = 'hans';
      if (is_ids $c2) {
        $vkey = 'idses';
        $vtype .= ':ids';
      }
      $Data->{$vkey}->{$c1}->{$c2}->{$vtype} = 1;

      if (defined $note and length $note) {
        use utf8;
        if ($note =~ /^\p{Ideographic_Description_Characters}[\p{Han}\p{Ideographic_Description_Characters}\x{E000}-\x{F7FF}]+$/) {
          my $c5 = (wrap_ids $note, ':cjkvi:') // die;
          $Data->{idses}->{$c1}->{$c5}->{$vtype.':#'} = 1;
        } elsif ($note =~ /^(?:(\p{Han})|整理表（(\p{Han})）)$/) {
          my $c5 = $1 // $2;
          $Data->{$vkey}->{$c1}->{$c5}->{$vtype.':#'} = 1;
        } elsif ($note =~ /^G([35])-([0-9]{2})([0-9]{2}) U\+([0-9A-F]+), cf\. G([24])-([0-9]{2})([0-9]{2})$/) {
          my $c5 = sprintf ':gb%d-%d-%d', $1-1, $2, $3;
          my $c6 = chr hex $4;
          my $c7 = sprintf ':gb%d-%d-%d', $5, $6, $7;
          $Data->{$vkey}->{$c1}->{$c5}->{$vtype.':#:' . $1} = 1;
          $Data->{$vkey}->{$c1}->{$c6}->{$vtype.':#'} = 1;
          $Data->{$vkey}->{$c1}->{$c7}->{$vtype.':#:' . $5} = 1;
        } elsif ($note =~ m{^(?:(\p{Han}) |)<G([135])-([0-9A-F]{2})([0-9A-F]{2})>(?:\t# <G1-[0-9]{4}>|)$}) {
          my $c5 = $1;
          my $c6 = sprintf ':gb%d-%d-%d', $2 == 1 ? 1 : $2-1, (hex $3)-0x20, (hex $4)-0x20;
          my $v2 = $2;
          $Data->{$vkey}->{$c1}->{$c5}->{$vtype.':#'} = 1 if defined $c5;
          $vtype =~ s/:ids$//;
          $Data->{$vkey}->{$c1}->{$c6}->{$vtype.':#:' . $v2} = 1;
          my $c6_2 = $c6;
          $c6_2 =~ s/^:gb1-/:gb0-/;
          $Data->{codes}->{$c6_2}->{$c6}->{'manakai:private'} = 1;
        } else {
          die $note;
        }
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $TempPath->child ('cjkvi-data/nom_qn.txt');
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    my $c3;
    {
      use utf8;
      if (s/\s*# (\p{Han})の異体字.+$//) {
        $c3 = $1;
      }
      s/\s*部首間違い\s*$//;
    }
    if (/^(\p{Ideographic_Description_Characters}[\p{Han}\p{Ideographic_Description_Characters}\x{E000}-\x{F7FF}\x{FF1F}]+|\p{Han}(?:,\p{Han})*|[\x{FF1F}\x{E000}-\x{F7FF}])\s+[^\t]+\s+# \[([^\[\]]+)\]\s*$/) {
      my $v1 = $1;
      my $v2 = $2;
      next if $v1 eq "\x{FF1F}" and not $v2 =~ /,/;
      for (split /,/, $v1) {
        my $c1 = (wrap_ids $_, ':cjkvi:') // die;
        for (split /,\s*/, $v2) {
          my $c2;
          my $rel_type1 = 'cjkvi:ids';
          my $rel_type2 = 'cjkvi:nom_qn:#';
          if (/^V04-([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/) {
            $c2 = sprintf ':v%d-%d-%d', 3, (hex $1) - 0x20, (hex $2) - 0x20;
            $rel_type1 .= ':V4';
            $rel_type2 .= ':V4';
          } elsif (/^V\+([0-9A-Fa-f]+)$/) {
            $c2 = sprintf ':u-nom-%x', hex $1;
            my $c2_0 = chr hex $1;
            $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
          } else {
            die $_;
          }
          if (is_ids $c1) {
            $Data->{idses}->{$c2}->{$c1}->{$rel_type1} = 1;
          } else {
            my $key = get_vkey $c1;
            $Data->{$key}->{$c1}->{$c2}->{$rel_type2} = 1;
          }
          $Data->{hans}->{$c1}->{$c3}->{'cjkvi:nom_qn:variant'} = 1 if defined $c3;
        }
      }
    } elsif (/^(\p{Han})\t[^\t]+\t# \[V\+([0-9A-F]+)\]\s+V\+\2\w\x{3001}(\p{Ideographic_Description_Characters}\p{Han}+)$/) {
      my $c1 = $1;
      my $c2 = sprintf ':u-nom-%x', hex $2;
      my $c2_0 = chr hex $2;
      my $c4 = (wrap_ids $3, ':cjkvi:') // die;
      $Data->{hans}->{$c1}->{$c2}->{'cjkvi:nom_qn:variant'} = 1;
      $Data->{idses}->{$c2}->{$c4}->{'cjkvi:ids'} = 1;
      $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    } elsif (/.#./) {
      die $_;
    }
  }
}

{
  my $path = $ThisPath->child ('variants-ids.list');
  write_rel_data {idses => delete $Data->{idses}} => $path;
}
write_rel_data_sets
    $Data => $ThisPath, 'variants',
    [
      qr/^:/,
      qr/^[\x{3000}-\x{5FFF}]/,
      qr/^[\x{6000}-\x{8000}]/,
      qr/^[\x{9000}-\x{21FFF}]/,
      qr/^[\x{22000}-\x{26FFF}]/,
    ];

## License: Public Domain.
