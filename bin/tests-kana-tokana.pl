use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

my @Dakuten = ("\x{3099}", "\x{309A}", "\x{309B}", "\x{309C}", "\x{FF9E}", "\x{FF9F}");

{
  my $path = $RootPath->child ('data/maps.json');
  my $json = json_bytes2perl $path->slurp;
  {
    my $map = $json->{maps}->{'kana:h2k'};
    for (keys %{$map->{char_to_char}}) {
      my $input = chr hex $_;
      my $output = chr hex $map->{char_to_char}->{$_};
      $Data->{to_hiragana}->{$input} = $input;
      $Data->{to_katakana}->{$input} = $output;
      for my $dakuten (@Dakuten, 'ー', '－') {
        $Data->{to_hiragana}->{$input.$dakuten} = $input.$dakuten;
        $Data->{to_katakana}->{$input.$dakuten} = $output.$dakuten;
      }
    }
    for (keys %{$map->{char_to_seq}}) {
      my $input = chr hex $_;
      my $output = join '', map { chr hex } split / /, $map->{char_to_seq}->{$_};
      $Data->{to_hiragana}->{$input} = $input;
      $Data->{to_katakana}->{$input} = $output;
      for my $dakuten (@Dakuten, 'ー', '－') {
        $Data->{to_hiragana}->{$input.$dakuten} = $input.$dakuten;
        $Data->{to_katakana}->{$input.$dakuten} = $output.$dakuten;
      }
    }
  }
  {
    my $map = $json->{maps}->{'kana:k2h'};
    for (keys %{$map->{char_to_char}}) {
      my $input = chr hex $_;
      my $output = chr hex $map->{char_to_char}->{$_};
      $Data->{to_hiragana}->{$input} = $output;
      $Data->{to_katakana}->{$input} = $input;
      for my $dakuten (@Dakuten, 'ー', '－') {
        $Data->{to_hiragana}->{$input.$dakuten} = $output.$dakuten;
        $Data->{to_katakana}->{$input.$dakuten} = $input.$dakuten;
      }
    }
    for (keys %{$map->{char_to_seq}}) {
      my $input = chr hex $_;
      my $output = join '', map { chr hex } split / /, $map->{char_to_seq}->{$_};
      $Data->{to_hiragana}->{$input} = $input;
      $Data->{to_katakana}->{$input} = $output;
      for my $dakuten (@Dakuten, 'ー', '－') {
        $Data->{to_hiragana}->{$input.$dakuten} = $output.$dakuten;
        $Data->{to_katakana}->{$input.$dakuten} = $input.$dakuten;
      }
    }
  }
}

{
  for (
    ['あいうえお', 'アイウエオ'],
    ['かきくけこ', 'カキクケコ'],
    ['さしすせそ', 'サシスセソ'],
    ['たちつてと', 'タチツテト'],
    ['なにぬねの', 'ナニヌネノ'],
    ['はひふへほ', 'ハヒフヘホ'],
    ['まみむめも', 'マミムメモ'],
    ['やゆよ', 'ヤユヨ'],
    ['らりるれろ', 'ラリルレロ'],
    ['わゐゑをん', 'ワヰヱヲン'],
    ['がぎぐげご', 'ガギグゲゴ'],
    ['ざじずぜぞ', 'ザジズゼゾ'],
    ['だぢづでど', 'ダヂヅデド'],
    ['ばびぶべぼ', 'バビブベボ'],
    ['ぱぴぷぺぽ', 'パピプペポ'],
    ["か\x{309A}き\x{309A}く\x{309A}け\x{309A}こ\x{309A}",
     "カ\x{309A}キ\x{309A}ク\x{309A}ケ\x{309A}コ\x{309A}"],
    ["か\x{309C}き\x{309C}く\x{309C}け\x{309C}こ\x{309C}",
     "カ\x{309C}キ\x{309C}ク\x{309C}ケ\x{309C}コ\x{309C}"],
    ['きゃきゅきょ', 'キャキュキョ'],
    ['あっ', 'アッ'],
  ) {
    my ($hira, $kata) = @$_;
    $Data->{to_hiragana}->{$hira} = $hira;
    $Data->{to_katakana}->{$hira} = $kata;
    $Data->{to_hiragana}->{$kata} = $hira;
    $Data->{to_katakana}->{$kata} = $kata;
  }
}

{
  ## Unchanged
  for (
    0x0000..0x00FF,
    0x4E00,
    0xE000,
    0xF800..0xF8FF,
    0x10000,
    0x1F200,
    0x1F201,
    0x1F202,
    0x1F213,
    0x1F214,
    0x20000,
    0x100000,
    0x10FFFF,
    (map { ord $_ } @Dakuten),
    0x3000..0x33FF,
    0xFF00..0xFFFF,
    0x1B000..0x1B1FF,
  ) {
    my $input = my $output = chr $_;
    $Data->{to_hiragana}->{$input} //= $output;
    $Data->{to_katakana}->{$input} //= $output;
  }

  $Data->{to_hiragana}->{''} = '';
  $Data->{to_katakana}->{''} = '';
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
