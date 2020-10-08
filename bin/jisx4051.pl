use strict;
use warnings;
use utf8;
use Path::Tiny;

my $RootPath = path (__FILE__)->parent->parent;
my $DestPath = $RootPath->child ('src/set');

sub write_set ($$%) {
  my ($name, $hashref, %args) = @_;
  $args{sw} //= 'JIS X 4151';

  my $lines = [];
  push @$lines, '#label:' . $args{label} if  defined $args{label};
  push @$lines, '#sw:' . $args{sw} if  defined $args{sw};
  push @$lines, '#url:' . $args{url} if  defined $args{url};
  push @$lines, '[';

  for (sort { $a <=> $b } keys %$hashref) {
    push @$lines, sprintf '\u{%04X}', $_;
  }
  
  push @$lines, ']';
  if (defined $args{additional}) {
    push @$lines, '|', $args{additional};
  }

  $DestPath->child ("$name.expr")->spew_utf8 (join "\x0A", @$lines);
} # write_set

sub parse_char_list ($) {
  my $chars = {};
  for (split /\x0A/, $_[0]) {
    if (/^[0-9A-F]{2}(?:\s+[0-9A-F]{2}(?:-[0-9A-F]{2}|))+\s*$/) {
      my @c = split /\s+/, $_;
      my $h = hex shift @c;
      for (@c) {
        if (/^([0-9A-F]{2})-([0-9A-F]{2})$/) {
          my $start = hex $1;
          my $end = hex $2;
          for ($start..$end) {
            $chars->{$h * 0x100 + $_} = 1;
          }
        } else {
          $chars->{$h * 0x100 + hex $_} = 1;
        }
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
  return $chars;
} # parse_char_list

my @HasVertical;
my @HasHV;

sub write_sets_1995 ($$$$$$$$;%) {
  my ($no, $key, $name, $h1, $v1, $atable, $ahlist, $avlist, %args) = @_;

  if (defined $h1) {
  my $hchars1 = {map { (ord ($_) => 1) } split //, $h1};
  my $vchars1 = {map { (ord ($_) => 1) } split //, $v1};
  write_set
      "jisx4051-1995/table1-$key-horizontal",
      $hchars1,
      label => "JIS X 4051-1995 表1 ($no) $name 横書き用文字";
  write_set
      "jisx4051-1995/table1-$key-vertical",
      $vchars1,
      label => "JIS X 4051-1995 表1 ($no) $name 縦書き用文字";
  write_set
      "jisx4051-1995/table1-$key",
      {%$hchars1, %$vchars1},
      label => "JIS X 4051-1995 表1 ($no) $name";
  } # $h1
  
  if (defined $atable) {
    my $ahchars = parse_char_list $ahlist;
    my $avchars = parse_char_list ($avlist // '');
    if (defined $avlist) {
      write_set
          "jisx4051-1995/0221-$key-horizontal",
          $ahchars,
          label => "JIS X 4051-1995 附属書表$atable ($no) $name 字形 横書き あり",
          additional => $args{additional};
      write_set
          "jisx4051-1995/0221-$key-vertical",
          $avchars,
          label => "JIS X 4051-1995 附属書表$atable ($no) $name 字形 縦書き あり",
          additional => $args{additional};
      push @HasVertical, "\$jisx4051-1995:0221-$key-vertical";
    }
    write_set
        "jisx4051-1995/0221-$key",
        {%$ahchars, %$avchars},
        label => "JIS X 4051-1995 附属書表$atable ($no) $name",
        additional => $args{additional};
    if (defined $args{compat}) {
      write_set
          "jisx4051-1995/$args{compat}",
          {%$ahchars, %$avchars},
          label => "JIS X 4051-1995 附属書表$atable ($no) $name",
          additional => $args{additional};
    }

    my $asamechars = parse_char_list ($args{same} // '');
    if (keys %$asamechars) {
      write_set
          "jisx4051-1995/0221-$key-hequalv",
          $asamechars,
          label => "JIS X 4051-1995 附属書表$atable ($no) $name 字形 横書き 縦書き がほぼ同じ";
      push @HasHV, "\$jisx4051-1995:0221-$key-hequalv"
    }
  } # $atable

} # write_sets_1995

write_sets_1995
    '1', 'open-brackets',
    '始め括弧類',
    q@‘“(〔[{〈《「『【@,
    q@(〔[[{〈《「『【‘“@,
    '2',
    q{
00 28 5B 7B
20 18 1B 1C 1F
30 08 0A 0C 0E 10 14 16 18 1A 1D
    }, q{
00 28 5B 7B
20 18    1C
30 08 0A 0C 0E 10 14 16 18 1A
    },
    compat => 'open-brackets';

write_sets_1995
    '2', 'close-brackets',
    '終わり括弧類',
    q@、,’”)〕]}〉》」』】@,
    q@、’”)〕]}〉》」』】@,
    '3',
    q{
00 29 2C 5D 7D
20 19 1A 1D 1E
30 01 09 0B 0D 0F 11 15 17 19 1B 1E 1F
    }, q{
00 29    5D 7D
20 19    1D 
30 01 09 0B 0D 0F 11 15 17 19 1B 
    },
    compat => 'close-brackets';

write_sets_1995
    '3', 'line-start-kinsoku',
    '行頭禁則和字',
    q@ヽヾゝゞ々ーぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮヵヶ@,
    q@ヽヾゝゞ々ーぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮヵヶ@,
    '4',
    q{
20 3C 44
30 1C 41 43 45 47 49 63 83 85 87 8E 9D 9E
30 A1 A3 A5 A7 A9 C3 E3 E5 E7 EE F5 F6 FC FD FE
    }, q{
20 3C 44
30 1C 41 43 45 47 49 63 83 85 87 8E 9D 9E
30 A1 A3 A5 A7 A9 C3 E3 E5 E7 EE F5 F6 FC FD FE
    },
    compat => 'kinsoku',
    same => q{
20 3C 44
30 9D 9E
30 FD FE
    };
write_sets_1995
    '3', 'line-start-kinsoku-optional',
    '行頭禁則和字 処理系定義',
    # 長音記号及びよう (拗) 促音を含む仮名の小文字
    q@ーぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮヵヶ@,
    q@ーぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮヵヶ@,
    '4',
    q{
20 44
    }, q{
20 44
    };
# compat: kinsoku-additional-kana.expr
# compat: kinsoku-additional-misc.expr
write_sets_1995
    '3', 'line-start-kinsoku-required',
    '行頭禁則和字 必須',
    q@ヽヾゝゞ々@,
    q@ヽヾゝゞ々@,
    '4',
    q{
20 3C 
30 1C 41 43 45 47 49 63 83 85 87 8E 9D 9E
30 A1 A3 A5 A7 A9 C3 E3 E5 E7 EE F5 F6 FC FD FE
    }, q{
20 3C 
30 1C 41 43 45 47 49 63 83 85 87 8E 9D 9E
30 A1 A3 A5 A7 A9 C3 E3 E5 E7 EE F5 F6 FC FD FE
    },
    compat => 'kinsoku-common';

write_sets_1995
    '4', 'delimiters',
    '区切り約物',
    q@?!@,
    q@?!@,
    '5',
    q{
00 21 3F
    }, q{
00 21 3F
    },
    compat => 'separators',
    same => q{
00 21 3F
    };

write_sets_1995
    '5', 'middle-dots',
    '中点類',
    q@・:;@,
    q@・:@,
    '6',
    q{
00 3A 3B FB
    }, q{
00 3A    FB
    },
    compat => 'middle-dots';

write_sets_1995
    '6', 'full-stops',
    '句点類',
    q@。.@,
    q@。@,
    '7',
    q{
00 2E
30 02
    }, q{
30 02
    },
    compat => 'full-stops';

write_sets_1995
    '7', 'unseparatable',
    '分離禁止文字',
    qq@\x{2014}\x{2026}\x{2025}@,
    qq@\x{2014}\x{2026}\x{2025}@,
    '8',
    q{
20 14 24 25 26
    }, q{
20 14 24 25 26
    },
    # U+2024 H & V are similar glyphs with different dimensions
    compat => 'unseparatable';

write_sets_1995
    '8', 'prefixes',
    '前置省略記号',
    qq@\x{00A5}\x{0024}\x{00A3}@,
    qq@\x{00A5}\x{0024}\x{00A3}@,
    '9',
    q{
00 24 A3 A5
21 16
    }, q{
00 24 A3 A5
21 16
    },
    compat => 'prefixes',
    same => q{
00 24 A3 A5
21 16
    };

write_sets_1995
    '9', 'suffixes',
    '後置省略記号',
    qq@\x{00B0}\x{2032}\x{2033}%‰\x{00A2}@,
    qq@%‰\x{00A2}@,
    '10',
    q{
00 25 A2 B0
20 30 31 32 33
    }, q{
00 25 A2
20 30 31
    },
    compat => 'suffixes',
    same => q{
00 25 A2
20 30 31
    };

write_sets_1995
    '10', 'japanese-space',
    '和字間隔',
    undef, undef,
    '1',
    q{
30 00
    }, undef,
    compat => 'japanese-space';

write_sets_1995
    '11', 'hiragana',
    '平仮名',
    # [あいう]...[ん] (濁音、半濁音も含むか不明)
    (join '', map { keys %$_ } parse_char_list ("30 42 44 46 48 4A-62 64-82 84 86 88-8D 8F-94")),
    (join '', map { keys %$_ } parse_char_list ("30 42 44 46 48 4A-62 64-82 84 86 88-8D 8F-94")),
    '1',
    # 3042-3094 - 行頭禁則和字
    q{
30 42 44 46 48 4A-62 64-82 84 86 88-8D 8F-94
    }, undef,
    compat => 'hiragana';
write_sets_1995
    '11', 'hiragana-all',
    '平仮名 + 処理系定義で行頭禁則和字からはずしたよう (拗) 促音を含む平仮名の小文字',
    (join '', map { keys %$_ } parse_char_list ("30 42 44 46 48 4A-62 64-82 84 86 88-8D 8F-94")) . q{ぁぃぅぇぉっゃゅょゎ},
    (join '', map { keys %$_ } parse_char_list ("30 42 44 46 48 4A-62 64-82 84 86 88-8D 8F-94")) . q{ぁぃぅぇぉっゃゅょゎ},
    undef, undef, undef;

write_sets_1995
    '12', 'japanese-others',
    '(1)～(11)以外の和字',
    undef, undef,
    '1',
    # U+203B(※) とあるが※は U+203B のこと、注釈ではない
    # U+30A2-U+30FA - 行頭禁則和字
    q{
00 2B 2D 3C 3D 3E A7 A9 AE B1 B6 D7 F7
20 3B
21 60-7F 90-EA
24 60-EA
25 00-7F 80-95 A0-EF
26 00-13 1A-6E
27 01-04 06-09 0C-27 29-4B 4D 4F-52 56 58-5E 61-67 76-94 98-AF B1-BE
30 03 04 06 07 12 13 20 36 A2 A4 A6 A8 AA-C2 C4-E2 E4 E6 E8-ED EF-F4 F7-FA
32 20-43 80-B0 D0-FE
33 00-57 71-76 80-DD
    }, undef,
    compat => 'misc-japanese',
    additional => q{[\u{4E00}-\u{9FA5}]};
#compat:misc-japanese-non-kanji.expr
#compat:misc-japanese-kanji.expr

# (13) 添え字付き親文字群中の文字
# empty

# (14) ルビ付き親文字群中の文字
# empty

write_sets_1995
    '15', 'numbers',
    '連数字中の文字',
    # 数字、小数点のピリオド、位取りのコンマ、空白
    "0123456789., ",
    "0123456789., ",
    '1',
    q{
00 30-39 20 2C 2E
    }, undef,
    compat => 'numbers';

write_sets_1995
    '16', 'units',
    '単位記号中の文字',
    # JIS Z 8202 単位記号
    undef, undef,
    '1',
    q{
00 41-5A 61-7A
21 26
    }, undef,
    compat => 'units';

write_sets_1995
    '17', 'western-space',
    '欧文間隔',
    undef, undef,
    '1',
    q{
00 20
    }, undef,
    compat => 'western-space';

write_sets_1995
    '18', 'western-non-space',
    '欧文間隔以外の欧文用文字',
    undef, undef,
    '1',
    q{
00 21-7E
00 A1-FF
01 00-7F
02 50-A8
03 74-75 7A 7E 84-8A 8C 8E-A1 A3-CE
04 01-0C 0E-4F 51-5C 5E-7F 80-86 90-C4 C7-C8 CB-CC D0-EB EE-F5 F8-F9
20 00-2E 30-46 70 74-8E A0-AA
21 00-38 53-82 90-EA
22 00-7F 80-F1
23 12
24 60-EA
25 00-7F 80-95 A0-EF
26 00-13 1A-6F
27 01-04 06-09 0C-27 29-4B 4D 4F-52 56 58-5E 61-67 76-94 98-AF B1-BE
    }, undef,
    compat => 'western-non-space';

write_sets_1995
    '19', 'inline-annotation-open',
    '割注始め括弧類',
    q@(〔[@,
    q@[〔(@,
    #および前側の空き
    '11',
    q{
00 28 5B
30 14
    }, q{
00 28 5B
30 14
    },
    compat => 'inline-annotation-open';

write_sets_1995
    '20', 'inline-annotation-close',
    '割注終わり括弧類',
    q@)〕]@,
    q@]〕)@,
    #および後ろ側の空き
    '12',
    q{
00 29 5D
30 15
    }, q{
00 29 5D
30 15
    },
    compat => 'inline-annotation-close';

## (表1) 各クラス += 処理系定義のこれ以外の文字

write_set
    "jisx4051-1995/vertical-specific-glyphs",
    {},
    label => "JIS X 4051-1995 附属書各表 字形 縦書きに横書きと異なる字形",
    additional => (join " |\x0A", @HasVertical) . " -\x0A" . (join " -\x0A", @HasHV);

## License: Public Domain.
