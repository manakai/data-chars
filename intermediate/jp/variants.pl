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

my $Jouyou = {};
{
  use utf8;
  my $path = $ThisPath->child ('jouyouh22-table.json');
  my $json = json_bytes2perl $path->slurp;
  for my $char (keys %{$json->{jouyou}}) {
    my $in = $json->{jouyou}->{$char};
    $Jouyou->{$char} = $in->{index};
    my $c1 = sprintf ':jouyou-h22-%d', $in->{index};
    $Data->{hans}->{$c1}->{$char}->{'pdf:char'} = 1;
    for my $c3 (@{$in->{old} or []}) {
      my $c2 = sprintf ':jouyou-h22kouki-%d', $in->{index};
      $Data->{hans}->{$c1}->{$c2}->{"jouyou:いわゆる康熙字典体"} = 1;
      $Data->{hans}->{$c2}->{$c3}->{'pdf:char'} = 1;
    }
    if ($in->{old_image}) {
      my $c2 = sprintf ':jouyou-h22kouki-%d', $in->{index};
      $Data->{hans}->{$c1}->{$c2}->{"jouyou:いわゆる康熙字典体"} = 1;
    }
    for (@{$in->{kyoyou} or []}) {
      my $c3 = sprintf ':jouyou-h22kyoyou-%d', $in->{index};
      $Data->{hans}->{$c1}->{$c3}->{"jouyou:許容字体"} = 1;
      my $c4 = $_->{text};
      $Data->{hans}->{$c3}->{$c4}->{'pdf:char'} = 1;
    }
  }
}

{
  use utf8;
  my $path = $ThisPath->child ('jouyouh22-mapping.txt');
  for (split /\x0A/, $path->slurp) {
    my @line = split /\t/, $_, -1;
    my $c1 = sprintf ':jouyou-h22-%d', $line[0];
    if (length $line[1]) {
      my $c3 = ':jis' . $line[1];
      $Data->{hans}->{$c1}->{$c3}->{'jish22:jisx0213'} = 1;
    }
    if (length $line[3]) {
      my $c3 = chr hex $line[3];
      $Data->{hans}->{$c1}->{$c3}->{'jish22:ucs:jisx0213'} = 1;
    }
    if (length $line[2]) {
      my $c3 = ':jis' . $line[2];
      if ($line[5] eq 'other') {
        $Data->{hans}->{$c1}->{$c3}->{'jish22:jisx0208:other'} = 1;
      } elsif ($line[5] eq 'kyoyou') {
        $Data->{hans}->{$c1}->{$c3}->{'jish22:jisx0208:許容字体'} = 1;
      } elsif ($line[5] eq 'itai_douji') {
        $Data->{hans}->{$c1}->{$c3}->{'jish22:jisx0208:異体の関係にある同字'} = 1;
      } elsif (length $line[5]) {
        die $line[5];
      } else {
        $Data->{hans}->{$c1}->{$c3}->{'jish22:jisx0208'} = 1;
      }
      if (length $line[6]) {
        my $c4 = ':jis' . $line[6];
        $Data->{hans}->{$c3}->{$c4}->{'jisx0208:2012:annex12:JIS X 0213常用漢字'} = 1;
      }
      my $c4 = chr hex $line[4];
      $Data->{hans}->{$c1}->{$c4}->{'jish22:ucs:jisx0208'} = 1;
      $Data->{hans}->{$c1}->{$c3}->{'jisx0208:2012:annex12'} = 1;
    } elsif (length $line[4] or length $line[5] or length $line[6]) {
      die $_;
    }
  }
  $Data->{hans}->{':jis1-47-52'}->{':jis1-28-24'}->{'jisx0213:2012:annex12:異体の関係にある同字'} = 1;
  #$Data->{hans}->{':jis1-28-24'}->{':jis1-47-52'}->{'jisx0213:2012:annex12:通用字体'} = 1;
}

