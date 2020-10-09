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

my $J2U = {};
{
  my $path = $RootPath->child ('local/jis-0213-1.txt');
  for (split /\n/, $path->slurp) {
    if (m{^0x([0-9A-F]{2})([0-9A-F]{2})\tU\+([0-9A-F]+)\t}) {
      $J2U->{1, -0x20 + hex $1, -0x20 + hex $2} = hex $3;
    }
  }
}
{
  my $path = $RootPath->child ('local/jis-0213-2.txt');
  for (split /\n/, $path->slurp) {
    if (m{^0x([0-9A-F]{2})([0-9A-F]{2})\tU\+([0-9A-F]+)\t}) {
      $J2U->{2, -0x20 + hex $1, -0x20 + hex $2} = hex $3;
    }
  }
}

sub parse_jis_char_list ($) {
  my $chars = {};
  for (split /\x0A/, $_[0]) {
    if (/^[0-9]+(?:\s+[0-9]+(?:-[0-9]+|))+\s*$/) {
      my @c = split /\s+/, $_;
      my $h = shift @c;
      for (@c) {
        if (/^([0-9]+)-([0-9]+)$/) {
          my $start = $1;
          my $end = $2;
          for ($start..$end) {
            $chars->{$J2U->{1, $h, $_} // die "1-$h-$_"} = 1;
          }
        } else {
          $chars->{$J2U->{1, $h, $_} // die "1-$h-$_"} = 1;
        }
      }
    } elsif (/^([12])-([0-9]+)--([0-9]+)$/) {
      my $p = $1;
      my $r1 = $2;
      my $r2 = $3;
      for my $r ($r1..$r2) {
        for my $c (1..94) {
          $chars->{$J2U->{$p, $r, $c} // die "$p-$r-$c"} = 1;
        }
      }
    } elsif (/^2-([0-9]+)\s+([0-9]+)-([0-9]+)$/) {
      my $r = $1;
      for my $c ($2..$3) {
        $chars->{$J2U->{2, $r, $c} // die "2-$r-$c"} = 1;
      }
    } elsif (/^0x20$/) {
      $chars->{0+0x0020} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
  return $chars;
} # parse_jis_char_list

my @HasVertical;
my @HasHV;
my @HasVertical2;
my @HasHV2;
my @HasHorizontal2;

sub write_class_sets ($$$$$$$$$$$$;%) {
  my ($no1, $no2, $key,
      $name, $h1, $v1,
      $atable, $ahlist, $avlist,
      $atable2, $ahlist2, $avlist2,
      %args) = @_;

  if (defined $h1) {
    my $hchars1 = {map { (ord ($_) => 1) } split //, $h1};
    my $vchars1 = {map { (ord ($_) => 1) } split //, $v1};
    if (defined $no1) {
      write_set
          "jisx4051-1995/table1-$key-horizontal",
          $hchars1,
          label => "JIS X 4051-1995 表1 ($no1) $name 横書き用文字";
      write_set
          "jisx4051-1995/table1-$key-vertical",
          $vchars1,
          label => "JIS X 4051-1995 表1 ($no1) $name 縦書き用文字";
      write_set
          "jisx4051-1995/table1-$key",
          {%$hchars1, %$vchars1},
          label => "JIS X 4051-1995 表1 ($no1) $name";
    }
    if (defined $no2) {
      my $hchars2 = {map { (ord ($_) => 1) } split //, $args{h2} // ''};
      my $vchars2 = {map { (ord ($_) => 1) } split //, $args{v2} // ''};
      write_set
          "jisx4051-2004/table4-$key-horizontal",
          {%$hchars1, %$hchars2},
          label => "JIS X 4051:2004 表4 ($no2) $name 横書き用文字";
      write_set
          "jisx4051-2004/table4-$key-vertical",
          {%$vchars1, %$vchars2},
          label => "JIS X 4051:2004 表4 ($no2) $name 縦書き用文字";
      write_set
          "jisx4051-2004/table4-$key",
          {%$hchars1, %$vchars1,
           %$hchars2, %$vchars2},
          label => "JIS X 4051:2004 表4 ($no2) $name";
    }
  } # $h1
  
  if (defined $atable) {
    my $ahchars = parse_char_list $ahlist;
    my $avchars = parse_char_list ($avlist // '');
    if (defined $avlist) {
      write_set
          "jisx4051-1995/0221-$key-horizontal",
          $ahchars,
          label => "JIS X 4051-1995 附属書表$atable ($no1) $name 字形 横書き あり",
          additional => $args{additional};
      write_set
          "jisx4051-1995/0221-$key-vertical",
          $avchars,
          label => "JIS X 4051-1995 附属書表$atable ($no1) $name 字形 縦書き あり",
          additional => $args{additional};
      push @HasVertical, "\$jisx4051-1995:0221-$key-vertical";
    }
    write_set
        "jisx4051-1995/0221-$key",
        {%$ahchars, %$avchars},
        label => "JIS X 4051-1995 附属書表$atable ($no1) $name",
        additional => $args{additional};
    if (defined $args{compat}) {
      write_set
          "jisx4051-1995/$args{compat}",
          {%$ahchars, %$avchars},
          label => "JIS X 4051-1995 附属書表$atable ($no1) $name",
          additional => $args{additional};
    }

    my $asamechars = parse_char_list ($args{same} // '');
    if (keys %$asamechars) {
      write_set
          "jisx4051-1995/0221-$key-hequalv",
          $asamechars,
          label => "JIS X 4051-1995 附属書表$atable ($no1) $name 字形 横書き 縦書き がほぼ同じ";
      push @HasHV, "\$jisx4051-1995:0221-$key-hequalv";
    }
  } # $atable
  if (defined $atable2) {
    my $ahchars2 = parse_jis_char_list $ahlist2;
    my $avchars2 = parse_jis_char_list ($avlist2 // '');
    my $suffix = '';
    $suffix .= ' (1文字)' if $args{more};
    $suffix .= ' (空き領域以外)' if $args{unassigned};
    if (defined $avlist2) {
      write_set
          "jisx4051-2004/0213-$key-horizontal",
          $ahchars2,
          label => "JIS X 4051:2004 附属書表$atable2 ($no2) $name 字形 横書き あり".$suffix,
          additional => $args{additional2};
      write_set
          "jisx4051-2004/0213-$key-vertical",
          $avchars2,
          label => "JIS X 4051:2004 附属書表$atable2 ($no2) $name 字形 縦書き あり".$suffix,
          additional => $args{additional2};
      push @HasVertical2, "\$jisx4051-2004:0213-$key-vertical";
      push @HasHorizontal2, "\$jisx4051-2004:0213-$key-horizontal";
    }
    write_set
        "jisx4051-2004/0213-$key",
        {%$ahchars2, %$avchars2},
        label => "JIS X 4051:2004 附属書表$atable2 ($no2) $name".$suffix,
        additional => $args{additional2};

    my $asamechars2 = parse_jis_char_list ($args{same2} // '');
    if (keys %$asamechars2) {
      write_set
          "jisx4051-2004/0213-$key-hequalv",
          $asamechars2,
          label => "JIS X 4051:2004 附属書表$atable2 ($no2) $name 字形 横書き 縦書き がほぼ同じ".$suffix;
      push @HasHV2, "\$jisx4051-2004:0213-$key-hequalv";
    }
  } # $atable2
} # write_class_sets

write_class_sets
    '1', '1', 'open-brackets',
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
    '2', q{
1 42 46 48 44 50 52 54 56 58
2 56 58 
13 64
1 38 40
2 54
9 8
    }, q{
1 42 46 48 44 50 52 54 56 58
2 56 58 
13 64
1 38 
2 54
9 8
    },
    compat => 'open-brackets';

write_class_sets
    '2', '2', 'close-brackets',
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
    '3', q{
1 4 43 47 49 2 45 51 53 55 57 59
2 57 59
13 65
1 39 41
2 55
9 18
    }, q{
1   43 47 49 2 45 51 53 55 57 59
2 57 59
13 65
1 39 
2 55
9 18
    },
    compat => 'close-brackets',
    2004 => 1;

write_class_sets
    '3', '3', 'line-start-kinsoku',
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
    '4', q{
1 19 20 28 
5 1 3 5 7 9 35 67 69 71 78 85 86
1 21 22 
4 1 3 5 7 9 35 67 69 71 78 85 86
6 78 79 80 81 82 83 84 85 86 87 89 90 91 92 93 94
1 25 
    }, q{
1 19 20 28 
5 1 3 5 7 9 35 67 69 71 78 85 86
1 21 22 
4 1 3 5 7 9 35 67 69 71 78 85 86
6 78 79 80 81 82 83 84 85 86 87 89 90 91 92 93 94
1 25 
2 22
    }, # 小書きプなし
    compat => 'kinsoku',
    same => q{
20 3C 44
30 9D 9E
30 FD FE
    }, same2 => q{
1 19 20 
1 21 22
1 25
    };
write_class_sets
    '3', undef, 'line-start-kinsoku-optional',
    '行頭禁則和字 処理系定義',
    # 長音記号及びよう (拗) 促音を含む仮名の小文字
    q@ーぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮヵヶ@,
    q@ーぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮヵヶ@,
    '4',
    q{
20 44
    }, q{
20 44
    },
    undef, undef, undef;
# compat: kinsoku-additional-kana.expr
# compat: kinsoku-additional-misc.expr
write_class_sets
    '3', '3', 'line-start-kinsoku-required',
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
    undef, undef, undef,
    compat => 'kinsoku-common';

write_class_sets
    undef, '4', 'hyphens',
    'ハイフン類',
    q@-@ . "\x{2014}\x{301C}\x{30A0}",
    q@-@ . "\x{2014}\x{301C}\x{30A0}",
    undef,
    undef, undef,
    '5', q{
1    91 92 33
    }, q{
1 30 91 92 33
    };

write_class_sets
    '4', '5', 'delimiters',
    '区切り約物',
    q@?!@,
    q@?!@,
    '5',
    q{
00 21 3F
    }, q{
00 21 3F
    },
    '6', q{
1 9 10 
8 75 76 77 78
    }, q{
1 9 10 
8 75 76 77 78
    },
    compat => 'separators',
    same => q{
00 21 3F
    }, 
    same2 => q{
1 9 10 
8 75 76 77 78
    };

write_class_sets
    '5', '6', 'middle-dots',
    '中点類',
    q@・:;@,
    q@・:@,
    '6',
    q{
00 3A 3B 
30 FB
    }, q{
00 3A    
30 FB
    },
    '7' => q{
1 6 7 8
    }, q{
1 6 7
    },
    compat => 'middle-dots',
    same => undef, # ・は同字形別サイズ
    same2 => q{
1 6
    };

write_class_sets
    '6', '7', 'full-stops',
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
    '8', q{
1 3 5
    }, q{
1 3
    },
    compat => 'full-stops';

write_class_sets
    '7', '8', 'unseparatable',
    '分離禁止文字',
    qq@\x{2014}\x{2026}\x{2025}@,
    qq@\x{2014}\x{2026}\x{2025}@,
    '8',
    q{
20 14 24 25 26
    }, q{
20 14 24 25 26
    },
    '9', q{
1 29 36 37
    }, q{
1 29 36 37
2 19 20 21
    },
    compat => 'unseparatable',
    same => undef, # U+2024 H & V are similar glyphs with different dimensions
    ;

write_class_sets
    '8', '9', 'prefixes',
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
    '10', q{
1 79 82 80 84 
9 1 
13 66
    }, q{
1 79 82 80 84 
9 1 
13 66
    },
    compat => 'prefixes',
    same => q{
00 24 A3 A5
21 16
    },
    h2 => "\x{20AC}",
    v2 => "\x{20AC}",
    same2 => q{
1 79 82 80 84 
9 1 
13 66
    };

write_class_sets
    '9', '10', 'suffixes',
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
    '11', q{
1 75 81 76 77 
2 83
1 78
3 63
1 83
3 62
    }, q{
1    81 
2 83
1 78
3 63
1 83
3 62
    },
    compat => 'suffixes',
    h2 => '℃',
    v2 => '℃',
    same => q{
00 25 A2
20 30 31
    },
    same2 => q{
1    81 
2 83
1 78
3 63
1 83
3 62
    };

write_class_sets
    '10', '11', 'japanese-space',
    '和字間隔',
    undef, undef,
    '1',
    q{
30 00
    }, undef,
    '1',
    q{1 1}, undef,
    compat => 'japanese-space';

write_class_sets
    '11', '12', 'hiragana',
    '平仮名',
    # [あいう]...[ん] (濁音、半濁音も含むか不明)
    (join '', map { map { chr } keys %$_ } parse_char_list ("30 42 44 46 48 4A-62 64-82 84 86 88-8D 8F-94")),
    (join '', map { map { chr } keys %$_ } parse_char_list ("30 42 44 46 48 4A-62 64-82 84 86 88-8D 8F-94")),
    # 3042-3094 - 行頭禁則和字
    '1', q{
30 42 44 46 48 4A-62 64-82 84 86 88-8D 8F-94
    }, undef,
    # 1-4-2 - 1-4-91 - 行頭禁則和字
    '1', q{
4  2 4 6 8 10-34 36-66 68 70 72-77 79-84
    }, undef,
    more => 1, # XXX 1-4-87 - 1-4-89
    compat => 'hiragana';
write_class_sets
    '11', '12', 'hiragana-all',
    '平仮名 + 処理系定義で行頭禁則和字からはずしたよう (拗) 促音を含む平仮名の小文字',
    (join '', map { map { chr } keys %$_ } parse_char_list ("30 42 44 46 48 4A-62 64-82 84 86 88-8D 8F-94")) . q{ぁぃぅぇぉっゃゅょゎ},
    (join '', map { map { chr } keys %$_ } parse_char_list ("30 42 44 46 48 4A-62 64-82 84 86 88-8D 8F-94")) . q{ぁぃぅぇぉっゃゅょゎ},
    undef, undef, undef,
    undef, undef, undef;

write_class_sets
    '12', '13', 'japanese-others',
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
    # 1-5-1 - 1-5-94 - 行頭禁則和字
    '1', q{
1 23 24 26 27 31 32 34 35 60-74 85-94
2 1-14 23-53 60-2 65-81 84-94
3 1-15 26-32 59 93 94
5 1-86
6 25-32 58-77
7  82-94
8 33-62 71-74
9 6 10 19-21 
12 1-83 93-94
13 1-55 63 67-79 83 88 89 93 94
14 2-94
15 1-93
1-16--46
47 1-51 53-93
1-48--83
84 1-6 8-94
1-85--93
94 1-89
2-1--1
2-3--5
2-8--8
2-12--15
2-78--93
2-94 1-86
    }, undef,
    more => 1, # XXX 1-5-87 - 1-5-94 1-6-88
    unassigned => 1, # 1-47-52, 1-47-94, 1-84-7 have no Unicode mapping
    compat => 'misc-japanese',
    additional => q{[\u{4E00}-\u{9FA5}]};
#compat:misc-japanese-non-kanji.expr
#compat:misc-japanese-kanji.expr

# 2004 (14) 合印中の文字

# 1995 (13)
# 2004 (15)
# 添え字付き親文字群中の文字
# empty

# 1995 (14) ルビ付き親文字群中の文字
# empty

# 2004 (16) 熟語ルビ以外のルビ付き親文字群中の文字
# empty

# 2004 (17) 熟語ルビ付き親文字群中の文字
# empty

write_class_sets
    '15', '18', 'numbers',
    '連数字中の文字',
    # 数字、小数点のピリオド、位取りのコンマ、空白
    "0123456789., ",
    "0123456789., ",
    '1',
    q{
00 30-39 20 2C 2E
    }, undef,
    '1', q{
0x20
1 4 5  
3 16-25
    }, undef,
    compat => 'numbers';

write_class_sets
    '16', '19', 'units',
    '単位記号中の文字',
    # 1995: JIS Z 8202 単位記号
    # 2004: JIS Z 8202 単位記号 - °′″℃ + U+212B U+2127
    undef, undef,
    '1', q{
00 41-5A 61-7A
21 26
    }, undef,
    '1', q{
0x20
1 6 31 42 43 61 
2 82 
3 17-20 33-58 64-90
6 24 44
    }, undef,
    # 1-1-31 は半角
    compat => 'units';

write_class_sets
    '17', '20', 'western-space',
    '欧文間隔',
    undef, undef,
    '1',
    q{
00 20
    }, undef,
    '1', q{0x20}, undef,
    compat => 'western-space';

write_class_sets
    '18', '21', 'western-non-space',
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
    '1', q{
1 4 5 7-10 13-18 29 31 32 34-43 46-49 60-77 79-94
2 1-7 10-13 15-18 26-53 60-94
3 1-25 31-61 64-90 92
6 1-67 71-75 77
7 1-33 49-81 86-94
8 33-62 71-74 79-92
9 1-94
10 1-94
11 1-35 37 50-63 71-94
12 1-20 33-58 93-94
13 1-20 83 88 89 93 94
    }, undef,
    more => 1, # XXX 1-11-36 1-11-38 -- 1-11-49 1-11-64 -- 1-11-70
    compat => 'western-non-space';

write_class_sets
    '19', '22', 'inline-annotation-open',
    '割注始め括弧類',
    q@(〔[@,
    q@[〔(@, # 1995; 2004 q@(〔[@,
    #および前側の空き
    '11',
    q{
00 28 5B
30 14
    }, q{
00 28 5B
30 14
    },
    '12', q{
1 42 46 44
    }, q{
1 42 46 44
    },
    compat => 'inline-annotation-open';

write_class_sets
    '20', '23', 'inline-annotation-close',
    '割注終わり括弧類',
    q@)〕]@,
    q@]〕)@, # 1995; 2004 q@)〕]@,
    #および後ろ側の空き
    '12',
    q{
00 29 5D
30 15
    }, q{
00 29 5D
30 15
    },
    '13', q{
1 43 47 45
    }, q{
1 43 47 45
    },
    compat => 'inline-annotation-close';

## 各クラス += 処理系定義のこれ以外の文字

write_set
    "jisx4051-1995/vertical-specific-glyphs",
    {},
    label => "JIS X 4051-1995 附属書各表 字形 縦書きに横書きと異なる字形",
    additional => (join " |\x0A", @HasVertical) . " -\x0A" . (join " -\x0A", @HasHV);
write_set
    "jisx4051-2004/vertical-specific-glyphs",
    {},
    label => "JIS X 4051:2004 附属書各表 字形 縦書きに横書きと異なる字形",
    additional => (join " |\x0A", @HasVertical2) . " -\x0A" . (join " -\x0A", @HasHV2);
write_set
    "jisx4051-2004/vertical-glyphs-only",
    {},
    label => "JIS X 4051:2004 附属書各表 字形 縦書き のみ",
    additional => (join " |\x0A", @HasVertical2) . " -\x0A" . (join " -\x0A", @HasHorizontal2);

## License: Public Domain.
