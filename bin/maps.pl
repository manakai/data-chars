use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;
use JSON::PS;
use Charinfo::Set;

my $unicode_version = 'latest';

my $root_path = path (__FILE__)->parent->parent;
my $input_ucd_path = $root_path->child ('local/unicode', $unicode_version);
my $InputSrcPath = $root_path->child ('src/map');

{
  my $path = $root_path->child ('local/perl-unicode', $unicode_version, 'lib');
  unshift our @INC, $path->stringify;
  require UnicodeNormalize;
}

my $Data = {};

sub uhex ($) {
  return sprintf '%04X', hex $_[0];
} # uhex

sub u ($) {
  return sprintf '%04X', $_[0];
} # u

my $Maps = {};

## <http://www.unicode.org/reports/tr44/#Character_Decomposition_Mappings>
## <http://www.unicode.org/reports/tr44/#Casemapping>
{
  my $path = $input_ucd_path->child ('UnicodeData.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    chomp;
    my @d = split /;/, $_;

    unless ($d[5] eq '') {
      if ($d[5] =~ s/^<[^<>]+>\s*//) {
        $Maps->{'unicode:compat_decomposition'}->{hex $d[0]} = [map { hex $_ } split / /, $d[5]];
      } else {
        $Maps->{'unicode:canon_decomposition'}->{hex $d[0]} =
        $Maps->{'unicode:compat_decomposition'}->{hex $d[0]} = [map { hex $_ } split / /, $d[5]];
      }
    }

    $Maps->{'unicode:Uppercase_Mapping'}->{hex $d[0]} = [hex $d[12]]
        if defined $d[12] and length $d[12];
    $Maps->{'unicode:Lowercase_Mapping'}->{hex $d[0]} = [hex $d[13]]
        if defined $d[13] and length $d[13];
    if (defined $d[14] and length $d[14]) {
      $Maps->{'unicode:Titlecase_Mapping'}->{hex $d[0]} = [hex $d[14]];
    } elsif (defined $d[12] and length $d[12]) {
      $Maps->{'unicode:Titlecase_Mapping'}->{hex $d[0]} = [hex $d[12]];
    }
  }
}

for (0xAC00..0xD7A3) {
  $Maps->{'unicode:canon_decomposition'}->{$_} =
  $Maps->{'unicode:compat_decomposition'}->{$_} = [map { ord $_ } split //, UnicodeNormalize::NFD (chr $_)];
}

{
  my $path = $input_ucd_path->child ('SpecialCasing.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F]+)\s*;\s*([0-9A-F ]*)\s*;\s*([0-9A-F ]*)\s*;\s*([0-9A-F ]*)\s*;\s*\#/) {
      ## Full mapping
      $Maps->{'unicode:Lowercase_Mapping'}->{hex $1} = [map { hex $_ } split / /, $2];
      $Maps->{'unicode:Titlecase_Mapping'}->{hex $1} = [map { hex $_ } split / /, $3];
      $Maps->{'unicode:Uppercase_Mapping'}->{hex $1} = [map { hex $_ } split / /, $4];
    }
  }
}

{
  my $path = $input_ucd_path->child ('CaseFolding.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F]+)\s*;\s*[CF]\s*;\s*([0-9A-F ]*)\s*;\s*\#/) {
      $Maps->{'unicode:Case_Folding'}->{hex $1} = [map { hex $_ } split / /, $2];
    }
  }
}

{
  my $path = $input_ucd_path->child ('DerivedNormalizationProps.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F]+(?:\.\.[0-9A-F]+)?)\s*;\s*NFKC_CF\s*;\s*([0-9A-F ]+)\s*\#/) {
      my ($from, $to) = map { hex $_ } split /\.\./, $1;
      $to //= $from;
      my $new = [map { hex $_ } grep { length } split / /, $2];
      $Maps->{'unicode:NFKC_Casefold'}->{$_} = $new for $from..$to;
    }
  }
}

