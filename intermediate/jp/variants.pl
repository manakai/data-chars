use strict;
use warnings;
use Path::Tiny;
use Web::Encoding;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/ijp');

my $Data = {};

{
  my $path = $ThisPath->child ('doukun-s47.txt');
  my @s = ();
  my $emit = sub {
    return unless @s;

    #warn "<@s>\n";
    use utf8;
    for my $c1 (@s) {
      for my $c2 (@s) {
        next if $c1 eq $c2;
        $Data->{hans}->{$c1}->{$c2}->{'jp:「異字同訓」の漢字の用法'} = 1;
      }
    }
  }; # $emit

  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    use utf8;
    if (/^\s*#/) {
      #
    } elsif (/^\p{sc=Hiragana}+(?:・\p{sc=Hiragana}+)*$/) {
      $emit->();
      @s = ();
    } elsif (/^([\w・]+)－/) {
      for (split /・/, $1) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
    } elsif (/^(?:[\w（）]+。)*$/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  } # lines
  $emit->();
}

{
  my $path = $ThisPath->child ('doukun-h22.txt');
  my @s = ();
  my $emit = sub {
    return unless @s;

    #warn "<@s>\n";
    use utf8;
    for my $c1 (@s) {
      for my $c2 (@s) {
        next if $c1 eq $c2;
        $Data->{hans}->{$c1}->{$c2}->{'jp:「異字同訓」の漢字の用法例'} = 1;
      }
    }
  }; # $emit

  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    use utf8;
    if (/^\s*#/) {
      #
    } elsif (/^\p{sc=Hiragana}+(?:・\p{sc=Hiragana}+)*$/) {
      $emit->();
      @s = ();
    } elsif (/^([\w・]+)\s*\Q......\E/) {
      for (split /・/, $1) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
    } elsif (/^(?:[\w（）]+。)*$/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  } # lines
  $emit->();
}

{
  my $path = $ThisPath->child ('doukun-h26.txt');
  my @s = ();
  my $emit = sub {
    return unless @s;

    #warn "<@s>\n";
    use utf8;
    for my $c1 (@s) {
      for my $c2 (@s) {
        next if $c1 eq $c2;
        $Data->{hans}->{$c1}->{$c2}->{'jp:「異字同訓」の漢字の使い分け例'} = 1;
      }
    }
  }; # $emit

  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    use utf8;
    if (/^\s*#/) {
      #
    } elsif (/^[０-９]+\s*\p{sc=Hiragana}+(?:・\p{sc=Hiragana}+)*（(\w(?:・\w)+)）$/) {
      for (split /・/, $1) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
      $emit->();
      @s = ();
    } elsif (/^[０-９]+\s*\p{sc=Hiragana}+(?:・\p{sc=Hiragana}+)*（(\w(?:・\w)+)）\s*[０-９]+\s*\p{sc=Hiragana}+(?:・\p{sc=Hiragana}+)*（(\w(?:・\w)+)）$/) {
      my $v2 = $2;
      for (split /・/, $1) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
      $emit->();
      
      @s = ();
      for (split /・/, $v2) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
      $emit->();
      @s = ();
    } elsif (/\S/) {
      die $_;
    }
  } # lines
  $emit->();
}

{
  my $path = $TempPath->child ('nyukanseiji.json');
  my $json = json_bytes2perl $path->slurp;
  use utf8;
  for (@{$json->{table4_1}}) {
    my $c1 = chr hex $_->[0];
    my $c2 = chr hex $_->[1];
    my $c1_0 = $c1;
    if (is_private $c1) {
      $c1 = sprintf ':u-immi-%x', ord $c1;
      $Data->{hans}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
    }
    $Data->{hans}->{$c1}->{$c2}->{"jp:法務省告示582号別表第四:一:第1順位"} = 1;
    if (defined $_->[2]) {
      my $c2 = chr hex $_->[2];
      $Data->{hans}->{$c1}->{$c2}->{"jp:法務省告示582号別表第四:一:第2順位"} = 1;
    }
  }
  for (@{$json->{table4_2}}) {
    my $c1 = chr hex $_->[0];
    my $c2 = chr hex $_->[1];
    my $c1_0 = $c1;
    if (is_private $c1) {
      $c1 = sprintf ':u-immi-%x', ord $c1;
      $Data->{hans}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
    }
    $Data->{hans}->{$c1}->{$c2}->{"jp:法務省告示582号別表第四:二:第1順位"} = 1;
    if (defined $_->[2]) {
      my $c2 = chr hex $_->[2];
      $Data->{hans}->{$c1}->{$c2}->{"jp:法務省告示582号別表第四:二:第2順位"} = 1;
    }
  }
}

