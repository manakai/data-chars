use strict;
use warnings;
use Path::Tiny;

my $RootPath = path (__FILE__)->parent->parent;
my $DestPath = $RootPath->child ('src/set');

sub write_set ($$%) {
  my ($name, $hashref, %args) = @_;

  my $lines = [];
  push @$lines, '#label:' . $args{label} if  defined $args{label};
  push @$lines, '#sw:' . $args{sw} if  defined $args{sw};
  push @$lines, '#url:' . $args{url} if  defined $args{url};
  push @$lines, '[';

  for (sort { $a <=> $b } keys %$hashref) {
    push @$lines, sprintf '\u{%04X}', $_;
  }
  
  push @$lines, ']';

  $DestPath->child ("$name.expr")->spew_utf8 (join "\x0A", @$lines);
} # write_set

my $JISChars = {};
my $J2U = {};
{
  my $path = $RootPath->child ('local/jis-0208.txt');
  for (split /\n/, $path->slurp) {
    if (m{^0x([0-9A-F]{2})([0-9A-F]{2})\tU\+([0-9A-F]+)\t}) {
      $JISChars->{hex $3} = 1;
      $J2U->{-0x20 + hex $1, -0x20 + hex $2} = hex $3;
    }
  }
}

my $EncodingsChars = {};
{
  my $path = $RootPath->child ('local/encoding-0208.txt');
  for (split /\n/, $path->slurp) {
    if (m{^\s*([0-9]+)\s+0x([0-9A-F]+)\s}) {
      next if $1 >= 8272;
      next if 1128 <= $1 and $1 <= 1219;
      $EncodingsChars->{hex $2} = 1;
    }
  }
}

my $JISOnly = {};
for (keys %$JISChars) {
  unless ($EncodingsChars->{$_}) {
    $JISOnly->{$_} = 1;
  }
}
$JISOnly->{0+0x005C} = 1;
$JISOnly->{0+0x25EF} = 1;
write_set
    'jisx0208/map-jis-only',
    $JISOnly,
    sw => 'JIS X 0208',
    label => 'JIS X 0208 characters not in JIS X 0208 area of encodings (except for fullwidth variants)';

my $EncodingsOnly = {};
for (keys %$EncodingsChars) {
  unless ($JISChars->{$_}) {
    $EncodingsOnly->{$_} = 1;
  }
}
$EncodingsOnly->{0+0xFF3C} = 1;
$EncodingsOnly->{0+0x20DD} = 1;
write_set
    'jisx0208/map-nonjis-only',
    $EncodingsOnly,
    sw => 'JIS X 0208',
    label => 'Alternative characters assigned in JIS X 0208 area of encodings (except for fullwidth variants)';