{
  my $path = $root_path->child ('local/security/latest/confusables.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F][ 0-9A-F]+[0-9A-F])\s*;\s*([0-9A-F][ 0-9A-F]+[0-9A-F])\s/) {
      my $v1 = $1;
      my $v2 = $2;
      my $s1 = join ' ', map { uhex $_ } split / /, $v1;
      my $s2 = join ' ', map { uhex $_ } split / /, $v2;
      $Data->{maps}->{'unicode:security:confusable'}->{chars}->{$s1} = $s2;
    }
  }
}
{
  my $path = $root_path->child ('local/security/latest/intentional.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F][ 0-9A-F]+[0-9A-F])\s*;\s*([0-9A-F][ 0-9A-F]+[0-9A-F])\s/) {
      my $v1 = $1;
      my $v2 = $2;
      my $s1 = join ' ', map { uhex $_ } split / /, $v1;
      my $s2 = join ' ', map { uhex $_ } split / /, $v2;
      $Data->{maps}->{'unicode:security:intentional'}->{chars}->{$s1} = $s2;
    }
  }
}

use Unicode::Stringprep::Mapping;
for (
  ['rfc3454:B.1' => \@Unicode::Stringprep::Mapping::B1],
  ['rfc3454:B.2' => \@Unicode::Stringprep::Mapping::B2],
  ['rfc3454:B.3' => \@Unicode::Stringprep::Mapping::B3],
) {
  my @m = @{$_->[1]};
  while (@m) {
    my $s = shift @m;
    my $t = [map { ord $_ } split //, shift @m];
    $Maps->{$_->[0]}->{$s} = $t;
  }
}

## <http://tools.ietf.org/html/rfc4518#section-2.2>
## <http://www.rfc-editor.org/errata_search.php?rfc=4518>
$Maps->{'rfc4518:map:common'}->{$_} = [] for
    0x00AD, # SOFT HYPHEN
    0x1806, # MONGOLIAN TODO SOFT HYPHEN
    0x034F, # COMBINING GRAPHEME JOINER
    0x180B..0x180D, 0xFE00..0xFE0F, # VARIATION SELECTORs
    0xFFFC, # OBJECT REPLACEMENT CHARACTER
    0x0000..0x0008, 0x000E..0x001F, 0x007F..0x0084,
    0x0086..0x009F, 0x06DD, 0x070F, 0x180E, 0x200C..0x200F,
    0x202A..0x202E, 0x2060..0x2063, 0x206A..0x206F,
    0xFEFF, 0xFFF9..0xFFFB, 0x1D173..0x1D17A, 0xE0001, 0xE0020..0xE007F,
    0x200B; # ZERO WIDTH SPACE
$Maps->{'rfc4518:map:common'}->{$_} = [0x0020] for
    0x0009, # CHARACTER TABULATION
    0x000A, # LINE FEED (LF)
    0x000B, # LINE TABULATION
    0x000C, # FORM FEED (FF)
    0x000D, # CARRIAGE RETURN (CR)
    0x0085, # NEXT LINE (NEL)
    0x0020, 0x00A0, 0x1680, 0x2000..0x200A, 0x2028..0x2029,
    0x202F, 0x205F, 0x3000;
$Maps->{'rfc4518:map:case_folding'} = {%{$Maps->{'rfc3454:B.2'}}};

{
  my $path = $root_path->child ('src/tn1150table.txt');
  my %map = map { join ' ', map { uhex $_ } grep { length } split /\s+/, $_ } split /\s*,\s*/, $path->slurp;
  for (keys %map) {
    $Maps->{'tn1150:decomposition'}->{hex $_} = [map { hex $_ } split / /, $map{$_}];
  }
}
{
  my $path = $root_path->child ('src/tn1150lowercase.json');
  my $json = json_bytes2perl $path->slurp;
  for (keys %$json) {
    $Maps->{'tn1150:lowercase'}->{hex $_} = [length $json->{$_} ? hex $json->{$_} : ()];
  }
}


my $SetsJSON;
my $full_exclusion;
{
  my $path = $root_path->child ('data/sets.json');
  $SetsJSON = json_bytes2perl $path->slurp;
  my $chars = $SetsJSON->{sets}->{'$unicode:Full_Composition_Exclusion'}->{chars};
  $chars =~ s/\\u([0-9A-F]{4})/\\x{$1}/g;
  $chars =~ s/\\u\{([0-9A-F]+)\}/\\x{$1}/g;
  $full_exclusion = qr/$chars/;
}

## <https://www.whatwg.org/specs/web-apps/current-work/#case-sensitivity-and-string-comparison>
## <https://dom.spec.whatwg.org/#strings>
## <https://url.spec.whatwg.org/#ascii-lowercase>
## <https://encoding.spec.whatwg.org/#ascii-lowercase>
for my $from ('A'..'Z') {
  my $to = $from;
  $to =~ tr/A-Z/a-z/;
  $Maps->{'html:to-ASCII-lowercase'}->{ord $from} = [ord $to];
  $Maps->{'html:to-ASCII-uppercase'}->{ord $to} = [ord $from];
  $Maps->{'dom:to-ASCII-lowercase'}->{ord $from} = [ord $to];
  $Maps->{'dom:to-ASCII-uppercase'}->{ord $to} = [ord $from];
  $Maps->{'url:ASCII-lowercase'}->{ord $from} = [ord $to];
  $Maps->{'encoding:ASCII-lowercase'}->{ord $from} = [ord $to];
}

## <https://tools.ietf.org/html/draft-brocklesby-irc-isupport-03#section-3.1>
for my $from (65..90) {
  my $to = $from + ord ('a') - ord ('A');
  $Maps->{'irc:ascii-lowercase'}->{$from} = [$to];
}
for my $from (65..94) {
  my $to = $from + ord ('a') - ord ('A');
  $Maps->{'irc:rfc1459-lowercase'}->{$from} = [$to];
}
for my $from (65..93) {
  my $to = $from + ord ('a') - ord ('A');
  $Maps->{'irc:strict-rfc1459-lowercase'}->{$from} = [$to];
}

{
  $Maps->{'rfc5051:titlecase-canonical'} = {%{$Maps->{'unicode:compat_decomposition'}}, %{$Maps->{'unicode:Titlecase_Mapping'}}};
  for (1..10) {
    for (keys %{$Maps->{'rfc5051:titlecase-canonical'}}) {
      my $v = $Maps->{'rfc5051:titlecase-canonical'}->{$_};
      $Maps->{'rfc5051:titlecase-canonical'}->{$_} = [map { @{$Maps->{'unicode:compat_decomposition'}->{$_} || [$_]} } @$v];
    }
  }
}

{
  use utf8;
  my @hira = split //, 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんゔがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉゃゅょっゕゖ';
  push @hira, "\x{1B150}","\x{1B151}","\x{1B152}";
  my @kata = split //, 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンヴガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポァィゥェォャュョッヵヶ';
  push @kata, "\x{1B164}","\x{1B165}","\x{1B166}";
  for (0..$#hira) {
    $Maps->{'kana:h2k'}->{ord $hira[$_]} = [ord $kata[$_]];
    $Maps->{'kana:k2h'}->{ord $kata[$_]} = [ord $hira[$_]];
  }

  my @small = split //, qw(ぁぃぅぇぉゃゅょっゕゖァィゥェォャュョッヵヶㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇺㇻㇼㇽㇾㇿι);
  push @small, "\x{1B150}","\x{1B151}","\x{1B152}","\x{1B164}",
      "\x{1B165}","\x{1B166}","\x{1B167}";
  my @large = split //, qw(あいうえおやゆよつかけアイウエオヤユヨツカケクシストヌハヒフヘホムラリルレロしゐゑをヰヱヲン);
  for (0..$#small) {
    $Maps->{'kana:large'}->{ord $small[$_]} = [ord $large[$_]];
    $Maps->{'kana:small'}->{ord $large[$_]} = [ord $small[$_]];
  }

  for (map { ord $_ } split //, q(かきくけこさしすせそたちつてとはひふへほカキクケコサシスセソタチツテトハヒフヘホ)) {
    $Maps->{'kana:combine_voiced_sound_marks'}->{$_, 0x3099} = [$_ + 1];
    $Maps->{'kana:combine_voiced_sound_marks'}->{$_, 0x309B} = [$_ + 1];
    $Maps->{'kana:combine_voiced_sound_marks'}->{$_, 0xFF9E} = [$_ + 1];
  }
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'う'), 0x3099} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'う'), 0x309B} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'う'), 0xFF9E} = [ord 'ゔ'];
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ウ'), 0x3099} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ウ'), 0x309B} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ウ'), 0xFF9E} = [ord 'ヴ'];
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ワ'), 0x3099} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ワ'), 0x309B} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ワ'), 0xFF9E} = [ord 'ヷ'];
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヰ'), 0x3099} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヰ'), 0x309B} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヰ'), 0xFF9E} = [ord 'ヸ'];
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヱ'), 0x3099} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヱ'), 0x309B} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヱ'), 0xFF9E} = [ord 'ヹ'];
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヲ'), 0x3099} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヲ'), 0x309B} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヲ'), 0xFF9E} = [ord 'ヺ'];
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord '〱'), 0x3099} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord '〱'), 0x309B} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord '〱'), 0xFF9E} = [ord '〲'];
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord '〳'), 0x3099} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord '〳'), 0x309B} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord '〳'), 0xFF9E} = [ord '〴'];
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ゝ'), 0x3099} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ゝ'), 0x309B} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ゝ'), 0xFF9E} = [ord 'ゞ'];
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヽ'), 0x3099} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヽ'), 0x309B} =
  $Maps->{'kana:combine_voiced_sound_marks'}->{(ord 'ヽ'), 0xFF9E} = [ord 'ヾ'];
  for (map { ord $_ } split //, q(はひふへほハヒフヘホ)) {
    $Maps->{'kana:combine_voiced_sound_marks'}->{$_, 0x309A} = [$_ + 2];
    $Maps->{'kana:combine_voiced_sound_marks'}->{$_, 0x309C} = [$_ + 2];
    $Maps->{'kana:combine_voiced_sound_marks'}->{$_, 0xFF9F} = [$_ + 2];
  }
  $Maps->{'kana:k2h'}->{ord 'ヷ'} = [(ord 'わ'), 0x3099];
  $Maps->{'kana:k2h'}->{ord 'ヸ'} = [(ord 'ゐ'), 0x3099];
  $Maps->{'kana:k2h'}->{ord 'ヹ'} = [(ord 'ゑ'), 0x3099];
  $Maps->{'kana:k2h'}->{ord 'ヺ'} = [(ord 'を'), 0x3099];