{
  use utf8;
  my $path = $ThisPath->child ('jissyukutaimap1_0_0.xslx.tsv');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    my @line = split /\t/, $_, -1;
    if (length $line[1]) {
      if ($line[0] eq $line[4]) {
        #
      } elsif (length $line[4] and not $line[1] eq 'Unicode') {
        die "|$_| ($line[1])" unless $line[1] =~ /^u\+[0-9a-f]{4,5}$/;
        die "|$_| ($line[5])" unless $line[5] =~ /^u\+[0-9a-f]{4,5}$/;
        $line[1] =~ s/^u\+//;
        $line[5] =~ s/^u\+//;
        my $c1 = chr hex $line[1];
        my $c2 = chr hex $line[5];
        my $vkey = get_vkey $c1;
        $Data->{$vkey}->{$c1}->{$c2}->{'nta:JIS縮退マップ:コード変換'} = 1;

        $line[0] =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/ or die;
        my $c3 = sprintf ':jis%d-%d-%d', $1, $2, $3;
        $line[4] =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/ or die;
        my $c4 = sprintf ':jis%d-%d-%d', $1, $2, $3;
        $Data->{$vkey}->{$c3}->{$c4}->{'nta:JIS縮退マップ:コード変換'} = 1;
      }
      if (length $line[7] and not $line[1] eq 'Unicode') {
        $line[1] =~ s/^u\+//;
        my $c1 = chr hex $line[1];
        my $c2 = join '', map { my $x = $_; die $x unless $x =~ /^u\+[0-9a-f]{4,5}$/; $x =~ s/^u\+//; chr hex $x } grep { length } $line[11], $line[12], $line[13], $line[14];
        my $vkey = get_vkey $c1;
        $Data->{$vkey}->{$c1}->{$c2}->{'nta:JIS縮退マップ:文字列変換'} = 1;

        $line[0] =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/ or die;
        my $c3 = sprintf ':jis%d-%d-%d', $1, $2, $3;
        my $c4 = join '', map { my $x = $_; $x =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/ or die; sprintf ':jis%d-%d-%d', $1, $2, $3 } grep { length } $line[7], $line[8], $line[9], $line[10];
        $Data->{$vkey}->{$c3}->{$c4}->{'nta:JIS縮退マップ:文字列変換'} = 1;
      }

      if ($line[1] eq 'Unicode') {
        #
      } elsif ($line[16] =~ /^類似字形u\+([0-9a-f]+)は本文字に変換する。$/) {
        my $c1 = chr hex $1;
        $line[1] =~ s/^u\+//;
        my $c2 = chr hex $line[1];
        my $vkey = get_vkey $c2;
        $Data->{$vkey}->{$c1}->{$c2}->{'nta:JIS縮退マップ:類似字形'} = 1;
      } elsif ($line[16] eq '合成文字（本システムでは取り扱わない）') {
        #
      } elsif ($line[16] eq '半角文字（※特に変換しない）') {
        #
      } elsif (length $line[16]) {
        die $line[16];
      }
    } # $line[1]
  }
}