{
  my $HasVerticals = q{
0x2122U+3001# IDEOGRAPHIC COMMA
0x2123U+3002# IDEOGRAPHIC FULL STOP
0x2127U+FF1A# FULLWIDTH COLON
0x213DU+2014# EM DASH
0x2141U+301C# WAVE DASH
0x2144U+2026# HORIZONTAL ELLIPSIS
0x2145U+2025# TWO DOT LEADER
0x213CU+30FC# KATAKANA-HIRAGANA PROLONGED SOUND MARK
0x2146U+2018# LEFT SINGLE QUOTATION MARK
0x2147U+2019# RIGHT SINGLE QUOTATION MARK
0x2148U+201C# LEFT DOUBLE QUOTATION MARK
0x2149U+201D# RIGHT DOUBLE QUOTATION MARK
0x214AU+FF08# FULLWIDTH LEFT PARENTHESIS
0x214BU+FF09# FULLWIDTH RIGHT PARENTHESIS
0x214CU+3014# LEFT TORTOISE SHELL BRACKET
0x214DU+3015# RIGHT TORTOISE SHELL BRACKET
0x214EU+FF3B# FULLWIDTH LEFT SQUARE BRACKET
0x214FU+FF3D# FULLWIDTH RIGHT SQUARE BRACKET
0x2150U+FF5B# FULLWIDTH LEFT CURLY BRACKET
0x2151U+FF5D# FULLWIDTH RIGHT CURLY BRACKET
0x2152U+3008# LEFT ANGLE BRACKET
0x2153U+3009# RIGHT ANGLE BRACKET
0x2154U+300A# LEFT DOUBLE ANGLE BRACKET
0x2155U+300B# RIGHT DOUBLE ANGLE BRACKET
0x2156U+300C# LEFT CORNER BRACKET
0x2157U+300D# RIGHT CORNER BRACKET
0x2158U+300E# LEFT WHITE CORNER BRACKET
0x2159U+300F# RIGHT WHITE CORNER BRACKET
0x215AU+3010# LEFT BLACK LENTICULAR BRACKET
0x215BU+3011# RIGHT BLACK LENTICULAR BRACKET
0x2161U+FF1D# FULLWIDTH EQUALS SIGN
0x2421U+3041# HIRAGANA LETTER SMALL A
0x2423U+3043# HIRAGANA LETTER SMALL I
0x2425U+3045# HIRAGANA LETTER SMALL U
0x2427U+3047# HIRAGANA LETTER SMALL E
0x2429U+3049# HIRAGANA LETTER SMALL O
0x2443U+3063# HIRAGANA LETTER SMALL TU
0x2463U+3083# HIRAGANA LETTER SMALL YA
0x2465U+3085# HIRAGANA LETTER SMALL YU
0x2467U+3087# HIRAGANA LETTER SMALL YO
0x246EU+308E# HIRAGANA LETTER SMALL WA
0x2521U+30A1# KATAKANA LETTER SMALL A
0x2523U+30A3# KATAKANA LETTER SMALL I
0x2525U+30A5# KATAKANA LETTER SMALL U
0x2527U+30A7# KATAKANA LETTER SMALL E
0x2529U+30A9# KATAKANA LETTER SMALL O
0x2543U+30C3# KATAKANA LETTER SMALL TU
0x2563U+30E3# KATAKANA LETTER SMALL YA
0x2565U+30E5# KATAKANA LETTER SMALL YU
0x2567U+30E7# KATAKANA LETTER SMALL YO
0x256EU+30EE# KATAKANA LETTER SMALL WA
0x2575U+30F5# KATAKANA LETTER SMALL KA
0x2576U+30F6# KATAKANA LETTER SMALL KE
  };
  my $HasVerticalChars = {};
  for (split /\n/, $HasVerticals) {
    if (/U\+([0-9A-F]+)/) {
      my $unicode = hex $1;
      if (0xFF00 < $unicode and $unicode < 0xFF5F) {
        $HasVerticalChars->{$unicode - 0xFF00 + 0x20} = 1;
      } else {
        $HasVerticalChars->{$unicode} = 1;
      }
    }
  }
  use utf8;
  write_set
      'jisx0208-1997/has-vertical-example',
      $HasVerticalChars,
      label => 'JIS X 0208:1997 附属書4 (規定) に縦書き例示字形 (参考) あり',
      sw => '縦書き例示字形';
}