#  $Maps->{'kana:h2k'}->{(ord 'わ'), 0x3099} = [ord 'ヷ'];
#  $Maps->{'kana:h2k'}->{(ord 'ゐ'), 0x3099} = [ord 'ヸ'];
#  $Maps->{'kana:h2k'}->{(ord 'ゑ'), 0x3099} = [ord 'ヹ'];
#  $Maps->{'kana:h2k'}->{(ord 'を'), 0x3099} = [ord 'ヺ'];
  $Maps->{'kana:h2k'}->{ord 'ゝ'} = [ord 'ヽ'];
  $Maps->{'kana:k2h'}->{ord 'ヽ'} = [ord 'ゝ'];
  $Maps->{'kana:h2k'}->{ord 'ゞ'} = [ord 'ヾ'];
  $Maps->{'kana:k2h'}->{ord 'ヾ'} = [ord 'ゞ'];
  $Maps->{'kana:k2h'}->{0x1B000} = [ord 'え']; # KATAKANA LETTER ARCHAIC E
}
{
  use utf8;
  my @hira = split //, 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんぁぃぅぇぉゃゅょっ';
  my @kata = split //, 'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝｧｨｩｪｫｬｭｮｯ';
  for (0..$#hira) {
    $Maps->{'kana:k2h'}->{ord $kata[$_]} = [ord $hira[$_]];
  }
}
{
  my $path = $root_path->child ('local/hentai_to_standard.json');
  my $json = json_bytes2perl $path->slurp;
  for (keys %$json) {
    my $hentaigana = ord $_;
    my $hiragana = ord $json->{$_};
    my $katakana_mapped = $Maps->{'kana:h2k'}->{$hiragana}
        or die "|$json->{$_}| has no Katakana";
    $Maps->{'kana:h2k'}->{$hentaigana} = $katakana_mapped;
  }
}

