use strict;
use warnings;
use utf8;
use Path::Tiny;
use Web::Encoding;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');

my $Data = {};

sub extract_source ($) {
  my $html = $_[0];
  $html =~ s{^.+<textarea[^<>]*>}{}s;
  $html =~ s{</textarea>.*$}{}s;
  $html =~ s/&lt;/</g;
  $html =~ s/&amp;/&/g;

  $html = decode_web_utf8 $html;
  $html =~ s/&#x([0-9a-f]+);/chr hex $1/ge;
  $html =~ s/&#([0-9]+);/chr $1/ge;
  return $html;
} # extract_source

for (
  ['nan-1.html', 'wikipedia:zh:臺閩字列表:異用字 / 俗字', undef],
  ['nan-2.html', 'wikipedia:zh:臺語本字列表:異用字 / 俗字', undef],
  ['nan-3.html', undef, 'wikipedia:zh:歌仔冊文字'],
) {
  my ($fname, $rel_type1, $rel_type2) = @$_;
  my $path = $TempPath->child ($fname);

  my $i = -"Inf";
  my $c1;
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (/^\|-/) {
      $i = 0;
      undef $c1;
    } elsif (/^\|/) {
      $i++;
      s{<ref[^<>]*>.*?</ref>}{}g;
      s{<ref[^<>]*/>}{}g;
      s{-\{(\w)\}-}{$1}g;
      if ($i == 1) {
        if (/^\|\s*(\p{sc=Han}+)\s*$/) {
          $c1 = $1;
        } else {
          undef $c1;
        }
      } elsif ($i == 2) {
        if (defined $c1 and /^\|\s*(\p{sc=Han}+(?:、\p{sc=Han}+)*)\s*$/) {
          my @c2 = split /、/, $1;
          if (1 == length $c1) {
            for my $c2 (@c2) {
              if (defined $rel_type1 and 1 == length $c2) {
                $Data->{hans}->{$c1}->{$c2}->{$rel_type1} = 1;
              }
              if (defined $rel_type2 and 1 == length $c2) {
                $Data->{hans}->{$c2}->{$c1}->{$rel_type2} = 1;
              }
            }
          } elsif (2 == length $c1) {
            my @c = grep { 2 == length $_ } ($c1, @c2);
            for my $c1 (@c) {
              for my $c2 (@c) {
                if (substr ($c1, 0, 1) eq substr ($c2, 0, 1)) {
                  $Data->{hans}->{substr $c1, 1, 1}->{substr $c2, 1, 1}->{'manakai:related'} = 1;
                } elsif (substr ($c1, 1, 1) eq substr ($c2, 1, 1)) {
                  $Data->{hans}->{substr $c1, 0, 1}->{substr $c2, 0, 1}->{'manakai:related'} = 1;
                }
              }
            }
          }
        } else {
          undef $c1;
        }
      }
    }
  }
}

for (
  ['gb12052.html', 0xA, ':gb20', 'csw:mapping:gb12052'],
  ['ksx1002.html', 0x2, ':ks1', 'csw:mapping:ksx1002'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $prefix = $_->[2];
  my $rel_type = $_->[3];
  my $delta = $_->[1];
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (s/^\|([2-7A-F][0-9A-F])([0-9A-F])\|\|//) {
      my $ku = (hex $1) - ($delta * 0x10);
      my $ten = ((hex $2) - $delta) * 0x10;
      my @v = split /\|\|/, $_;
      for my $s (@v) {
        my $x = $s =~ s{^([^|]*)\|\s*}{} ? $1 : '';
        if (length $s) {
          $s =~ s{<nowiki></nowiki>}{}g;
          unless (1 == length $s or 2 == length $s) {
            if ($s eq q{<sup>O</sup><small>U</small><sub>T</sub>}) {
              $s = ':csw:' . $s;
            } elsif ($s =~ m{^\{\{옛한글\|(\p{Hang}+)\}\}$}) {
              $s = $1;
            } else {
              die "($x) ($s) " . (length $s);
            }
          }
          #warn sprintf "%d-%d (%s)\n", $ku, $ten, $s;
          my $c1 = sprintf '%s-%d-%d', $prefix, $ku, $ten;
          my $c2 = $s;

          my $key = get_vkey $c2;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
        }
        $ten++;
      }
    }
  }
  
  ## :gb20-71-41 - :gb20-71-64 "Hunminjeongeum Haerye style" variant
  my @x = qw(
    71-41 314F
    71-42 3151
    71-43 3153
    71-44 3155
    71-45 3157
    71-46 315B
    71-47 315C
    71-48 3160
    71-49 3150
    71-50 3152
    71-51 3154
    71-52 3156
    71-53 315A
    71-54 3189
    71-55 315F
    71-56 318C
    71-57 3158
    71-58 3187
    71-59 115F:118F
    71-60 318A
    71-61 3159
    71-62 115F:11A7
    71-63 315E
    71-64 318B
  );
  while (@x) {
    my $c1 = ':gb20-' . shift @x;
    my $c2 = join '', map { chr hex $_ } split /:/, shift @x;
    my $rel_type = q{kchar:Hunminjeongeum Haerye style};
    $Data->{kchars}->{$c1}->{$c2}->{$rel_type} = 1;
  }
}

