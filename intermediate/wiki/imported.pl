use strict;
use warnings;
use Path::Tiny;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');
my $RepoPath = $TempPath->child ('repos/data-chartables');

my $Data = {};

my $Type = {};

for (
  ["cho5-bbb-utf8.txt", "btron:utf-8", undef],
  ["cho5-bbb-gb2312.txt", "btron:gb2312", ":gbk%x"],
  ["cho5-bbb-eucjp.txt", "btron:euc-jp", ":ascii-%x"],
  ["cho5-bbb-euckr.txt", "btron:euc-kr", ":ascii-%x"],
  ["cho5-bbb-sjis.txt", "btron:shift_jis", ":jisx0201-%x"],
  ["cho5-bbb-sjis-imode.txt", "btron:shift_jis-imode", undef],
  ["cho5-bbb-iso88591.txt", "btron:iso-8859-1", ":isolatin1-%x"],
  ["cho5-bbb-iso2022jp.txt", "btron:iso-2022-jp", undef],
  ["cho5-bbb-big5.txt", "btron:big5", ":b5-%x"],
) {
  my $path = $RepoPath->child ('tron/' . $_->[0]);
  my $type = $_->[1];
  my $cpattern = $_->[2];
  my $section;
  for (split /\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^\*\s*(\S.*\S)\s*$/) {
      $section = $1;
    } elsif (/^0x([0-9A-F]{2})\t([0-9]+)-([0-9A-F]+)$/) {
      if (defined $cpattern) {
        my $c1 = sprintf $cpattern, hex $1;
        my $c2 = sprintf ":tron%d-%x", $2, hex $3;
        my $key = $Type->{$c2} = get_vkey $c1;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif (/^0x([0-9A-F]{4,6})\t([0-9]+)-([0-9A-F]+)$/) {
      my $x3 = hex $3;
      if ($type eq "btron:big5") {
        my $c1 = sprintf $cpattern, hex $1;
        my $c2 = sprintf ":tron%d-%x", $2, $x3;
        my $key = $Type->{$c2} = $Type->{$c1} // get_vkey $c1;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      } elsif ($type eq "btron:utf-8") {
        my $c1 = chr hex $1;
        my $c2 = sprintf ":tron%d-%x", $2, $x3;
        my $key = $Type->{$c2} = $Type->{$c1} // get_vkey $c1;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      } elsif ($type eq "btron:shift_jis-imode" and $x3 >= 0xF000) {
        my $c2 = sprintf ":tron%d-%x", $2, $x3;
        my $ku = (int ($x3 / 0x100) - 0xE0) * 2 + 1 + 94 - 32;
        my $ten = (hex $1) % 0x100;
        if ($ten > 0xFC - 94) {
          $ten = $ten - (0xFC - 94);
          $ku++;
        } elsif ($ten > 0x7F) {
          $ten = $ten - 0x40 + 1 - 1;
        } else {
          $ten = $ten - 0x40 + 1;
        }
        my $c1 = sprintf ":jis-imode-1-%d-%d", $ku, $ten;
        my $key = get_vkey $c1;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif (/^U\+([0-9A-F]+)\t([0-9]+)-([0-9A-F]+)$/) {
      my $c2 = sprintf ":tron%d-%x", $2, hex $3;
      my $c1 = chr hex $1;
      my $key = $Type->{$c2} = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (/^0x1B2842-0x([0-9A-F]{2})\t([0-9]+)-([0-9A-F]+)$/) {
      my $c1 = sprintf ":ascii-%x", hex $1;
      my $c2 = sprintf ":tron%d-%x", $2, hex $3;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (/^0x1B284A-0x([0-9A-F]{2})\t([0-9]+)-([0-9A-F]+)$/) {
      my $c1 = sprintf ":jisx0201-%x", hex $1;
      my $c2 = sprintf ":tron%d-%x", $2, hex $3;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (/^0x1B[0-9A-F]+-0x([0-9A-F]{4})\t([0-9]+)-([0-9A-F]+)$/) {
      #
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  use utf8;
  my $section = '';
  my $hotsuma = {};
  my @hotsuma;
  my $path = $RepoPath->child ('tron/tron.txt');
  for (split /\x0A/, $path->slurp_utf8) {
    if (/^\*\s*(\S.*\S)\s*$/) {
      $section = $1;
    } elsif (/^\s*#/) {
      #
    } elsif ($section eq "" and
             /^([0-9]+)-([0-9A-F]+)(?:\tU\+([0-9A-F]+)|)$/) { # controls
      #
    } elsif (($section eq "日本基本" or $section eq '日本補助') and
             /^([0-9]+)-([0-9A-F]+)\t([0-9]+)-([0-9]+)-([0-9]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":jis%d-%d-%d", $3, $4, $5;
      my $key = get_vkey $c2;
      my $type = 'tron:definition';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif ($section eq "中国基本" and
             /^([0-9]+)-([0-9A-F]+)\t([0-9]+)-([0-9]+)-([0-9]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":gb%d-%d-%d", $3, $4, $5;
      my $key = get_vkey $c2;
      my $type = 'tron:definition';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif ($section eq "韓国" and
             /^([0-9]+)-([0-9A-F]+)\t([0-9]+)-([0-9]+)-([0-9]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":ks%d-%d-%d", $3, $4, $5;
      my $key = get_vkey $c2;
      my $type = 'tron:definition';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif ($section eq "CNS 11643" and
             /^([0-9]+)-([0-9A-F]+)\t([0-9]+)-([0-9]+)-([0-9]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":cns%d-%d-%d", $3, $4, $5;
      my $key = get_vkey $c2;
      my $type = 'tron:definition';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (($section eq "六点点字" or $section eq "八点点字") and
             /^([0-9]+)-([0-9A-F]+)\t([0-9]+)-([0-9]+)\tU\+([0-9A-F]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = chr hex $5;
      my $key = get_vkey $c2;
      my $type = 'manakai:unified';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif ($section eq "GT" and
             /^([0-9]+)-([0-9A-F]+)\t([0-9]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":gt%d", $3;
      my $key = get_vkey $c2;
      my $type = 'tron:definition';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (($section eq "大漢和" or $section eq "削除") and
             /^([0-9]+)-([0-9A-F]+)\t(h?)([0-9]+)('*)\t?$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":m%s%d%s", $3, $4, $5;
      my $key = get_vkey $c2;
      my $type = 'tron:definition';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif ($section eq "削除" and
             /^([0-9]+)-([0-9A-F]+)\t([0-9]+)\t(\S*)\t(\S*)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":m%d", $3;
      my $key = 'kanas';
      my $type = 'tron:definition';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      my $x = $4;
      my $y = $5;
      for (split /;/, $x) {
        my $c2 = $_;
        $c2 =~ s/^<([0-9]+)-([0-9A-F]+)>$/sprintf ':tron%d-%x', $1, hex $2/ge;
        my $type = 'kana:origin';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
      for (split /;/, $y) {
        my $c2 = $_;
        $c2 =~ s/^<([0-9]+)-([0-9A-F]+)>$/sprintf ':tron%d-%x', $1, hex $2/ge;
        my $type = 'kana:modern';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif ($section eq "濁点仮名" and
             /^([0-9]+)-([0-9A-F]+)\t[0-9]+\t(\S+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = $3;
      my $key = get_vkey $c2;
      my $type = 'manakai:unified';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif ($section eq "住基仮名" and
             /^([0-9]+)-([0-9A-F]+)\t[0-9]+\t(\S+)\t(\S+)\tJ\+([0-9A-F]+)\tMJ[0-9]+$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":u-juki-%x", hex $5;
      my $key = get_vkey $c2;
      my $type = 'tron:definition';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif ($section eq "変体仮名" and
             /^([0-9]+)-([0-9A-F]+)\t[0-9]+\t(\S*)\t(\S*)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $x = $3;
      my $y = $4;
      my $key = 'kanas';
      for (split /;/, $x) {
        my $c2 = $_;
        $c2 =~ s/^<([0-9]+)-([0-9A-F]+)>$/sprintf ':tron%d-%x', $1, hex $2/ge;
        my $type = 'kana:origin';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
      for (split /;/, $y) {
        my $c2 = $_;
        $c2 =~ s/^<([0-9]+)-([0-9A-F]+)>$/sprintf ':tron%d-%x', $1, hex $2/ge;
        my $type = 'kana:modern';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif ($section eq "iモード" and
             /^([0-9]+)-([0-9A-F]+)\t([0-9]+)\t(\S*)\t(\S*)\t(\S*)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c1old = sprintf ":tronold%d-%x", $1, hex $2;
      my $s = $3;
      my $old = $5;
      my $new = $6;
      {
        my $ku = (int ($s / 0x100) - 0xF0) * 2 + 1 + 94;
        my $ten = $s % 0x100;
        if ($ten > 0xFC - 94) {
          $ten = $ten - (0xFC - 94);
          $ku++;
        } elsif ($ten > 0x7F) {
          $ten = $ten - 0x40 + 1 - 1;
        } else {
          $ten = $ten - 0x40 + 1;
        }
        my $c2 = sprintf ":jis-imode-1-%d-%d", $ku, $ten;
        my $key = get_vkey $c2;
        my $type = 'tron:definition';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        unless ($old eq $new) {
          $Data->{$key}->{$c1old}->{$c2}->{$type} = 1;
          $Data->{codes}->{$c1old}->{$c1}->{"manakai:private"} = 1;
        }
      }
      {
        last if $old eq $new;
        my $c2;
        if ($old =~ /^[0-9]+$/) {
          $c2 = sprintf ":imode%d", $old;
        } elsif ($old =~ /^拡([0-9]+)$/) {
          $c2 = sprintf ":imodex%d", $1;
        } else {
          last;
        }
        my $key = get_vkey $c2;
        my $type = 'manakai:unified';
        $Data->{$key}->{$c1old}->{$c2}->{$type} = 1;
      }
      {
        my $c2;
        if ($new =~ /^[0-9]+$/) {
          $c2 = sprintf ":imode%d", $new;
        } elsif ($new =~ /^拡([0-9]+)$/) {
          $c2 = sprintf ":imodex%d", $1;
        } else {
          last;
        }
        my $key = get_vkey $c2;
        my $type = 'manakai:unified';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif ($section eq "ホツマ" and
             /^([0-9]+)-([0-9A-F]+)\t[0-9]+\t(.*)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $x = $3;
      if ($x =~ /^(\S+)\s異体字$/) {
        my $c2 = $1;
        my $c3 = $hotsuma->{$c2} or die $c2;
        my $key = get_vkey $c2;
        my $type = 'tron:ホツマ:異体字';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        $Data->{$key}->{$c3}->{$c1}->{"manakai:variant"} = 1;
      } elsif ($x =~ /^(\S+)$/) {
        my $c2 = {"φ" => "∅"}->{$1} // $1;
        my $key = get_vkey $c2;
        my $type = 'manakai:related';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        $hotsuma->{$c2} = $c1;
        push @hotsuma, [$c1, $c2];
      }
    } elsif ($section eq "陰陽五行" and
             /^([0-9]+)-([0-9A-F]+)\t[0-9]+\t(\S*)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $x = $3;
      if ($x =~ /^U\+([0-9A-F]+)$/) {
        my $c2 = chr hex $1;
        my $key = get_vkey $c2;
        my $type = 'manakai:unified';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      } elsif ($x =~ /\S/) {
        #
      }
    } elsif ($section eq "序数" and
             /^([0-9]+)-([0-9A-F]+)\t[0-9]+\t(\S+)\t(\S+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = $3;
      my $key = get_vkey $c2;
      my $type = 'manakai:related';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif ($section eq "序数" and /^([0-9]+)-([0-9A-F]+)\t[0-9]+\t$/) {
      #
    } elsif ($section eq "アーヴ" and
             /^([0-9]+)-([0-9A-F]+)\t[0-9]+\t(\S*)(?:\t(\S*)|)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      if (length $3) {
        my $c2 = {
          '空白' => ' ',
        }->{$3} // $3;
        my $key = 'descs'; #get_vkey $c1;
        my $type = 'tron:転写';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
      if (defined $4 and length $4) {
        my $c2 = {
          '空白' => ' ',
        }->{$3} // $3;
        my $key = 'descs'; #get_vkey $c1;
        my $type = 'tron:音価';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif ($section eq "トンパ" and
             /^([0-9]+)-([0-9A-F]+)\t[0-9]+$/) {
      #
    } elsif ($section eq "Unicode" and
             /^([0-9]+)-([0-9A-F]+)\tU\+([0-9A-F]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = chr hex $3;
      my $key = $Type->{$c1} = get_vkey $c2;
      my $type = 'tron:definition';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif ($section eq "中国拡張" and
             /^([0-9]+)-([0-9A-F]+)\t0x([0-9A-F]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":gbk%x", hex $3;
      my $key = get_vkey $c2;
      my $type = 'tron:definition';
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (/\S/) {
      die "Bad line |$_| ($section)";
    }
  }

  for (@hotsuma) {
    my ($c1, $c2) = @$_;
    my $key = 'descs'; #get_vkey $c2;
    if ("あかさたなはまやらわがざだばぱ" =~ /$c2/) {
      my $c3 = $hotsuma->{"ａ"} // die $c1;
          my $type3 = "tron:ホツマ:段";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("いきしちにひみ𛀆りゐぎじぢびぴ" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｉ"} // die $c1;
          my $type3 = "tron:ホツマ:段";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("うくすつぬふむゆるうぐずづぶぷ" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｕ"} // die $c1;
          my $type3 = "tron:ホツマ:段";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("えけせてねへめ𛀁れゑげぜでべぺ" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｅ"} // die $c1;
          my $type3 = "tron:ホツマ:段";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("おこそとのほもよろをごぞどぼぽ" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｏ"} // die $c1;
          my $type3 = "tron:ホツマ:段";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        }
    if ("あいうえお" =~ /$c2/) {
      my $c3 = $hotsuma->{"∅"} // die $c1;
      my $type3 = "tron:ホツマ:行";
      $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
    } elsif ("かきくけこ" =~ /$c2/) {
      my $c3 = $hotsuma->{"ｋ"} // die $c1;
          my $type3 = "tron:ホツマ:行";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("さしすせそ" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｋ"} // die $c1;
          my $type3 = "tron:ホツマ:行";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("たちつてと" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｔ"} // die $c1;
          my $type3 = "tron:ホツマ:行";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("なにぬねの" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｎ"} // die $c1;
          my $type3 = "tron:ホツマ:行";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("はひふへほ" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｈ"} // die $c1;
          my $type3 = "tron:ホツマ:行";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("まみむめも" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｍ"} // die $c1;
          my $type3 = "tron:ホツマ:行";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("や𛀆ゆ𛀁よ" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｙ"} // die $c1;
          my $type3 = "tron:ホツマ:行";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("らりるれろ" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｒ"} // die $c1;
          my $type3 = "tron:ホツマ:行";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        } elsif ("わを" =~ /$c2/) {
          my $c3 = $hotsuma->{"ｗ"} // die $c1;
          my $type3 = "tron:ホツマ:行";
          $Data->{$key}->{$c1}->{$c3}->{$type3} = 1;
        }
  }
}

{
  my $path = $RepoPath->child ('tron/fixed.txt');
  for (split /\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^([0-9])-([0-9A-F]+)\t([0-9])-([0-9A-F]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":tron%d-%x", $3, hex $4;
      if ($c1 =~ s/:tron9-92/:tronold9-92/) {
        my $key = get_vkey $c2;
        my $type = 'tron:fixed';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      } else {
        my $key = get_vkey $c2;
        my $type = 'tron:removed';
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

for (
  ["ssfonts-glyph-shared.txt", "ss:glyph-shared"],
  ["gtfont-glyph-shared.txt", "gt:glyph-shared"],
  ["tfonts-glyph-shared.txt", "t:glyph-shared"],
) {
  my $path = $RepoPath->child ('tron/' . $_->[0]);
  my $type = $_->[1];
  for (split /\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^([0-9]+)-([0-9A-F]+)\t([0-9]+)-([0-9A-F]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":tron%d-%x", $3, hex $4;
      my $key = $Type->{$c2} = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (/\S/) {
      die "$path: Bad line |$_|";
    }
  }
}

{
  my $path = $RepoPath->child ('tron/wenjian.txt');
  my $type = $_->[1];
  my $section;
  for (split /\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^\*\s*(\S.*\S)\s*$/) {
      $section = $1;
    } elsif (/^([0-9]+)-([0-9A-F]+)\t([0-9]+)-([0-9A-F]+)$/) {
      my $c1 = sprintf ":tron%d-%x", $1, hex $2;
      my $c2 = sprintf ":tron%d-%x", $3, hex $4;
      my $key = $Type->{$c1} // $Type->{$c2} // get_vkey $c1;
      my $type = "wenjian:$section";
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (/^U\+([0-9A-F]+)\t([0-9]+)-([0-9A-F]+)$/) {
      my $c2 = sprintf ":tron%d-%x", $2, hex $3;
      my $c1 = chr hex $1;
      my $key = $Type->{$c1} = get_vkey $c2;
      my $type = "wenjian:$section";
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (/^0x([0-9A-F]+)\t([0-9]+)-([0-9A-F]+)$/) {
      my $c2 = sprintf ":tron%d-%x", $2, hex $3;
        my $ku = (int ((hex $3) / 0x100) - 0xE0) * 2 + 1 + 94 - 32;
        my $ten = (hex $1) % 0x100;
        if ($ten > 0xFC - 94) {
          $ten = $ten - (0xFC - 94);
          $ku++;
        } elsif ($ten > 0x7F) {
          $ten = $ten - 0x40 + 1 - 1;
        } else {
          $ten = $ten - 0x40 + 1;
        }
      my $c1 = sprintf ":jis-dos-1-%d-%d", $ku, $ten;
      my $key = $Type->{$c1} // get_vkey $c2;
      my $type = "wenjian:$section";
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $TempPath->child ('swir-list.json');
  my $json = json_bytes2perl $path->slurp;
  for my $group (values %{$json->{groups}}) {
    next unless defined $group->{features};
    my $ff = [split /\./, $group->{features}];
    my $vv = [map { sprintf '%x', ord $_ } split //, $group->{value}];
    my $c1 = join '-', ':u-swk', @$vv, @$ff;
    my $c2 = $group->{value};
    $Data->{rels}->{$c1}->{$c2}->{'manakai:related'} = 1;
  }
}

write_rel_data_sets
    $Data => $TempPath, 'imported',
    [];

## License: Public Domain.