{
  use utf8;
  my @fw = (0x3000, 0xFF00..0xFFEF);
  for (0..$#fw) {
    $Maps->{'kana:normalize'}->{$fw[$_]} =
    $Maps->{'fwhw:strict_normalize'}->{$fw[$_]} =
    $Maps->{'fwhw:normalize'}->{$fw[$_]}
        = $Maps->{'unicode:compat_decomposition'}->{$fw[$_]} || [$fw[$_]];
  }
  $Maps->{'kana:normalize'}->{0xFF5E} = [0x301C];
  $Maps->{'fwhw:normalize'}->{0xFF5E} = [0x301C];
  $Maps->{'fwhw:normalize'}->{0x2212} = [ord '-'];
  $Maps->{'kana:normalize'}->{0x3000} = [0x0020, 0x0020];
  for (split //, q(ｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾊﾋﾌﾍﾎﾜｦ)) {
    $Maps->{'kana:combine_voiced_sound_marks'}->{(ord $_), 0x3099} =
    $Maps->{'kana:combine_voiced_sound_marks'}->{(ord $_), 0x309B} =
    $Maps->{'kana:combine_voiced_sound_marks'}->{(ord $_), 0xFF9E} =
    $Maps->{'kana:combine_voiced_sound_marks'}->{$Maps->{'kana:normalize'}->{ord $_}->[0], 0x3099};
  }
  for (split //, q(ﾊﾋﾌﾍﾎ)) {
    $Maps->{'kana:combine_voiced_sound_marks'}->{(ord $_), 0x309A} =
    $Maps->{'kana:combine_voiced_sound_marks'}->{(ord $_), 0x309C} =
    $Maps->{'kana:combine_voiced_sound_marks'}->{(ord $_), 0xFF9F} =
    $Maps->{'kana:combine_voiced_sound_marks'}->{$Maps->{'kana:normalize'}->{ord $_}->[0], 0x309A};
  }

  for (keys %{$Maps->{'kana:combine_voiced_sound_marks'}}) {
    $Maps->{'kana:normalize'}->{$_} = $Maps->{'kana:combine_voiced_sound_marks'}->{$_};
  }

  my $set = Charinfo::Set->evaluate_expression ($SetsJSON->{sets}->{'$kana:before-mark'}->{chars});
  for (@$set) {
    for ($_->[0]..$_->[1]) {
      $Maps->{'kana:normalize'}->{$_, 0x309B} //= [$_, 0x3099];
      $Maps->{'kana:normalize'}->{$_, 0xFF9E} //= [$_, 0x3099];
      $Maps->{'kana:normalize'}->{$_, 0x309C} //= [$_, 0x309A];
      $Maps->{'kana:normalize'}->{$_, 0xFF9F} //= [$_, 0x309A];
    }
  }

  $Maps->{'kana:normalize'}->{0x3033, 0x3035} = [0x3031];
  $Maps->{'kana:normalize'}->{0x3034, 0x3035} = [0x3032];
}