{
  use utf8;
  for (
    ['jisx0208-1997:附属書1:表1', qw(
16-19 82-45
18-09 82-84
19-34 73-58
19-41 57-88
19-86 67-62
20-35 62-85
20-50 75-61
23-59 80-84
25-60 66-72
28-41 73-02
31-57 80-55
33-08 76-45
36-59 52-68
37-55 66-74
37-78 59-77
37-83 62-25
38-86 77-78
39-72 74-04
41-16 59-56
43-89 48-54
44-89 73-14
47-22 68-38
    )],
    ['jisx0208-1997:附属書1:表2', qw(
22-38 84-01
43-74 84-02
45-58 84-03
64-86 84-04
84-06 63-70
    )],
    ['jisx0208-1997:附属書2:表1', qw(
16-19 82-45
18-09 82-84
19-34 73-58
19-41 57-88
19-86 67-62
20-35 62-85
20-50 75-61
23-59 80-84
25-60 66-72
28-41 73-02
31-57 80-55
33-08 76-45
36-59 52-68
37-55 66-74
37-78 59-77
37-83 62-25
38-86 77-78
39-72 74-04
41-16 59-56
43-89 48-54
44-89 73-14
47-22 68-38
22-38 84-01
43-74 84-02
45-58 84-03
64-86 84-04
    )],
    ['jisx0208-1997:附属書2:表2', qw(
84-06 63-70
    )],
    ['jisx0208-1997:附属書7:83入替え:入替え', qw(
16-19 82-45
18-09 82-84
19-34 73-58
19-41 57-88
19-86 67-62
20-35 62-85
20-50 75-61
23-59 80-84
25-60 66-72
28-41 73-02
31-57 80-55
33-08 76-45
36-59 52-68
37-55 66-74
37-78 59-77
37-83 62-25
38-86 77-78
39-72 74-04
41-16 59-56
43-89 48-54
44-89 73-14
47-22 68-38
    )],
    ['jisx0208-1997:附属書7:83入替え:追加入替え', qw(
22-38 84-01
43-74 84-02
45-58 84-03
64-86 84-04
    )],
    ['jisx0213:附属書7:2.1 a)', qw(
1-16-2 1-15-8
1-17-75 1-87-49
1-18-10 1-94-69
1-19-90 1-15-26
1-22-2 1-14-26
1-22-77 1-92-42
1-24-20 1-94-74
1-25-77 1-94-79
1-28-40 1-47-64
1-29-11 1-90-22
1-30-53 1-91-22
1-30-63 1-92-89
1-32-70 1-91-66
1-33-63 1-84-86
1-34-45 1-94-20
1-35-29 1-89-73
1-36-47 1-84-89
1-37-22 1-15-56
1-37-31 1-94-3
1-37-88 1-89-35
1-38-34 1-87-29
1-39-25 1-15-32
1-40-14 1-87-9
1-40-16 1-92-90
1-43-43 1-93-90
1-44-45 1-94-80
1-45-73 1-91-6
1-47-25 1-91-71
1-58-25 1-85-6
    )],
    ['jisx0213:附属書7:2.1 b)', qw(
1-41-78 1-14-24
1-42-27 1-14-28
1-33-46 1-14-41
1-44-40 1-14-48
1-42-57 1-14-67
1-22-48 1-14-72
1-40-60 1-14-78
1-34-8 1-14-81
1-19-69 1-15-12
1-35-18 1-15-15
1-20-79 1-15-22
1-36-45 1-15-55
1-42-29 1-15-58
1-33-93 1-15-61
1-43-47 1-15-62
1-20-18 1-47-58
1-33-56 1-47-65
1-33-67 1-84-8
1-47-13 1-84-14
1-36-7 1-84-36
1-38-33 1-84-37
1-18-89 1-84-48
1-19-20 1-84-60
1-33-94 1-84-62
1-36-8 1-84-65
1-44-65 1-84-67
1-23-39 1-84-83
1-23-66 1-85-2
1-41-50 1-85-8
1-20-91 1-85-11
1-40-53 1-85-28
1-29-75 1-85-35
1-46-81 1-85-39
1-47-15 1-85-46
1-39-63 1-85-69
1-19-21 1-86-4
1-18-3 1-86-16
1-45-83 1-86-27
1-42-66 1-86-35
1-46-82 1-86-37
1-27-6 1-86-41
1-43-72 1-86-42
1-19-4 1-86-73
1-30-36 1-86-76
1-46-62 1-86-83
1-29-77 1-86-87
1-19-73 1-86-88
1-18-25 1-86-92
1-20-33 1-87-5
1-32-5 1-87-30
1-28-49 1-87-53
1-30-85 1-87-74
1-35-86 1-87-79
1-34-86 1-88-5
1-41-51 1-88-39
1-24-6 1-89-3
1-40-74 1-89-7
1-28-50 1-89-19
1-27-67 1-89-20
1-21-7 1-89-23
1-45-20 1-89-24
1-33-36 1-89-25
1-29-43 1-89-27
1-31-32 1-89-28
1-30-45 1-89-29
1-18-50 1-89-31
1-36-87 1-89-32
1-42-1 1-89-33
1-25-82 1-89-45
1-38-45 1-89-49
1-32-65 1-89-68
1-46-48 1-90-8
1-29-79 1-90-12
1-17-79 1-90-13
1-46-93 1-90-14
1-40-43 1-90-19
1-29-80 1-90-26
1-28-52 1-90-36
1-29-13 1-90-56
1-35-88 1-91-7
1-23-16 1-91-32
1-21-85 1-91-46
1-46-26 1-91-47
1-19-76 1-91-79
1-27-75 1-91-89
1-29-84 1-92-14
1-17-58 1-92-15
1-22-64 1-92-16
1-41-48 1-92-24
1-45-74 1-92-26
1-34-3 1-92-29
1-16-79 1-92-57
1-47-26 1-92-71
1-37-52 1-92-74
1-22-31 1-92-76
1-47-31 1-93-21
1-47-3 1-93-27
1-46-20 1-93-61
1-38-81 1-93-67
1-22-33 1-93-86
1-41-49 1-93-91
1-46-64 1-94-4
1-18-11 1-94-81
1-25-85 1-94-82
    )],
    ['jisx0213:附属書7:2.1 d)', qw(
1-22-70 1-14-1
1-39-77 1-15-94
1-28-24 1-47-52
1-38-61 1-47-94
1-17-19 1-84-7
1-53-11 1-94-90
1-54-2 1-94-91
1-54-85 1-94-92
1-33-73 1-94-93
1-23-50 1-94-94
    )],
    ['jisx0213:附属書7:2.2', qw(
1-88-87 1-80-19
2-86-79 1-73-28
    )],
  ) {
    my $rel_type = shift @$_;
    while (@$_) {
      my $v = shift @$_;
      my $c1;
      if ($v =~ /^([0-9]+)-([0-9]+)$/) {
        $c1 = sprintf ':jis1-%d-%d', $1, $2;
      } elsif ($v =~ /^([12])-([0-9]+)-([0-9]+)$/) {
        $c1 = sprintf ':jis%d-%d-%d', $1, $2, $3;
      } else {
        die $v;
      }
      my $w = shift @$_;
      my $c2;
      if ($w =~ /^([0-9]+)-([0-9]+)$/) {
        $c2 = sprintf ':jis1-%d-%d', $1, $2;
      } elsif ($w =~ /^([12])-([0-9]+)-([0-9]+)$/) {
        $c2 = sprintf ':jis%d-%d-%d', $1, $2, $3;
      } else {
        die $w;
      }
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    }
  }
}