for (
  ['hanyang.html', ':u-hanyang'],
  ['jeju.html', ':u-jeju'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $prefix = $_->[1];
  my $file = $path->openr;
  while (<$file>) {
    if (/^\|U\+([0-9A-F]+)\|\|[^|]+\|\|&lt;([^>]+)>/) {
      my $c1 = chr hex $1;
      my $c1_0 = $c1;
      $c1 = sprintf '%s-%x', $prefix, ord $c1;
      my $c2 = join '', map {
        s/^U\+//;
        chr hex $_;
      } split /\s*,\s*/, $2;
      my $key = 'kchars';
      my $rel_type = 'wikt:mapping';
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
      $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
    }
  }
}

{
  my $path = $ThisPath->child ('doukun.txt');
  my $text = decode_web_utf8 $path->slurp;
  $text =~ s{^#.*}{}gm;
  for (split /\x0A/, $text) {
    if (/^\s*#/) {
      #
    } elsif (/^(\p{sc=Hiragana}+)：(.+)$/) {
      my $s = $2;
      $s =~ s/（[^（）]+）//g;
      my @s;
      for (split /[・；、]/, $s) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
      for my $c1 (@s) {
        for my $c2 (@s) {
          next if $c1 eq $c2;
          $Data->{hans}->{$c1}->{$c2}->{'wikipedia:ja:同訓異字'} = 1;
        }
      }
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $ThisPath->child ('gbk.txt');
  my $text = decode_web_utf8 $path->slurp;
  $text =~ s{^#.*}{}gm;
  for (split /\x0A/, $text) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s.*U\+([0-9A-F]+)\s.*$/) {
      my $c1 = chr hex $1;
      my $c2 = chr hex $2;
      my $c1_0 = $c1;
      $c1 = sprintf ':u-gb-%x', ord $c1;
      my $key = 'variants';
      $key = 'hans' if hex $1 >= 0xE800;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:same'} = 1;
      $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  for my $c1 (keys %{$Data->{hans}}) {
    for my $c2 (keys %{$Data->{hans}->{$c1}}) {
      delete $Data->{hans}->{$c1}->{$c2} if $c1 eq $c2;
    }
    delete $Data->{hans}->{$c1} unless keys %{$Data->{hans}->{$c1}};
  }
}

{
  my $path = $TempPath->child ('0201-1.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^0x([0-9A-F]{2})\tU\+([0-9A-F]+)\s*#/) {
      my $c1 = sprintf ':jisx0201-%x', hex $1;
      my $c2 = chr hex $2;
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:related'} = 1;
    } elsif (/^#0x([0-9A-F]{2})\tU\+([0-9A-F]+)\s*<-\s*#/) {
      my $c1 = sprintf ':jisx0201-%x', hex $1;
      my $c2 = chr hex $2;
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:related'} = 1;
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('0201-2.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^0x([0-9A-F]{2})\tU\+([0-9A-F]+)\s*#/) {
      my $i1 = hex $1;
      my $c1 = sprintf ':jisx0201-%x', 0x80 + $i1;
      my $c2 = chr hex $2;
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:related'} = 1;

      my $c3 = sprintf ':jisx0201-ocrk-%x', 0x80 + $i1;
      $Data->{$key}->{$c1}->{$c3}->{'manakai:ocr'} = 1;

      unless ({
        0x21, 1, 0x24, 1, 0x25, 1, 0x27, 1, 0x28, 1, 0x29, 1,
        0x2A, 1, 0x2B, 1, 0x2C, 1, 0x2D, 1, 0x2E, 1, 0x2F, 1,
      }->{$i1}) {
        my $c4 = sprintf ':jisx0201-ocrhk-%x', 0x80 + $i1;
        $Data->{$key}->{$c1}->{$c4}->{'manakai:ocr'} = 1;
      }
    } elsif (/^0x[0-9A-F]+\s*#/) {
      #
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
  {
    my $c1 = sprintf ':jisx0201-ocrk-%x', 0x80 + 0x21;
    my $c2 = ":u2e";
    my $key = get_vkey $c2;
    $Data->{$key}->{$c1}->{$c2}->{'manakai:related'} = 1;
  }
  {
    my $c1 = sprintf ':jisx0201-ocrk-%x', 0x80 + 0x24;
    my $c2 = ",";
    my $key = get_vkey $c2;
    $Data->{$key}->{$c1}->{$c2}->{'manakai:related'} = 1;
  }
}
{
  my $path = $TempPath->child ('0201-2-hw.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^0x([0-9A-F]{2})\tU\+([0-9A-F]+)\s*#/) {
      my $c1 = sprintf ':jisx0201-%x', 0x80 + hex $1;
      my $c2 = chr hex $2;
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{'jis:halfwidth'} = 1;
    } elsif (/^0x[0-9A-F]+\s*#/) {
      #
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('0212.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^(#?)0x([2][0-9A-F])([0-9A-F]{2})\tU\+([0-9A-F]+)\s*#/) {
      my $c1 = sprintf ':jis%d-%d-%d', 2, (hex $2) - 0x20, (hex $3) - 0x20;
      my $c2 = chr hex $4;
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:related'} = 1;
    } elsif (/^(#?)0x([3-7][0-9A-F])([0-9A-F]{2})\tU\+([0-9A-F]+)\s*#/) {
      #
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('0208.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^()0x([2][0-9A-F])([0-9A-F]{2})\tU\+([0-9A-F]+)\s*#/) {
      my $c1 = sprintf ':jis%d-%d-%d', 1, (hex $2) - 0x20, (hex $3) - 0x20;
      my $c2 = chr hex $4;
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:related'} = 1;
    } elsif (/^(#?)0x([3-7][0-9A-F])([0-9A-F]{2})\tU\+([0-9A-F]+)\s*#/) {
      #
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('0213.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^(#|)0x([2][0-9A-D])([0-9A-F]{2})\tU\+([0-9A-F]+)\s*#/) {
      my $c1 = sprintf ':jis%d-%d-%d', 1, (hex $2) - 0x20, (hex $3) - 0x20;
      my $c2 = chr hex $4;
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:related'} = 1;
    } elsif (/^(#)0x([2][0-9A-D])([0-9A-F]{2})\tU\+([0-9A-F]+)\+([0-9A-F]+)\s*#/) {
      my $c1 = sprintf ':jis%d-%d-%d', 1, (hex $2) - 0x20, (hex $3) - 0x20;
      my $c2 = (chr hex $4) . (chr hex $5);
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:related'} = 1;
    } elsif (/^(#?)0x([3-7][0-9A-F]|2[EF])([0-9A-F]{2})\tU\+([0-9A-F]+)\s*#/) {
      #
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('gw-tron.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*(\S+)\s*\|\s*\S+\s*\|\s*99:0:0:0:0:200:200:([^:]+)\s*$/) {
      my $n1 = $1;
      my $n2 = $2;
      if ($n1 =~ /^tron-([0-9]{2})-([0-9a-f]{2})([0-9a-f]{2})$/) {
        my $tp = 0+$1;
        my $tc1 = hex $2;
        my $tc2 = hex $3;
        next unless $tp == 9;

        my $c1 = sprintf ':tron%d-%02x%02x', $tp, $tc1, $tc2;
        my $c2;
        if ($n2 =~ m{^juki-([0-9a-f]+)$}) {
          $c2 = sprintf ':u-juki-%x', hex $1;
        } elsif ($n2 =~ m{^jmj-([0-9]+)$}) {
          $c2 = sprintf ':MJ%06d', $1;
        } elsif ($n2 =~ m{^koseki-([0-9]+)$}) {
          $c2 = sprintf ':koseki%06d', $1;
        } elsif ($n2 =~ m{^aj1-([0-9]+)$}) {
          $c2 = sprintf ':aj%d', $1;
        } elsif ($n2 =~ m{^dkw-([0-9]+)$}) {
          die;
        } elsif ($n2 =~ m{^gt-([0-9]+)$}) {
          die;
        } elsif ($n2 =~ m{^u([0-9a-f]+)-u([0-9a-f]+)$}) {
          $c2 = (chr hex $1) . (chr hex $2);
        } elsif ($n2 =~ m{^u([0-9a-f]+)-u([0-9a-f]+)-u([0-9a-f]+)$}) {
          die;
        } elsif ($n2 =~ m{^u([0-9a-f]+)$}) {
          $c2 = chr hex $1;
        } elsif ($n2 =~ m{^u([0-9a-f]+)-([gjk]|jv|var-[0-9]+|itaiji-[0-9]+)$}) {
          die;
        } else {
          die $n2;
        }

        my $key = get_vkey $c1;
        $Data->{$key}->{$c1}->{$c2}->{'glyphwiki:alias'} = 1;
      } elsif ($n2 =~ m{^tron-([0-9]{2})-([0-9a-f]{2})([0-9a-f]{2})$}) {
        my $tp = 0+$1;
        my $tc1 = hex $2;
        my $tc2 = hex $3;
        next unless $tp == 9;

        my $c1 = sprintf ':tron%d-%02x%02x', $tp, $tc1, $tc2;
        my $c2;
        if ($n1 =~ m{^juki-([0-9a-f]+)$}) {
          $c2 = sprintf ':u-juki-%x', hex $1;
        } elsif ($n1 =~ m{^koseki-([0-9]+)$}) {
          $c2 = sprintf ':koseki%06d', $1;
        } else {
          die $n1;
        }

        my $key = get_vkey $c1;
        $Data->{$key}->{$c2}->{$c1}->{'glyphwiki:alias'} = 1;
      } else {
        die "|$n1| |$n2|";
      }
    }
  }
}

{
  my $path = $TempPath->child ('gw-kana.txt');
  my $prefix = $_->[2];
  my $rel_type = $_->[3];
  my $delta = $_->[1];
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (/^,[0-9]+,/) {
      my @v = split /\s*,\s*/, $_;
      my $c_ninjal;
      if ($v[2] =~ m{^\[\[ninjal-([0-9]+)\]\]$}) {
        $c_ninjal = sprintf ':ninjal%s', $1;
      }
      my $c_mj;
      if ($v[3] =~ m{^\[\[jmj-([0-9]+)\]\]$}) {
        $c_mj = sprintf ':MJ%s', $1;
      }
      my $c_koseki;
      if ($v[4] =~ m{^\[\[koseki-([0-9]+)\]\]$}) {
        $c_koseki = sprintf ':koseki%s', $1;
      }
      my $c_juki;
      if ($v[5] =~ m{^\[\[juki-([0-9a-f]+)\]\]$}) {
        $c_juki = sprintf ':u-juki-%x', hex $1;
      }
      my $c_tron;
      if ($v[6] =~ m{^\[\[tron-09-([0-9a-f]+)\]\]$}) {
        $c_tron = sprintf ':tron9-%x', hex $1;
      }
      #my $c1 = $c_ninjal || $c_mj || die "$v[1] <$_>";
      my $c_kana;
      if ($v[7] =~ m{^(\w)$}) {
        $c_kana = $1;
      }
      my $c_jibo;
      if ($v[8] =~ m{^(\w)$}) {
        $c_jibo = $1;
      }
      use utf8;
      my $type_kana = 'glyphwiki:音価';
      my $type_jibo = 'glyphwiki:字母';
      if (defined $c_ninjal) {
        $Data->{kanas}->{$c_ninjal}->{$c_kana}->{$type_kana} = 1;
        $Data->{kanas}->{$c_ninjal}->{$c_jibo}->{$type_jibo} = 1;
      }
      if (defined $c_mj) {
        $Data->{kanas}->{$c_mj}->{$c_kana}->{$type_kana} = 1;
        $Data->{kanas}->{$c_mj}->{$c_jibo}->{$type_jibo} = 1;
      }
      if (defined $c_ninjal and defined $c_mj) {
        $Data->{kanas}->{$c_mj}->{$c_ninjal}->{'glyphwiki:ninjal'} = 1;
      }
      if (defined $c_mj and defined $c_juki) {
        $Data->{kanas}->{$c_mj}->{$c_juki}->{'glyphwiki:juki'} = 1;
      }
      if (defined $c_tron and defined $c_juki) {
        $Data->{kanas}->{$c_tron}->{$c_juki}->{'glyphwiki:juki'} = 1;
      }
      if (defined $c_koseki and defined $c_juki) {
        $Data->{kanas}->{$c_koseki}->{$c_juki}->{'glyphwiki:juki'} = 1;
      }
      if (defined $c_ninjal and not defined $c_mj and
          (defined $c_koseki or defined $c_juki or defined $c_tron)) {
        die;
      }
      if (defined $c_juki and $c_juki =~ /^:u-juki-([0-9a-f]+)$/) {
        my $cu = chr hex $1;
        $Data->{kanas}->{$cu}->{$c_juki}->{'manakai:private'} = 1;
      }
    }
  }
}

{
  use utf8;
  ## <https://ja.wikipedia.org/wiki/%E5%90%88%E7%95%A5%E4%BB%AE%E5%90%8D>
  for (
    ['Hiragana kashiko.svg', '𛀚しこ', 'かしこ', '合字'],
    ['Ligature hiragana koto.gif', 'こと', 'こと', '合字'],
    ['Hiragana sama 2.svg', 'さ𛃅', 'さま', '合字'],
    ['Hiragana mairasesoro 1.svg', 'まいらせ候', 'まいらせさうらふ', '合字'],
    ['Hiragana mairasesoro 2.svg', 'まいらせ候', 'まいらせさうらふ', '合字'],
    ['ゟ', 'より', 'より', '合字'],

    ['𬼂', '也', 'なり', '草体'],

    ['Katakana-toiu.svg', 'ト云', 'トイフ', '合字'],
    ['Katakana toki 1.svg', 'トキ', 'トキ', '合字'],
    ['Katakana-tote.svg', 'トテ', 'トテ', '合字'],
    ['𪜈', 'トモ', 'トモ', '合字'],
    ['𪜈゙', 'ドモ', 'ドモ', '合字'],
    ['Katakana-yori.svg', 'ヨリ', 'ヨリ', '合字'],

    ['Katakana ifu.svg', '云', 'イフ', '草体'],
    ['ヿ', '事', 'コト', '略体'],
    ['𬼀', '為', 'シテ', '略体'],
    ['Katakana toki 2.svg', '時', 'トキ', '略体'],
    ['𬻿', '也', 'ナリ', '草体'],
  ) {
    my $c1 = $_->[0] =~ /\./ ? ':wmc:' . $_->[0] : $_->[0];
    my $c2 = $_->[1];
    my $c3 = $_->[2];
    my $ref_type2 = 'wikipedia:ja:合略仮名:' . $_->[3];
    my $ref_type3 = 'wikipedia:ja:合略仮名:読み';
    $Data->{kanas}->{$c2}->{$c1}->{$ref_type2} = 1;
    $Data->{kanas}->{$c1}->{$c3}->{$ref_type3} = 1;
  }
  ## <https://ja.wikipedia.org/wiki/%E7%89%87%E4%BB%AE%E5%90%8D#%E7%95%B0%E4%BD%93%E5%AD%97>
  for (
    ['ホ', '甲', '甫', '転化か'],
    ['ホ', '[口/丨]', '保', '省字'],
    ['ワ', '禾', '和', '省字'],
    ['タ', '太', undef, undef],
    ['ツ', '⿶儿丨', undef, undef],
    ['ネ', 'It-子.png', undef, undef],
    ['ネ', '[ネ-丶]', undef, undef],
    ['ム', 'レ', '武', '省字'],
    ['ヰ', 'It-井.png', undef, undef],
    ['ノ', '𠄎', '乃', '省字'],
    ['マ', '丆', '万󠄂', '省字'],
    ['サ', '七', '㔫', '省字'],
    ['ミ', '尸', '民', '省字'],
    ['ス', '爪', '爲', '省字'],
    ['ス', '寸', undef, undef],
    ['ン', '𠃋', undef, undef],
  ) {
    my $c1 = $_->[1] =~ /\./ ? ':wmc:' . $_->[1] : $_->[1] =~ /\[|⿶/ ? ':wm:' . $_->[1] : $_->[1];
    my $c2 = $_->[2];
    my $c3 = $_->[0];
    my $ref_type3 = 'wikipedia:ja:片仮名:片仮名';
    $Data->{kanas}->{$c1}->{$c3}->{$ref_type3} = 1;
    if (defined $c2) {
      my $ref_type2 = 'wikipedia:ja:片仮名:' . $_->[3];
      $Data->{kanas}->{$c2}->{$c1}->{$ref_type2} = 1;
    }
  }
}

## <https://wiki.suikawiki.org/n/%E4%B8%87%E8%91%89%E4%BB%AE%E5%90%8D>
{
  my $path = $ThisPath->child ('manyou.txt');
  for (split /\n/, decode_web_utf8 $path->slurp) {
    my @v = split /\s+/, $_;
    my $c1 = shift @v;
    for my $c2 (@v) {
      $Data->{kanas}->{$c1}->{$c2}->{'kana:manyou'} = 1;
    }
    if ($c1 =~ /^:(.)/) {
      $Data->{kanas}->{$1}->{$c1}->{'manakai:unified'} = 1;
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