for my $map (keys %$Maps) {
  for my $char (keys %{$Maps->{$map}}) {
    my @m = @{$Maps->{$map}->{$char}};
    my $i = 0;
    {
      my $changed;
      @m = map {
        if (defined $Maps->{$map}->{$_}) {
          $changed = 1 unless @{$Maps->{$map}->{$_}} == 1 and $Maps->{$map}->{$_}->[0] == $_;
          @{$Maps->{$map}->{$_}};
        } else {
          ($_);
        }
      } @m;
      warn join (' ', map { sprintf '%04X', $_ } @m), "\n" if $i > 9;
      redo if $changed and $i++ < 12;
      warn "$map does not converge" if $changed;
    }
    $Data->{maps}->{$map}->{chars}->{join ' ', map { u $_ } split /\Q$;\E/, $char} = join ' ', map { u $_ } @m;
  }
}

for my $from_char (keys %{$Data->{maps}->{'unicode:canon_decomposition'}->{chars}}) {
  my $to_chars = $Data->{maps}->{'unicode:canon_decomposition'}->{chars}->{$from_char};
  next if (chr hex $from_char) =~ /$full_exclusion/o;
  warn "Duplicate: $to_chars" if $Data->{maps}->{'unicode:canon_composition'}->{chars}->{$to_chars};
  $Data->{maps}->{'unicode:canon_composition'}->{chars}->{$to_chars} = $from_char;
}

for (
  ['$rfc7613:non-ASCII-space' => 'rfc7613:non-ASCII-space'],
  ['$rfc7700:non-ASCII-space' => 'rfc7700:non-ASCII-space'],
) {
  my ($set_name, $map_name) = @$_;
  my $set = Charinfo::Set->evaluate_expression ($SetsJSON->{sets}->{$set_name}->{chars});
  for (@$set) {
    for ($_->[0]..$_->[1]) {
      $Data->{maps}->{$map_name}->{chars}->{u $_} = '0020';
    }
  }
}