my $JouyouS56;
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
  $JouyouS56 = $sets->{jouyou_s56};

  use utf8;
  for (keys %{$sets->{touyou_s24}}) {
    my $c1 = $_;
    my $c2 = ':jistype-touyou-' . $_;
    $Data->{glyphs}->{$c1}->{$c2}->{'manakai:glyph'} = 1;
    my $c4 = sprintf ':touyou-%s', $_;
    $Data->{hans}->{$c2}->{$c4}->{'manakai:implements'} = 1;
    unless ($c1 eq '燈') {
      my $c3 = ':jistype-jouyou-' . $_;
      $Data->{glyphs}->{$c2}->{$c3}->{'manakai:unified'} = 1;
      my $c5 = sprintf ':jouyou-s56-%s', $_;
      $Data->{hans}->{$c4}->{$c5}->{'manakai:newrevision'} = 1;
    }
  }
  for (keys %{$sets->{jouyou_s56}}) {
    my $c1 = $_;
    my $c2 = ':jistype-jouyou-' . $_;
    $Data->{glyphs}->{$c1}->{$c2}->{'manakai:glyph'} = 1;
    my $c4 = sprintf ':jouyou-s56-%s', $_;
    $Data->{hans}->{$c2}->{$c4}->{'manakai:implements'} = 1;
    if ({qw(勺 1 匁 1 脹 1 銑 1 錘 1)}->{$c1}) {
      my $c5 = sprintf ':jinmei-%s', $c1;
      $Data->{hans}->{$c4}->{$c5}->{'manakai:newrevision'} = 1;
    } else {
      my $c5 = sprintf ':jouyou-h22-%s', $Jouyou->{$c1} // die $c1;
      $Data->{hans}->{$c4}->{$c5}->{'manakai:newrevision'} = 1;
    }

    ## <https://www.moj.go.jp/content/000011775.pdf>
    ## <https://warp.ndl.go.jp/info:ndljp/pid/10217941/www.jisc.go.jp/newstopics/2004/jinmeicode.pdf>
    #$Data->{hans}->{$c4}->{$c1}->{'pdf:char'} = 1;
    $Data->{hans}->{$c4}->{$c1}->{'jish16:3.3:ucs'} = 1;
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
      $Data->{hans}->{$c1}->{$c2}->{'jisz8903:annex2'} = 1;
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

{
  use utf8;
  my $path = $ThisPath->child ('hyougai-table.json');
  my $json = json_bytes2perl $path->slurp;
  for my $in (@{$json}) {
    my $c1 = sprintf ':hyougai%d', $in->{no};
    if (defined $in->{kankan}) {
      my $c2 = $c1 . 'k';
      $Data->{hans}->{$c1}->{$c2}->{'hyougai:簡易慣用字体'} = 1;
      $Data->{hans}->{$c2}->{$c1}->{'hyougai:印刷標準字体'} = 1;
    }
    if (defined $in->{kobetsu_designsa}) {
      my $c2 = $c1 . 'd';
      $Data->{hans}->{$c1}->{$c2}->{'hyougai:個別デザイン差字形'} = 1;
    }
    if (defined $in->{kobetsu_designsa1}) {
      my $c2 = $c1 . 'd1';
      $Data->{hans}->{$c1}->{$c2}->{'hyougai:個別デザイン差字形'} = 1;
    }
    if (defined $in->{kobetsu_designsa2}) {
      my $c2 = $c1 . 'd2';
      $Data->{hans}->{$c1}->{$c2}->{'hyougai:個別デザイン差字形'} = 1;
    }
  }
}

{
  use utf8;
  my $path = $ThisPath->child ('hyougai-mapping.txt');
  for (split /\x0A/, $path->slurp) {
    my @line = split /\t/, $_, -1;
    my $c1 = sprintf ':hyougai%s', $line[0];
    if (length $line[1]) {
      my $c2 = ':' . $line[1];
      $Data->{hans}->{$c1}->{$c2}->{'manakai:hasglyph'} = 1;
    }
    my $c3;
    if (length $line[3]) {
      $c3 = ':jis' . $line[3];
      $Data->{hans}->{$c1}->{$c3}->{'jcsh13:'.$line[2].':jisx0213'} = 1;
    }
    if (length $line[4]) {
      my $c4 = chr hex $line[4];
      $Data->{hans}->{$c1}->{$c4}->{'jcsh13:'.$line[2].':ucs'} = 1;
    }
    if (length $line[5]) {
      my $c5 = ':jis' . $line[5];
      $Data->{hans}->{$c1}->{$c5}->{'jcsh13:jisx0212'} = 1;
    }
    if (length $line[6]) {
      my $c6 = ':jis' . $line[6];
      $Data->{hans}->{$c1}->{$c6}->{'jcsh13:'.$line[2].':confusing'} = 1;
    }
    if (length $line[7]) {
      my $c7 = ':jis' . $line[7];
      $Data->{hans}->{$c1}->{$c7}->{'jcsh13:'.$line[2].':confusing'} = 1;
    }
    if (length $line[8]) {
      my $c8 = ':jis' . $line[8];
      $Data->{hans}->{$c8}->{$c1}->{'jisx0213:2004:33:hyougai'} = 1;
      $Data->{hans}->{$c8}->{$c3}->{'jisx0213:2004:33:related'} = 1;
      my $c2 = ':' . $line[1];
      $Data->{hans}->{$c8}->{$c2}->{'jisx0213:2004:glyph'} = 1;
    } elsif ($line[0] =~ /^[0-9]+k?$/ and not $line[1] =~ /^J[AC]/) {
      my $c2 = ':' . $line[1];
      $c3 = ':jis' . $line[3];
      $Data->{hans}->{$c3}->{$c2}->{'jisx0213:2004:glyph'} = 1;
    }
  }
}

{
  use utf8;
  my $path = $ThisPath->child ('jiskouki-mapping.txt');
  for (split /\x0A/, $path->slurp_utf8) {
    my @line = split /\t/, $_, -1;
    my $c2 = sprintf ':jis%s', $line[2];
    if ($JouyouS56->{$line[0]}) {
      my $c1 = sprintf ':jouyou-s56kouki-%s', $line[0];
      $Data->{hans}->{$c2}->{$c1}->{"jisx0213:annex7:2.1 b):常用漢字表:いわゆる康煕字典体"} = 1;
      my $c4 = sprintf ':jouyou-s56-%s', $line[0];
      $Data->{hans}->{$c4}->{$c1}->{"jouyou:いわゆる康熙字典体"} = 1;
    }
    if (length $line[1]) {
      my $c3 = sprintf ':jinmei-%s', $line[1];
      $Data->{hans}->{$c2}->{$c3}->{"jisx0213:annex7:2.1 b):人名用漢字許容字体表"} = 1;
      unless ($JouyouS56->{$line[0]}) {
        my $c5 = sprintf ':jinmei-%s', $line[0];
        $Data->{hans}->{$c2}->{$c5}->{"jisx0213:annex7:2.1 b):jinmei"} = 1;
      }
    }
  }
  $Data->{hans}->{":jis1-94-31"}->{":jouyou-s56kouki-闘"}->{'jisx0213:annex7:2.1 b):常用漢字表:いわゆる康煕字典体'} = 1;
}

{
  use utf8;
  my $path = $ThisPath->child ('jinmeih16-mapping.txt');
  for (split /\x0A/, $path->slurp_utf8) {
    my @line = split /\t/, $_, -1;
    my $c1 = sprintf ':jinmei-%s', $line[0];
    my $c2 = sprintf ':jis%s', $line[2];
    my $c3 = sprintf ':jis%s', $line[3];
    my $c4 = chr hex $line[4];
    $Data->{hans}->{$c1}->{$c2}->{'jish16:3.' .$line[1]. ':jisx0208'} = 1;
    $Data->{hans}->{$c1}->{$c3}->{'jish16:3.' .$line[1]. ':jisx0213'} = 1;
    $Data->{hans}->{$c1}->{$c4}->{'jish16:3.' .$line[1]. ':ucs'} = 1;
  }
}

my $Version2Key = {
      1 => "jisx0208:1978:glyph",
      2 => "jisx0208:1983:glyph",
      3 => "jisx9051:glyph",
      4 => "jisx9052:glyph",
      5 => 'jis:1990:ir:glyph',
      6 => 'jis:1990:glyph',
      7 => 'jisx0213:fdis:glyph',
      8 => 'jisx0213:2000:glyph',
      9 => 'jisx0213:ir:glyph',

      "1978cor1w" => "jisx0208:1978:pr1cor:wrong",
      "1978cor1c" => "jisx0208:1978:pr1cor:correct",
      "1978cor24w" => "jisx0208:1978:pr2-4cor:wrong",
      "1978cor24c" => "jisx0208:1978:pr2-4cor:correct",
      "1978cor24xw" => "jisx0208:1978:pr2-4cor:index:wrong",
      "1978cor24xc" => "jisx0208:1978:pr2-4cor:index:correct",
      "1983r1" => "jisx0208:1983:pr1:glyph",
      "1983r5" => "jisx0208:1983:pr5:glyph",
      "1997a7e1draft" => "jisx0208:1997:annex7:ed1:draft",
      "1997a7e1"   => "jisx0208:1997:annex7:ed1:pr1",
      "1997a7e1r1" => "jisx0208:1997:annex7:ed1:pr1",
      "1997a7e1a1" => "jisx0208:1997:annex7:ed1:pr1:annex1",
      "1997a7e1t1" => "jisx0208:1997:annex7:ed1:pr1:table1",
      "1997a7e1r4corw" => "jisx0208:1997:annex7:ed1:pr4cor:wrong",
      "1997a7e1r4corc" => "jisx0208:1997:annex7:ed1:pr4cor:correct",
      "1997a7e1r7-" => "jisx0208:1997:annex7:ed1:pr7-",
      "1997a7e1r5" => "jisx0208:1997:annex7:ed1:pr5",
      "1997a7e1r2-4" => "jisx0208:1997:annex7:ed1:pr2-4",
      "78" => "jisx0208:1997:78",
      "78w" => "jisx0208:1997:78:wrong",
      "dict78w" => "jisx0208:1997:jisdictaug:78:wrong",
      "78/1" => "jisx0208:1997:78/1",
      "78/2-" => "jisx0208:1997:78/2-",
      "78/4c" => "jisx0208:1997:78/4:correct",
      "78/4-" => "jisx0208:1997:78/4-",
      "-78/4" => "jisx0208:1997:-78/4",
      "-78/4X" => "jisx0208:1997:-78/4X",
      "78/4X-" => "jisx0208:1997:78/4X-",
      "78/5" => "jisx0208:1997:78/5",
      "78-83" => "jisx0208:1997:78-83",
      "83" => "jisx0208:1997:83",
      "fdiscorw" => "jisx0213:fdis:cor:wrong",
      "fdiscorc" => "jisx0213:fdis:cor:correct",
      "2000corw" => "jisx0213:2000:cor:wrong",
      "2000corc" => "jisx0213:2000:cor:correct",
};
{
  my $path = $ThisPath->child ('heisei-fallback.txt');
  for (split /\x0A/, $path->slurp) {
    my @line = split /\t/, $_, -1;
    my $c1 = ':' . $line[0];
    my $c2 = glyph_to_char $line[1];
    my $key = get_vkey $c1;
    my $rel_type = $line[2] ? 'manakai:similarglyph' : 'manakai:equivglyph';
    $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
  }
}
{
  my $path = $ThisPath->child ('jis-heisei.txt');
  for (split /\x0A/, $path->slurp) {
    my @line = split /\t/, $_, -1;
    my $c1 = ':jis' . $line[0];
    my $c2 = glyph_to_char $line[2];
    my $key = get_vkey $c1;
    my $rel_type = $Version2Key->{$line[1]} // die;
    if (not is_heisei_char $c2) {
      if ($line[3] eq "~") {
        $rel_type .= ":similar";
      } else {
        $rel_type .= ":equiv";
      }
    }
    $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;

    my $rel_type_2 = {
      "jisx9051:glyph:equiv" => 'manakai:equivglyph',
      "jisx9051:glyph:similar" => 'manakai:similarglyph',
      "jisx9052:glyph:equiv" => 'manakai:equivglyph',
      "jisx9052:glyph:similar" => 'manakai:similarglyph',
    }->{$rel_type};
    if (defined $rel_type_2) {
      my $c3 = $c1;
      $c3 =~ s/^:jis/:jis-dot16-/ if $rel_type =~ /^jisx9051/;
      $c3 =~ s/^:jis/:jis-dot24-/ if $rel_type =~ /^jisx9052/;
      $Data->{glyphs}->{$c3}->{$c2}->{$rel_type_2} = 1;
    }
  }
}
{
  my $path = $ThisPath->child ('jisucs.txt');
  for (split /\x0A/, $path->slurp_utf8) {
    my @line = split /\t/, $_, -1;
    if ($line[0] eq '#') {
      #
    } elsif ($line[0] =~ /^[12]-/) {
      my $c1 = ':jis' . $line[0];
      my $c2 = join '', map { chr hex $_ } split / /, $line[2];
      my $key = get_vkey $c1;
      my $rel_type = {
        1 => "jisx0212:ucs",
        2 => "jisx0213:2000:ucs",
        "2f" => "jisx0213:2000:fullwidth:ucs",
        "2p" => "jisx0213:2000:ucs:()",
        "2x" => "jisx0213:2000:annex11",
        "2xp" => "jisx0213:2000:annex11:()",
        "2c" => "jisx0213:2000cor:ucs",
        "2cp" => "jisx0213:2000cor:ucs:()",
        3 => "jisx0213:2004:ucs",
        o => "manakai:related",
      }->{$line[1]} // die $line[1];
      if ($rel_type =~ /\(\)$/) {
        my $c2_2 = sprintf ':u-juki-%x', ord $c2;
        $Data->{$key}->{$c1}->{$c2_2}->{$rel_type} = 1;
        $Data->{codes}->{$c2}->{$c2_2}->{'manakai:private'} = 1;
      } else {
        $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
      }
    } elsif ($line[0] eq 'j') {
      my $c1 = sprintf ':jis%s', $line[2];
      $c1 = sprintf ':jis-dot16-%s', $line[2] if $line[1] eq 3;
      $c1 = sprintf ':jis-dot24-%s', $line[2] if $line[1] eq 4;
      my $c2 = sprintf ':jis%s', $line[3];
      my $rel_type = {
        1 => 'jis:1990:forkedjis1978w',
        2 => 'jis:2000:forkedjis1978w',
        3 => 'jis:2000:moved',
        4 => 'jis:2000:moved',
      }->{$line[1]};
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif ($line[0] =~ /^g(.+)$/) {
      my $c1 = ':jis' . $1;
      for my $i (1..9) {
        for (split /,/, $line[$i]) {
          my @v = split / /, $_;
          my $t = shift @v;
          my $c1 = $c1;
          $c1 = sprintf ':jis-dot16-%s', $1 if $i == 3;
          $c1 = sprintf ':jis-dot24-%s', $1 if $i == 4;
          my $rel_type = {
            e => 'manakai:equivglyph',
            u => 'manakai:unified',
            f => 'manakai:equivalent',
          }->{$t} // die $t;
          $rel_type .= ":" . ($Version2Key->{$i} // die "Bad version |$i|");
          my $c2 = join '', map { chr hex $_ } @v;
          my $key = get_vkey $c2;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
        }
      }
    } elsif ($line[0] =~ m{^-?\w[\w/-]*$}) {
      my $c1 = $line[0] eq 's' ? ':jistype-simplified-' . $line[1] : ':jis' . $line[1];
      my $c2 = join '', map { chr hex $_ } split / /, $line[3];
      my $key = get_vkey $c2;
      my $rel_type = {
        e => ($line[0] eq 's' ? 'manakai:unified' : 'manakai:equivglyph'),
        u => 'manakai:unified',
        f => 'manakai:equivalent',
      }->{$line[2]} // die $line[2];
      $rel_type .= ":" . ($Version2Key->{$line[0]} // die "Bad version |$line[0]|")
          unless $line[0] eq 's';
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } else {
      die "Bad line |$_|";
    }
  }
}
{
  my $path = $ThisPath->child ('jismoved.txt');
  for (split /\x0A/, $path->slurp) {
    my @line = split /\t/, $_, -1;
    my $c1 = $line[0] =~ /^:/ ? $line[0] : $line[0] =~ / / ? join '', map { chr hex $_ } split / /, $line[0] : ':jis' . $line[0];
    my $c2 = $line[2] =~ /^:/ ? $line[2] : $line[2] =~ / / ? join '', map { chr hex $_ } split / /, $line[2] : ':jis' . $line[2];
    my $key = get_vkey $c1;
    my $rel_type = {
      f2 => "jis:1990:forkedjis1978",
      f3 => "jis:2000:forkedjis1978",
      f4 => "jis:2004:forkedjis1978",
      m1 => "jis:1983:moved",
      mc1 => "jis:1983:movechanged",
      m3 => "jis:2000:moved",
      mc3 => "jis:2000:movechanged",
      mc3x => "jis:2000:variantadded",
      m4 => "jis:2004:moved",
      mc4 => "jis:2004:movechanged",
      e3 => "jis:2000:merged",
      m5 => "mj:moved",
      r5 => 'mj:shared:equiv',
      c5 => 'mj:shared:similar',
    }->{$line[1]} // die $line[1];
    $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
  }
}

{
  use utf8;
  my $path = $ThisPath->child ('gsi-r060301.txt');
  my $rel_type;
  for (split /\x0A/, $path->slurp_utf8) {
    if (/^\*\s*(\S.+\S)\s*$/) {
      $rel_type = 'gsi:地名情報で取り扱う漢字:' . $1;
    } elsif (/^U\+([0-9A-F]+)\s+U\+([0-9A-F]+)$/) {
      my $c1 = u_chr hex $1;
      my $c2 = u_chr hex $2;
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^U\+([0-9A-F]+) ([0-9A-F]+)\s+U\+([0-9A-F]+) ([0-9A-F]+)$/) {
      my $c1 = (u_chr hex $1) . (u_chr hex $2);
      my $c2 = (u_chr hex $3) . (u_chr hex $4);
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(\p{Hiragana}+)\s*$/) {
      my $c1 = u_chr hex $1;
      my $c2 = $2;
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/\S/) {
      die "Bad line: |$_|";
    }
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'variants',
    [
      qr/^:jis1/,
      qr/^:jis2/,
      qr/^:jis-/,
      qr/^:jis/,
      qr/^:u/,
      qr/^[\x{3000}-\x{6FFF}]/,
      qr/^:J/,
      qr/^:I/,
      qr/^:KS[012]/,
      qr/^:K/,
      qr/^:T/,
      qr/^:[a-z]/,
      qr/^:[A-Z]/,
    ];

## License: Public Domain.
