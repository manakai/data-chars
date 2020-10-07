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
{
  my $path = $RootPath->child ('local/jis-0208.txt');
  for (split /\n/, $path->slurp) {
    if (m{^0x[0-9A-F]+\tU\+([0-9A-F]+)\t}) {
      $JISChars->{hex $1} = 1;
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
      if (0xFF00 <= $unicode and $unicode <= 0xFF5F) {
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
      label => 'JIS X 0208:1997 附属書4 (規定) に縦書き例示字形あり',
      sw => '縦書き例示字形';
}

## License: Public Domain.
