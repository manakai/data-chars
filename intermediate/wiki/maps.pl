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
my $TempUCPath = $RootPath->child ('local/iuc');

my $Data = {};
my $GWRels = {};

sub extract_source ($) {
  my $html = $_[0];
  $html =~ s{^.+<textarea[^<>]*>}{}s;
  $html =~ s{</textarea>.*$}{}s;
  $html =~ s/&lt;/</g;
  $html =~ s/&amp;/&/g;

  $html = decode_web_utf8 $html;
  $html =~ s/&#x([0-9a-f]+);/chr hex $1/ge;
  $html =~ s/&#([0-9]+);/chr $1/ge;
  $html =~ s/&amp;/&/g;
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
  my $path = $TempPath->child ('jaconvert.html');
  my $section;
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (/^\*\s*(\p{Han}+)g?\s*\x{2192}\s*(\p{Han})\s*/) {
      my $c2 = $2;
      my @c1 = split //, $1;
      for my $c1 (@c1) {
        next if $c1 eq $c2;
        $Data->{hans}->{$c1}->{$c2}->{'wikisource:ja:新旧字体変換用辞書:' . $section} = 1;
      }
    } elsif (/^\*\s*&#x([0-9A-Fa-f]+);g?\s*\x{2192}\s*(\p{Han})\s*/) {
      my $c2 = $2;
      my @c1 = (chr hex $1);
      for my $c1 (@c1) {
        next if $c1 eq $c2;
        $Data->{hans}->{$c1}->{$c2}->{'wikisource:ja:新旧字体変換用辞書:' . $section} = 1;
      }
    } elsif (/^===\s*(\S.+\S)\s*===$/) {
      $section = $1;
    } elsif (/^\*/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('dict.ts');
  my $text = $path->slurp_utf8;
  while ($text =~ /src\s*:\s*'([^']+)'\s*,\s*dst\s*:\s*'([^']+)'/g) {
    my $c1 = $1;
    my $c2 = $2;
    $Data->{hans}->{$c1}->{$c2}->{'geolonia:oldnew'} = 1;
  }
}

{
  my $path = $TempPath->child ('ja_zh_cn.rb');
  my $text = $path->slurp_utf8;
  for (split /\x0A/, $text) {
    if (m{^\s*'(\w+)'\s*=>\s*'(\w+)',\s*$}) {
      my $c1 = $1;
      my $c2 = $2;
      $Data->{hans}->{$c1}->{$c2}->{'KanjiChineseConverter:JaZhCn'} = 1;
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
  my $path = $TempPath->child ('gw-immi-1.txt');
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (/^\[\[u([0-9a-f]+) juki-([0-9a-f]+)\]\]$/) {
      my $code1 = hex $1;
      my $code2 = hex $2;
      my $c1 = chr $code1;
      if (0xE000 <= $code1 and $code1 <= 0xF7FF) {
        $c1 = sprintf ':u-immi-%x', $code1;
        my $cu = chr $code1;
        $Data->{hans}->{$cu}->{$c1}->{'manakai:private'} = 1;
      } elsif ($code1 == 0xF9A1 or $code1 == 0xF96F) {
        #
      } elsif (0xF800 <= $code1 and $code1 <= 0xFFFF) {
        die $1;
      } else {
        #
      }
      my $c2 = chr $code2;
      if (0xA000 <= $code2 and $code2 <= 0xF7FF) {
        $c2 = sprintf ':u-juki-%x', $code2;
        my $cu = chr $code2;
        $Data->{hans}->{$cu}->{$c2}->{'manakai:private'} = 1;
      } elsif (0xF800 <= $code2 and $code2 <= 0xFFFF) {
        die $2;
      } else {
        #
      }
      if ($c1 eq $c2) {
        #
      } else {
        use utf8;
        $Data->{hans}->{$c1}->{$c2}->{'glyphwiki:平成23年12月26日法務省告示第582号別表第一'} = 1
      }
    } elsif (/^\[\[u([0-9a-f]+) koseki-([0-9]+)\]\]$/) {
      my $code1 = hex $1;
      my $c2 = sprintf ':koseki%s', $2;
      my $c1 = chr $code1;
      if (0xA000 <= $code1 and $code1 <= 0xF7FF) {
        $c1 = sprintf ':u-immi-%x', $code1;
        my $cu = chr $code1;
        $Data->{hans}->{$cu}->{$c1}->{'manakai:private'} = 1;
      } elsif ($code1 == 0xF9A1 or $code1 == 0xF96F) {
        #
      } elsif (0xF800 <= $code1 and $code1 <= 0xFFFF) {
        die $1;
      } else {
        #
      }
      use utf8;
      $Data->{hans}->{$c1}->{$c2}->{'glyphwiki:平成23年12月26日法務省告示第582号別表第一'} = 1
    }
  }
}
{
  ## <https://glyphwiki.org/wiki/GlyphWiki-talk:%e7%95%b0%e4%bd%93%e5%ad%97>
  use utf8;
  my $path = $TempPath->child ('gw-immi-pua.txt');
  my $current;
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (/^-\[\[u([0-9a-f]+)\]\]\[\[u([0-9a-f]+)\]\],入管正字$/) {
      my $c1 = chr hex $1;
      my $c2 = chr hex $2;
      my $rel_type = 'glyphwiki:異体字:入管正字:外字';
      if (defined $current and $current eq $c2) {
        $rel_type .= ':第2順位';
      } else {
        $rel_type .= ':第1順位';
      }
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
      $current = $c1;
    } elsif (/^-\[\[irg2017-([0-9]+)\]\]\[\[u([0-9a-f]+)\]\],入管正字$/) {
      my $c1 = sprintf ':irg2017-%d', $1;
      my $c2 = chr hex $2;
      my $rel_type = 'glyphwiki:異体字:入管正字:外字';
      if (defined $current and $current eq $c2) {
        $rel_type .= ':第2順位';
      } else {
        $rel_type .= ':第1順位';
      }
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
      $current = $c1;
    } elsif (/^--\[\[nyukan-([0-9a-f]+)\]\]$/) {
      my $code1 = hex $1;
      my $c1 = sprintf ':u-immi-%x', $code1;
      my $c2 = $current // die "No current ($_)";
      my $rel_type = 'glyphwiki:異体字:入管正字:外字';
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;

      my $cu1 = chr $code1;
      $Data->{hans}->{$cu1}->{$c1}->{'manakai:private'} = 1;
      
      undef $current;
    } elsif (/^--\[\[nyukan-([0-9a-f]+)\]\]\[\[nyukan-([0-9a-f]+)\]\]$/) {
      my $code1 = hex $1;
      my $code3 = hex $2;
      my $c1 = sprintf ':u-immi-%x', $code1;
      my $c3 = sprintf ':u-immi-%x', $code3;
      my $c2 = $current // die "No current ($_)";
      my $rel_type = 'glyphwiki:異体字:入管正字:外字';
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
      $Data->{hans}->{$c3}->{$c2}->{$rel_type} = 1;

      my $cu1 = chr $code1;
      $Data->{hans}->{$cu1}->{$c1}->{'manakai:private'} = 1;
      my $cu3 = chr $code3;
      $Data->{hans}->{$cu3}->{$c3}->{'manakai:private'} = 1;
      
      undef $current;
    } elsif (/^--現在無効/) {
      #
    } elsif (/^-/) {
      die $_;
    }
  }
}

for my $path (($TempPath->children (qr/^gw-relcp-[0-9]+\.txt$/))) {
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (/^-((?:\[\[u[0-9a-f]+\]\])+),([^,]+)$/) {
      my $v = $1;
      my $rel_type = 'glyphwiki:' . $2;
      {
        use utf8;
        $rel_type =~ s/繁簡関係\(二簡字、\w\w\)$/繁簡関係(二簡字)/;
      }
      $rel_type =~ s/\s+$//;
      $v =~ s/^\[\[u//;
      $v =~ s/\]\]$//;
      my @v = map { u_chr hex $_ } split /\]\]\[\[u/, $v;
      my $c1 = shift @v;
      my $key = get_vkey $c1;
      while (@v) {
        my $c2 = shift @v;
        $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
        $GWRels->{$rel_type}++;
        $c1 = $c2;
      }
    }
  }
}