## <http://www.whatwg.org/specs/web-apps/current-work/#consume-a-character-reference>
for (
  [0x00, 0xFFFD],
  [0x80, 0x20AC],
  [0x82, 0x201A],
  [0x83, 0x0192],
  [0x84, 0x201E],
  [0x85, 0x2026],
  [0x86, 0x2020],
  [0x87, 0x2021],
  [0x88, 0x02C6],
  [0x89, 0x2030],
  [0x8A, 0x0160],
  [0x8B, 0x2039],
  [0x8C, 0x0152],
  [0x8E, 0x017D],
  [0x91, 0x2018],
  [0x92, 0x2019],
  [0x93, 0x201C],
  [0x94, 0x201D],
  [0x95, 0x2022],
  [0x96, 0x2013],
  [0x97, 0x2014],
  [0x98, 0x02DC],
  [0x99, 0x2122],
  [0x9A, 0x0161],
  [0x9B, 0x203A],
  [0x9C, 0x0153],
  [0x9E, 0x017E],
  [0x9F, 0x0178],
) {
  $Data->{maps}->{'html:charref'}->{chars}->{u $_->[0]} = u $_->[1];
}
for (
  [0x00, 0xFFFD],
) {
  $Data->{maps}->{'xml:charref'}->{chars}->{u $_->[0]} = u $_->[1];
}
for (0xD800..0xDFFF) {
  $Data->{maps}->{'html:charref'}->{chars}->{u $_} = u 0xFFFD;
  $Data->{maps}->{'xml:charref'}->{chars}->{u $_} = u 0xFFFD;
}
## And > U+10FFFF

{
  my $refs = {};
for my $dir_path (($InputSrcPath->children)) {
  if ($dir_path->is_dir) {
    for my $file_path (($dir_path->children (qr(\.expr$)))) {
      my $key = $file_path->relative ($InputSrcPath);
      $key =~ s/\.expr$//g;
      $key =~ s{/}{:}g;
      for (split /\n/, $file_path->slurp_utf8) {
        if (/^\s*#/) {
          #
        #XXX #sw:
        #XXX #label:
        #XXX #url:
        } elsif (/^((?:\\u\{[0-9A-Fa-f]+\})+)\s*->\s*((?:\\u\{[0-9A-Fa-f]+\})+)$/) {
          my $v1 = $1;
          my $v2 = $2;
          $v1 =~ s/\\u\{([0-9A-Fa-f]+)\}/chr hex $1/ge;
          $v2 =~ s/\\u\{([0-9A-Fa-f]+)\}/chr hex $1/ge;
          $v1 = join ' ', map { u ord $_ } split //, $v1;
          $v2 = join ' ', map { u ord $_ } split //, $v2;
          $Data->{maps}->{$key}->{chars}->{$v1} = $v2;
        } elsif (/^([A-Za-z][A-Za-z0-9:_.-]*)$/) {
          $refs->{$key}->{$1} = 1;
        } elsif (/\S/) {
          die "|$file_path|: Bad line |$_|";
        }
      }
    }
  }
}
  # XXX ref resolution orders
  for my $key (keys %$refs) {
    for my $key2 (keys %{$refs->{$key}}) {
      die "Bad key |$key2| referenced from |$key|"
          unless defined $Data->{maps}->{$key2};
      my $values = $Data->{maps}->{$key2}->{chars};
      for my $from (keys %$values) {
        $Data->{maps}->{$key}->{chars}->{$from} = $values->{$from};
      }
    }
  }
}

for my $path ($root_path->child ('local/map-data')->children (qr/\.json$/)) {
  $path =~ m{([^/]+)\.json$};
  my $name = $1;
  $name =~ s/--/:/g;
  my $json = json_bytes2perl $path->slurp;
  $Data->{maps}->{$name} = $json;
}

for my $key (keys %{$Data->{maps}}) {
  my $entries = delete $Data->{maps}->{$key}->{chars};
  for my $from (keys %$entries) {
    my $to = $entries->{$from};
    next if $from eq $to;
    my $type = join '_to_',
        $from =~ / / ? 'seq' : 'char',
        $to eq '' ? 'empty' : $to =~ / / ? 'seq' : 'char';
    $Data->{maps}->{$key}->{$type}->{$from} = $to;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