{
  my $HasVerticals = q{
0x2122U+3001# IDEOGRAPHIC COMMA
0x2123U+3002# IDEOGRAPHIC FULL STOP
0x2127U+FF1A# FULLWIDTH COLON
0x237CU+2013# EN DASH
0x213DU+2014# EM DASH

# :2004
0x237BU+30A0# KATAKANA-HIRAGANA DOUBLE HYPHEN

0x2145U+2025# TWO DOT LEADER
0x2144U+2026# HORIZONTAL ELLIPSIS
0x2141U+301C# WAVE DASH
0x213CU+30FC# KATAKANA-HIRAGANA PROLONGED SOUND MARK

# vertical only
0x2233U+3033# VERTICAL KANA REPEAT MARK UPPER HALF
0x2234U+3034# VERTICAL KANA REPEAT WITH VOICED SOUND MARK UPPER HALF
0x2235U+3035# VERTICAL KANA REPEAT MARK LOWER HALF
0x2236U+303B# VERTICAL IDEOGRAPHIC ITERATION MARK

0x2146U+2018# LEFT SINGLE QUOTATION MARK
0x2147U+2019# RIGHT SINGLE QUOTATION MARK
0x2D60U+301D# REVERSED DOUBLE PRIME QUOTATION MARK
0x2D61U+301F# LOW DOUBLE PRIME QUOTATION MARK
0x214AU+FF08# FULLWIDTH LEFT PARENTHESIS
0x214BU+FF09# FULLWIDTH RIGHT PARENTHESIS

# :2004
0x2256U+FF5F# FULLWIDTH LEFT WHITE PARENTHESIS
0x2257U+FF60# FULLWIDTH RIGHT WHITE PARENTHESIS

0x214CU+3014# LEFT TORTOISE SHELL BRACKET
0x214DU+3015# RIGHT TORTOISE SHELL BRACKET

# "*" marking missing:
0x214EU+FF3B# FULLWIDTH LEFT SQUARE BRACKET
0x214FU+FF3D# FULLWIDTH RIGHT SQUARE BRACKET

0x2150U+FF5B# FULLWIDTH LEFT CURLY BRACKET
0x2151U+FF5D# FULLWIDTH RIGHT CURLY BRACKET
0x2152U+3008# LEFT ANGLE BRACKET
0x2153U+3009# RIGHT ANGLE BRACKET
0x2154U+300A# LEFT DOUBLE ANGLE BRACKET
0x2155U+300B# RIGHT DOUBLE ANGLE BRACKET
0x2928U+00AB# LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
0x2932U+00BB# RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
0x2156U+300C# LEFT CORNER BRACKET
0x2157U+300D# RIGHT CORNER BRACKET
0x2158U+300E# LEFT WHITE CORNER BRACKET
0x2159U+300F# RIGHT WHITE CORNER BRACKET
0x215AU+3010# LEFT BLACK LENTICULAR BRACKET
0x215BU+3011# RIGHT BLACK LENTICULAR BRACKET
0x225AU+3016# LEFT WHITE LENTICULAR BRACKET
0x225BU+3017# RIGHT WHITE LENTICULAR BRACKET
0x2161U+FF1D# FULLWIDTH EQUALS SIGN
0x2421U+3041# HIRAGANA LETTER SMALL A
0x2423U+3043# HIRAGANA LETTER SMALL I
0x2425U+3045# HIRAGANA LETTER SMALL U
0x2427U+3047# HIRAGANA LETTER SMALL E
0x2429U+3049# HIRAGANA LETTER SMALL O
0x2475U+3095# HIRAGANA LETTER SMALL KA
0x2476U+3096# HIRAGANA LETTER SMALL KE
0x2443U+3063# HIRAGANA LETTER SMALL TU
0x2463U+3083# HIRAGANA LETTER SMALL YA
0x2465U+3085# HIRAGANA LETTER SMALL YU
0x2467U+3087# HIRAGANA LETTER SMALL YO
0x246EU+308E# HIRAGANA LETTER SMALL WA
0x2521U+30A1# KATAKANA LETTER SMALL A
0x2523U+30A3# KATAKANA LETTER SMALL I
0x2525U+30A5# KATAKANA LETTER SMALL U
0x2527U+30A7# KATAKANA LETTER SMALL E
0x2529U+30A9# KATAKANA LETTER SMALL O

# :2004
0x266EU+31F0# KATAKANA LETTER SMALL KU
0x266FU+31F1# KATAKANA LETTER SMALL SI
0x2670U+31F2# KATAKANA LETTER SMALL SU

0x2543U+30C3# KATAKANA LETTER SMALL TU

# :2004
0x2671U+31F3# KATAKANA LETTER SMALL TO
0x2672U+31F4# KATAKANA LETTER SMALL NU
0x2673U+31F5# KATAKANA LETTER SMALL HA
0x2674U+31F6# KATAKANA LETTER SMALL HI
0x2675U+31F7# KATAKANA LETTER SMALL HU
0x2676U+31F8# KATAKANA LETTER SMALL HE
0x2677U+31F9# KATAKANA LETTER SMALL HO
#0x2678U+31F7+309A# [KATAKANA LETTER AINU P]
0x2679U+31FA# KATAKANA LETTER SMALL MU

0x2563U+30E3# KATAKANA LETTER SMALL YA
0x2565U+30E5# KATAKANA LETTER SMALL YU
0x2567U+30E7# KATAKANA LETTER SMALL YO

# :2004
0x267AU+31FB# KATAKANA LETTER SMALL RA
0x267BU+31FC# KATAKANA LETTER SMALL RI
0x267CU+31FD# KATAKANA LETTER SMALL RU
0x267DU+31FE# KATAKANA LETTER SMALL RE

# :2004, "*" marking missing:
0x267EU+31FF# KATAKANA LETTER SMALL RO

0x256EU+30EE# KATAKANA LETTER SMALL WA
0x2575U+30F5# KATAKANA LETTER SMALL KA
0x2576U+30F6# KATAKANA LETTER SMALL KE
0x2D40U+3349# SQUARE MIRI
0x2D41U+3314# SQUARE KIRO
0x2D42U+3322# SQUARE SENTI
0x2D43U+334D# SQUARE MEETORU
0x2D44U+3318# SQUARE GURAMU
0x2D45U+3327# SQUARE TON
0x2D46U+3303# SQUARE AARU
0x2D47U+3336# SQUARE HEKUTAARU
0x2D48U+3351# SQUARE RITTORU
0x2D49U+3357# SQUARE WATTO
0x2D4AU+330D# SQUARE KARORII
0x2D4BU+3326# SQUARE DORU
0x2D4CU+3323# SQUARE SENTO
0x2D4DU+332B# SQUARE PAASENTO
0x2D4EU+334A# SQUARE MIRIBAARU
0x2D4FU+333B# SQUARE PEEZI
  };
  my $HasVerticalChars = {};
  for (split /\n/, $HasVerticals) {
    if (/U\+([0-9A-F]+)/) {
      my $unicode = hex $1;
      if (0xFF00 < $unicode and $unicode < 0xFF5F) {
        $HasVerticalChars->{$unicode - 0xFF00 + 0x20} = 1;
      } else {
        $HasVerticalChars->{$unicode} = 1;
      }
    }
  }
  use utf8;
  write_set
      'jisx0213-2000/has-vertical-example',
      $HasVerticalChars,
      label => 'JIS X 0213:2000 附属書4 (規定) に縦書き例示字形 (参考) あり',
      sw => '縦書き例示字形';

  write_set
      'jisx0213-2000/no-horizontal-example',
      {0x3033, 1, 0x3034, 1, 0x3035, 1, 0x303B, 1},
      label => 'JIS X 0213:2000 附属書4 (規定) に横書き例示字形なし',
      sw => '横書き例示字形';
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
      my $unicode = $J2U->{$r, $c};
      if (0xFF00 < $unicode and $unicode < 0xFF5F) {
        $chars->{$unicode - 0xFF00 + 0x20} = 1;
      } else {
        $chars->{$unicode} = 1;
      }
    }
  }
  use utf8;
  write_set
      'jisx9051-1984/vertical',
      $chars,
      label => 'JIS X 9051-1984 縦書き用字形',
      sw => '縦書き用字形';
  write_set
      'jisx9052-1983/vertical',
      $chars,
      label => 'JIS X 9052-1983 縦書き用字形',
      sw => '縦書き用字形';
}


## License: Public Domain.