{
  my $path = $RootPath->child ('local/jis-0208.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^0x742[56]/) {
      #
    } elsif (/^0x([0-9A-F]{2})([0-9A-F]{2})\s/) {
      my $c1 = sprintf ':jis1-%d-%d', (hex $1) - 0x20, (hex $2) - 0x20;
      my $c2 = $c1;
      $c2 =~ s/^:jis1-/:jis-dot16-1-/;
      my $c3 = $c1;
      $c3 =~ s/^:jis1-/:jis-dot24-1-/;
      $Data->{glyphs}->{$c2}->{$c1}->{'manakai:implements'} = 1;
      $Data->{glyphs}->{$c3}->{$c1}->{'manakai:implements'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $HasV = q{
1  2 3 17 18 28 29 30 33 34 35 36 37
1  42 43 44 45 46 47 48 49 50 51 52 53
1  54 55 56 57 58 59 65
4  1 3 5 7 9 35 67 69 71 78
5  1 3 5 7 9 35 67 69 71 78 85 86
  };
  my $chars = {};
  for (split /\n/, $HasV) {
    my @c = split /\s+/, $_;
    my $r = shift @c;
    for my $c (@c) {
      my $c1 = sprintf ':jis1-%d-%d', $r, $c;
      my $c2 = $c1;
      $c2 =~ s/^:jis1-/:jis-dot16v-1-/;
      my $c3 = $c1;
      $c3 =~ s/^:jis1-/:jis-dot24v-1-/;
      $Data->{glyphs}->{$c2}->{$c1}->{'manakai:implements:vertical'} = 1;
      $Data->{glyphs}->{$c3}->{$c1}->{'manakai:implements:vertical'} = 1;
      my $c4 = $c2;
      $c4 =~ s/v-/-/g;
      my $c5 = $c3;
      $c5 =~ s/v-/-/g;
      $Data->{glyphs}->{$c4}->{$c2}->{'opentype:vert'} = 1;
      $Data->{glyphs}->{$c5}->{$c3}->{'opentype:vert'} = 1;
    }
  }
}

{
  my $path = $TempPath->child ('nihuINT.tsv');
  my @line = split /\x0D?\x0A/, $path->slurp_utf8;
  shift @line;
  for (@line) {
    my @item = split /\t/, $_;
    my @c;
    while (@item) {
      push @c, chr hex shift @item;
      shift @item;
    }
    my $c1 = shift @c;
    while (@c) {
      my $c2 = shift @c;
      $Data->{hans}->{$c1}->{$c2}->{'nihuINT:variant'} = 1
          unless $c1 eq $c2;
    }
  }
}

{
  my $sets = {};
  my $path = $RootPath->child ('data/sets.json');
  my $json = json_bytes2perl $path->slurp;
  for (
    ['$kanji:touyou-1949' => 'touyou_s24'],
    ['$kanji:jouyou-1981' => 'jouyou_s56'],
  ) {
    my ($key1, $key2) = @$_;
    my $chars = $json->{sets}->{$key1}->{chars};
    $chars =~ s/^\[//;
    $chars =~ s/\]$//;
    while ($chars =~ s/^\\u([0-9A-F]{4}|\{[0-9A-F]+\})//) {
      my $v1 = $1;
      $v1 =~ s/^\{//;
      $v1 =~ s/\}$//;
      my $cc1 = hex $v1;
      my $cc2 = $cc1;
      if ($chars =~ s/^-\\u([0-9A-F]{4}|\{[0-9A-F]+\})//) {
        my $v2 = $1;
        $v2 =~ s/^\{//;
        $v2 =~ s/\}$//;
        $cc2 = hex $v2;
      }
      for ($cc1..$cc2) {
        $sets->{$key2}->{chr $_} = 1;
      }
    }
    die $chars if length $chars;
  }

  use utf8;
  for (keys %{$sets->{touyou_s24}}) {
    my $c1 = $_;
    my $c2 = ':jistype-touyou-' . $_;
    $Data->{glyphs}->{$c1}->{$c2}->{'manakai:glyph'} = 1;
    unless ($c1 eq '燈') {
      my $c3 = ':jistype-jouyou-' . $_;
      $Data->{glyphs}->{$c2}->{$c3}->{'manakai:unified'} = 1;
    }
  }
  for (keys %{$sets->{jouyou_s56}}) {
    my $c1 = $_;
    my $c2 = ':jistype-jouyou-' . $_;
    $Data->{glyphs}->{$c1}->{$c2}->{'manakai:glyph'} = 1;
  }
  {
    for (qw(
      雲 駅 監 艦 鑑 器 機
      騎 緊 駆 繰 堅 賢 験
      酵 酷 酢 酸 事 質 酌
      酒 需 儒 酬 醜 襲 遵
      醸 嘱 職 震 酔 雪 選
      操 燥 霜 騒 藻 属 尊
      駄 第 駐 電 曇 配 雰
      簿 霧 猶 雷 酪 覧 濫
      臨 零 霊 露
    )) {
      my $c0 = $_;
      my $c1 = ':jistype-jouyou-' . $_;
      my $c2 = ':jistype-simplified-' . $_;
      $Data->{glyphs}->{$c0}->{$c2}->{'manakai:glyph'} = 1;
      $Data->{glyphs}->{$c1}->{$c2}->{'jisz8903:annex2'} = 1;
    }
  }
  {
    for (split //, q(あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむっめもやゆよらりるれろわをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽゃゅょっ)) {
      my $c1 = $_;
      my $c2 = ':jistype-' . $_;
      $Data->{glyphs}->{$c1}->{$c2}->{'manakai:glyph'} = 1;
    }
    for (split //, q(アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲンガギグゲゴザジズゼゾダデドバビブベボパピプペポァィゥェォャュョヮッー)) {
      my $c1 = $_;
      my $c2 = ':jistype-' . $_;
      $Data->{glyphs}->{$c1}->{$c2}->{'manakai:glyph'} = 1;
    }
    for (split //, q(1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz)) {
      my $c1 = $_;
      my $c2 = ':jistype-' . $_;
      $Data->{glyphs}->{$c1}->{$c2}->{'manakai:glyph'} = 1;
    }
  }
}


write_rel_data_sets
    $Data => $ThisPath, 'variants',
    [
      qr/^:jis/,
      qr/^:u/,
      qr/^[\x{3000}-\x{6FFF}]/,
    ];

## License: Public Domain.