{
  my $ToVKey = {};
  use utf8;
  my $path = $TempPath->child ('gw-cdp-unicode.txt');
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (/^,\[\[u([0-9a-f]+) cdp-([0-9a-f]+)\]\],\[\[u([0-9a-f]+)(-(?:[0-9]+-|)var-[0-9]+|-g[0-9]*|-[0-9]+|)\]\]$/) {
      my $c1 = sprintf ':u-cdp-%x', hex $1;
      my $c1_0 = u_chr hex $1;
      my $c2 = sprintf ':b5-cdp-%x', hex $2;
      my $c2_0 = sprintf ':b5-%x', hex $2;
      my $c3 = u_chr hex $3;
      my $rel_type = 'glyphwiki:UCSで符号化されたCDP外字';
      my $key = get_vkey $c3;
      $ToVKey->{$c1} = $key;
      my $c4 = $c3;
      $c3 = sprintf ':gw-u%s%s', $3, $4 if defined $4;
      $Data->{$key}->{$c1}->{$c3}->{$rel_type} = 1;
      $Data->{$key}->{$c2}->{$c3}->{$rel_type} = 1;
      $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:same'} = 1;
      if (not $c3 eq $c4) {
        #
      }
    } elsif (/^,\[\[u([0-9a-f]+) cdp-([0-9a-f]+)\]\],\[\[u([0-9a-f]+)-u([0-9a-f]+)\]\]$/) {
      my $c1 = sprintf ':u-cdp-%x', hex $1;
      my $c1_0 = u_chr hex $1;
      my $c2 = sprintf ':b5-cdp-%x', hex $2;
      my $c2_0 = sprintf ':b5-%x', hex $2;
      my $c3 = u_chr hex $3;
      $c3 .= u_chr hex $4;
      my $rel_type = 'glyphwiki:UCSで符号化されたCDP外字';
      my $key = get_vkey $c3;
      $Data->{$key}->{$c1}->{$c3}->{$rel_type} = 1;
      $Data->{$key}->{$c2}->{$c3}->{$rel_type} = 1;
      $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:same'} = 1;
    } elsif (/^,\[\[u([0-9a-f]+) cdp-([0-9a-f]+)\]\],\[\[koseki-([0-9]+)\]\]$/) {
      my $c1 = sprintf ':u-cdp-%x', hex $1;
      my $c1_0 = u_chr hex $1;
      my $c2 = sprintf ':b5-cdp-%x', hex $2;
      my $c2_0 = sprintf ':b5-%x', hex $2;
      my $c3 = sprintf ':koseki%s', $3;
      my $rel_type = 'glyphwiki:UCSで符号化されたCDP外字';
      my $key = 'hans';
      $Data->{$key}->{$c1}->{$c3}->{$rel_type} = 1;
      $Data->{$key}->{$c2}->{$c3}->{$rel_type} = 1;
      $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:same'} = 1;
    } elsif (/^,\[\[u([0-9a-f]+) cdp-([0-9a-f]+)\]\],\[\[cdp-([0-9a-f]+)\]\]$/) {
      my $c1 = sprintf ':u-cdp-%x', hex $1;
      my $c1_0 = u_chr hex $1;
      my $c2 = sprintf ':b5-cdp-%x', hex $2;
      my $c2_0 = sprintf ':b5-%x', hex $2;
      my $c3 = sprintf ':b5-cdp-%x', hex $3;
      my $rel_type = 'glyphwiki:UCSで符号化されたCDP外字';
      my $key = 'hans';
      $Data->{$key}->{$c1}->{$c3}->{$rel_type} = 1;
      $Data->{$key}->{$c2}->{$c3}->{$rel_type} = 1;
      $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:same'} = 1;
    } elsif (/^こちらの/) {
      #
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
  
  $path = $TempPath->child ('gw-cdp-all.txt');
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (/^\[\[u([0-9a-f]+) cdp-([0-9a-f]+)\]\]$/) {
      my $c1 = sprintf ':u-cdp-%x', hex $1;
      my $c1_0 = u_chr hex $1;
      my $c2 = sprintf ':b5-cdp-%x', hex $2;
      my $c2_0 = sprintf ':b5-%x', hex $2;
      my $key = $ToVKey->{$c1} // 'hans';
      $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:same'} = 1;
    } elsif (/^\[\[/) {
      die "Bad line |$_|";
    }
  }
}


{
  my $path = $TempPath->child ('gw-cjkeunified.txt');
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (/^,\s*[0-9]+\s*,\s*\[\[(?:u([0-9a-f]+)|extd-([0-9]+))\]\]\s*,\s*\[\[extd-([0-9]+)\]\]\s*,(.+?)\s*$/) {
      my $c1 = (defined $1 ? chr hex $1 : sprintf ':extd%d', $2);
      my $key = defined $1 ? get_vkey $c1 : 'hans';
      my $c2 = sprintf ':extd%d', $3;
      $Data->{$key}->{$c1}->{$c2}->{'glyphwiki:unified'} = 1;
      my @s3 = split /,/, $4;
      for my $s3 (@s3) {
        if ($s3 =~ /^T([0-9A-F]+)-([0-9A-F]{2})([0-9A-F]{2})$/) {
          my $c3 = sprintf ':cns%d-%d-%d',
              hex $1,
              (hex $2) - 0x20,
              (hex $3) - 0x20;
          $Data->{$key}->{$c1}->{$c3}->{'glyphwiki:unified'} = 1;
        } elsif ($s3 =~ /^V04-([0-9A-F]{2})([0-9A-F]{2})$/) {
          my $c3 = sprintf ':v3-%d-%d',
              (hex $1) - 0x20,
              (hex $2) - 0x20;
          $Data->{$key}->{$c1}->{$c3}->{'glyphwiki:unified'} = 1;
        } elsif ($s3 =~ /^UTC([0-9]+)$/) {
          my $c3 = sprintf ':UTC-%s', $1;
          $Data->{$key}->{$c1}->{$c3}->{'glyphwiki:unified'} = 1;
        } elsif ($s3 =~ /^MAC([0-9]+)$/) {
          #
        } elsif ($s3 =~ /^G/) {
          #
        } elsif ($s3 =~ /^JK-([0-9]+)$/) {
          my $c3 = sprintf ':m%d', $1;
          $Data->{$key}->{$c1}->{$c3}->{'glyphwiki:unified'} = 1;
        } elsif ($s3 =~ /^KP1-([0-9A-F]+)$/) {
          my $c3 = sprintf ':kp1%x', hex $1;
          $Data->{$key}->{$c1}->{$c3}->{'glyphwiki:unified'} = 1;
        } elsif ($s3 =~ /\S/) {
          die "Bad value |$s3|";
        }
      }
    }
  }
}

my $Jouyou = {};
my $JouyouOld = {};
{
  my $path = $ThisPath->parent->child ('jp/jouyouh22-table.json');
  my $json = json_bytes2perl $path->slurp;
  for my $char (keys %{$json->{jouyou}}) {
    my $in = $json->{jouyou}->{$char};
    $Jouyou->{$char} = $in->{index};
    for (@{$in->{old} or []}) {
      $JouyouOld->{$_} = $in->{index};
    }
    if ($in->{old_image}) {
      use utf8;
      $JouyouOld->{"龜"} = $in->{index};
    }
  }
}
{
  my $path = $TempPath->child ('gw-jouyoukoseki.txt');
  for (split /\n/, extract_source $path->slurp) {
    if (m{^\[\[(\w) koseki-([0-9]+)\]\]\s*$}) {
      my $char = $1;
      my $jouyou = $Jouyou->{$char} or die $_;
      my $c1 = sprintf ':jouyou-h22-%d', $jouyou;
      my $c2 = sprintf ':koseki%s', $2;
      $Data->{hans}->{$c1}->{$c2}->{'glyphwiki:koseki'} = 1;

      use utf8;
      if ({map { $_ => 1 } qw(串 伎 侶 俺 僅 冥 冶 凄 刹 勃 勾 匂 呂 唄 埼 堆 塞 塡 奈 妖 媛 宛 岡 崖 嵐 巾 弥 憧 戚 戴 拶 拭 挨 拳 捉 捻 斑 旦 旺 昧 曖 曽 枕 柵 柿 栃 桁 梗 梨 椅 椎 汎 沙 汰 湧 煎 熊 爪 爽 牙 玩 瑠 璃 瓦 畏 畿 眉 睦 瞳 瞭 稽 窟 箸 羨 肘 脇 腎 膳 臆 臼 舷 艶 芯 茨 葛 蓋 蔽 藤 藍 虎 虹 蜂 蜜 袖 裾 詣 詮 誰 諦 謎 貌 貼 蹴 遡 遜 那 酎 醒 采 釜 錦 鍋 鍵 鎌 闇 阜 阪 隙 韓 頃 須 頓 頰 餅 駒 鶴 鹿 麓 亀)}->{$char}) {
        my $c3 = sprintf ':jinmei-%s', $char;
        $Data->{hans}->{$c3}->{$c2}->{'glyphwiki:koseki'} = 1;
        $Data->{hans}->{$c3}->{$c1}->{'manakai:newrevision'} = 1;
      }
    }
  }
}
{
  use utf8;
  my $char;
  my $connected;
  my $path = $TempPath->child ('gw-jinmeikoseki.txt');
  for (split /\n/, extract_source $path->slurp) {
    if (m{^\[\[(\w) koseki-([0-9]+)\]\]\s*$}) {
      my $c = $1;
      my $c1 = sprintf ':jinmei-%s', $c;
      my $c2 = sprintf ':koseki%s', $2;
      $Data->{hans}->{$c1}->{$c2}->{'glyphwiki:koseki'} = 1;
      if ($connected) {
        my $c3 = sprintf ':jinmei-%s', $char;
        $Data->{hans}->{$c3}->{$c1}->{'jinmei:同一の字種'} = 1;
        $Data->{hans}->{$c3}->{$c1}->{'jinmeih16:同一の字種'} = 1
            unless $char eq "禱" or $char eq "祷";
        $connected = 0;
      }
      $char = $c;
    } elsif (m{^\((\p{Han})\)\s*$}) {
      my $c3 = sprintf ':jinmei-%s', $char;
      my $jouyou = $Jouyou->{$1} or die $_;
      my $c4 = sprintf ':jouyou-h22-%d', $jouyou;
      $Data->{hans}->{$c3}->{$c4}->{'jinmei:つながり'} = 1;
      if ($1 eq "曽" or $1 eq "弥") {
        my $c5 = sprintf ':jinmei-%s', $1;
        $Data->{hans}->{$c3}->{$c5}->{'jinmeih16:同一の字種'} = 1
      } else {
        $Data->{hans}->{$c3}->{$c4}->{'jinmeih16:つながり'} = 1
      }
    } elsif (m{^―\s*$}) {
      $connected = 1;
    }
  }
}
{
  my $path = $TempPath->child ('gw-jouyouoldmj.txt');
  for (split /\n/, extract_source $path->slurp) {
    if (m{^\[\[(\w) jmj-([0-9]+)\]\]\s*$}) {
      my $char = $1;
      my $jouyou = $JouyouOld->{$char} or die $char;
      my $c1 = sprintf ':jouyou-h22old-%d', $jouyou;
      my $c2 = sprintf ':MJ%s', $2;
      $Data->{hans}->{$c1}->{$c2}->{'glyphwiki:mj'} = 1;
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
    my $key = get_vkey $c1;
    my $type = 'kana:manyou';
    $type = 'manakai:idu' if $key eq 'kchars';
    for my $c2 (@v) {
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    }
    if ($c1 =~ /^:(.)/) {
      $Data->{$key}->{$1}->{$c1}->{'manakai:unified'} = 1;
    }
  }
}

my $JA2Char = {};
{
  my $path = $TempUCPath->child ('unihan3.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^U\+([0-9A-F]+)\s+(kIRG_JSource)\s+([A])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c1 = u_chr hex $1;
      my $jis = sprintf '%d-%d-%d', hex $3, (hex $4) - 0x20, (hex $5) - 0x20;
      $JA2Char->{$jis} = $c1;
    }
  }
  $JA2Char->{"10-6-43"} = "\x{FA1F}";
}

for (
  ['gmap.json', 'hans'],
  ['kana-gmap.json', 'kanas'],
) {
  my $path = $ThisPath->parent->child ('misc/' . $_->[0]);
  my $key = $_->[1];
  
  my $UnicodeRelTypes = {
    DIS12 => 'iso10646:1992:X:glyph',
    1993 => 'iso10646:1993:X:glyph',
    2000 => 'iso10646:2000:X:glyph',
    2003 => 'iso10646:2003:X:glyph',
    2008 => 'iso10646:2008:X:glyph',
    2010 => 'iso10646:2010:X:glyph',
    2020 => 'iso10646:2020:X:glyph',
    2023 => 'iso10646:2023:X:glyph',
    U2 => 'unicode2:X:glyph',
    U31 => 'unicode3.1:X:glyph',
    U32 => 'unicode3.2:X:glyph',
    U51 => 'unicode5.1:X:glyph',
    U52 => 'unicode5.2:X:glyph',
    U6 => 'unicode6:X:glyph',
    U61 => 'unicode6.1:X:glyph',
    U62 => 'unicode6.2:X:glyph',
    U9 => 'unicode9:X:glyph',
    U10 => 'unicode10:X:glyph',
    U13 => 'unicode13:X:glyph',
    U14 => 'unicode14:X:glyph',
    U15 => 'unicode15:X:glyph',
    U151 => 'unicode15.1:X:glyph',
    "18030-2022" => 'gb18030:2022:glyph',
  };
  
  my $json = json_bytes2perl $path->slurp;
    my $sel = sub {
    my $x = shift;
    return undef unless defined $x;
    if ($x->[0] eq 'mj' or $x->[0] eq 'gw' or $x->[0] eq 'g') {
      return $x->[1];
    } elsif ($x->[0] eq 'aj' and $x->[2] eq 'shs') {
      my $v = $x->[1];
      $v =~ s/^aj/shs/;
      return $v;
    } elsif ($x->[0] eq 'ucsT' and $x->[2] eq '') {
      return 'cns' . $x->[1];
    } else {
      die perl2json_bytes $x;
    }
  };
  for my $group_list (@{$json->{groups}}) {
    my $prev_group_c;
    for my $group (@$group_list) {
    for (
      ['jistype', 'simplified', ':jistype-simplified-%s', ''],
      ['koseki', '', ':koseki%s', ''],
      ['touki', '', ':touki%s', ''],
      ['juuki', '', ':u-juki-%x', 'x'],
      ['UTC', '', ':UTC-%s', ''],
      ['UCI', '', ':UCI-%s', ''],
    ) {
      my ($k1, $k2, $f, $cnv) = @$_;
      for (keys %{$group->{$k1}->{$k2} or {}}) {
        my $v = $_;
        $v = hex $v if $cnv eq 'x';
        my $c1 = sprintf $f, $v;
        if (defined $group->{selected}) {
          my $glyph = $sel->($group->{selected});
          my $c2 = glyph_to_char $glyph;
          $Data->{$key}->{$c1}->{$c2}->{'manakai:equivglyph'} = 1;
        } elsif (defined $group->{selected_similar}) {
          my $glyph = $sel->($group->{selected_similar});
          my $c2 = glyph_to_char $glyph;
          $Data->{$key}->{$c1}->{$c2}->{'manakai:similarglyph'} = 1;
        } else {
          #warn "No glyph for |$c1|";
        }
      }
    }
    for my $c (keys %{$group->{jouyou}->{kyoyou} or {}}) {
      my $jouyou = $Jouyou->{$c} or die $_;
      my $c1 = sprintf ':jouyou-h22kyoyou-%d', $jouyou;
      if (defined $group->{selected}) {
        my $glyph = $sel->($group->{selected});
        die "Bad glyph for |$c1| ($glyph)" unless $glyph =~ /^MJ/;
        my $c2 = glyph_to_char $glyph;
        $Data->{$key}->{$c1}->{$c2}->{'manakai:hasglyph'} = 1;
      } else {
        #warn "No glyph for |$c1|";
      }
    }
    for my $k2 (keys %{$group->{jis} or {}}) {
      for my $jis (keys %{$group->{jis}->{$k2} or {}}) {
        next unless $jis =~ /^10-/;
        next if {
          2011 => 1,
          2016 => 1,
        }->{$k2};
        my $rel_type = $UnicodeRelTypes->{$k2} // die "Bad key2 |$k2|";
        $rel_type =~ s/:X:/:j:/;
        my $c1 = $JA2Char->{$jis};
        #$c1 = ':jis' . $jis if not defined $c1;
        die "Bad JA |$jis|" unless defined $c1;
        if (defined $group->{selected}) {
          my $glyph = $sel->($group->{selected});
          my $c2 = glyph_to_char $glyph;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type.':equiv'} = 1;
        } elsif (defined $group->{selected_similar}) {
          my $glyph = $sel->($group->{selected_similar});
          my $c2 = glyph_to_char $glyph;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type.':similar'} = 1;
        } else {
          #warn "No glyph for |$c1|";
        }
      }
    }
    for (
      ['ucsG', ':g:'],
      ['ucsH', ':h:'],
      ['ucsM', ':m:'],
      ['ucsT', ':t:'],
      ['ucs', ':j:'],
      ['ucsK', ':k:'],
      ['ucsKP', ':kp:'],
      ['ucsV', ':v:'],
      ['ucsU', ':u:'],
      ['ucsS', ':s:'],
      ['ucsUK', ':uk:'],
      ['ucsUCS2003', ':ucs2003:'],
    ) {
      my ($k1, $type) = @$_;
      for my $k2 (keys %{$group->{$k1}}) {
        next if {
          2011 => 1,
          2016 => 1,
          ipa1 => 1,
          ipa3 => 1,
          ipa1v => 1,
          ipa3v => 1,
          ex => 1,
          exv => 1,
          mj => 1,
          mjv => 1,
          SWC => 1,
        }->{$k2};
        my $rel_type = $UnicodeRelTypes->{$k2} // die $k2;
        $rel_type =~ s/:X:/$type/;
        for (keys %{$group->{$k1}->{$k2} or {}}) {
          my $c1 = chr hex $_;
          if (defined $group->{selected}) {
            my $glyph = $sel->($group->{selected});
            my $c2 = glyph_to_char $glyph;
            $Data->{$key}->{$c1}->{$c2}->{$rel_type.':equiv'} = 1;
          } elsif (defined $group->{selected_similar}) {
            my $glyph = $sel->($group->{selected_similar});
            my $c2 = glyph_to_char $glyph;
            $Data->{$key}->{$c1}->{$c2}->{$rel_type.':similar'} = 1;
          } else {
            #warn "No glyph for |$c1|";
          }
        }
      }
    }
    {
      my $k1 = 'uni';
      for my $k2 (keys %{$group->{$k1}}) {
        my $rel_type = $UnicodeRelTypes->{$k2};
        next unless defined $rel_type;
        $rel_type =~ s/:X:/:u:/;
        
        for (keys %{$group->{$k1}->{$k2} or {}}) {
          my $c1 = chr hex $_;
          if (defined $group->{selected}) {
            my $glyph = $sel->($group->{selected});
            my $c2 = glyph_to_char $glyph;
            $Data->{$key}->{$c1}->{$c2}->{$rel_type.':equiv'} = 1;
          } elsif (defined $group->{selected_similar}) {
            my $glyph = $sel->($group->{selected_similar});
            my $c2 = glyph_to_char $glyph;
            $Data->{$key}->{$c1}->{$c2}->{$rel_type.':similar'} = 1;
          } else {
            #warn "No glyph for |$c1|";
          }
        }
      }
    }

    my @c1;
    for (sort { $a cmp $b } keys %{$group->{mj}->{''} or {}}) {
      push @c1, ':' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{heisei}->{''} or {}}) {
      push @c1, ':' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{aj}->{''} or {}}) {
      push @c1, ':' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{aj}->{shs} or {}}) {
      my $x = $_;
      $x =~ s/^aj/aj-shs-/;
      push @c1, ':' . $x;
    }
    for (sort { $a cmp $b } keys %{$group->{gw}->{''} or {}}) {
      push @c1, ':gw-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{g}->{''} or {}}) {
      push @c1, ':sw' . $_; # :swg{d}
    }
    for (sort { $a cmp $b } keys %{$group->{jis}->{16} or {}}) {
      push @c1, ':jis-dot16-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{jis}->{24} or {}}) {
      push @c1, ':jis-dot16-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{jisrev}->{''} or {}}) {
      push @c1, ':jis-pubrev-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{cns}->{kai} or {}}) {
      push @c1, ':cns-kai-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{cns}->{sung} or {}}) {
      push @c1, ':cns-sung-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{gb}->{''} or {}}) {
      if (/^20-/ or /^1-93-/) { # GK
        push @c1, ':gb' . $_;
      }
    }
    for (sort { $a cmp $b } keys %{$group->{ks}->{''} or {}}) {
      push @c1, ':ks' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{inherited}->{''} or {}}) {
      push @c1, ':inherited-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{m}->{''} or {}}) {
      push @c1, ':m' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{irg2021}->{''} or {}}) {
      push @c1, ':irg2021-' . $_;
    }
    next unless @c1;
    my $c1 = shift @c1;
    for my $c2 (@c1) {
      $Data->{$key}->{$c1}->{$c2}->{'manakai:equivglyph'} = 1;
    }
    if (defined $prev_group_c) {
      $Data->{$key}->{$prev_group_c}->{$c1}->{'manakai:similarglyph'} = 1;
    }
      $prev_group_c = $c1;
    } # $group
  } # $group_list
}

write_rel_data_sets
    $Data => $ThisPath, 'maps',
    [
      qr/[\x{3000}-\x{5FFF}]/,
      qr/[\x{6000}-\x{7FFF}]/,
      qr/[\x{8000}-\x{FFFF}]/,
      qr/[\x{20000}-\x{3FFFF}]/,
      qr/^:u/,
      qr/^:[kt]/,
      qr/^:[a-z]/,
    ];

{
  my $path = $TempPath->child ('gwreltypes.json');
  $path->spew (perl2json_bytes [sort { $a cmp $b } keys %$GWRels]);
}

## License: Public Domain.
