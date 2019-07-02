use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;

my $Data = {};

sub uhex ($) {
  my $c = hex $_[0];
  return sprintf '%04X', $c;
} # uhex

sub u ($) {
  my $c = $_[0];
  return sprintf '%04X', $c;
} # u

{
  my $names_list_path = $RootPath->child ('local/unicode/latest/NamesList.txt');
  for (split /\x0D?\x0A/, $names_list_path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^([0-9A-F]{4,})\t([^<].+)/) {
      $Data->{code_to_name}->{uhex $1}->{name} = $2;
    }
  }
}

{
  my $name_aliases_path = $RootPath->child ('local/unicode/latest/NameAliases.txt');
  for (split /\x0D?\x0A/, $name_aliases_path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^([0-9A-F]{4,});([^;]+);([^;\s]+)/) {
      $Data->{code_to_name}->{uhex $1}->{$3}->{$2} = 1;
    }
  }
}

{
  my $named_sequences_path = $RootPath->child ('local/unicode/latest/NamedSequences.txt');
  for (split /\x0D?\x0A/, $named_sequences_path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^([^;]+);([0-9A-F ]+)/) {
      my @code = map { uhex $_ } grep { length $_ } split / +/, $2;
      $Data->{code_seq_to_name}->{join ' ', @code}->{name} = $1;
    }
  }
}

my @L = ("G", "GG", "N", "D", "DD", "R", "M", "B", "BB", "S", "SS", "", "J", "JJ", "C", "K", "T", "P", "H");
my %L = map { $L[$_] => $_ } 0..$#L;
my @V = ("A", "AE", "YA", "YAE", "EO", "E", "YEO", "YE", "O", "WA", "WAE", "OE", "YO", "U", "WEO", "WE", "WI", "YU", "EU", "YI", "I");
my %V = map { $V[$_] => $_ } 0..$#V;
my @T = ("", "G", "GG", "GS", "N", "NJ", "NH", "D", "L", "LG", "LM", "LB", "LS", "LT", "LP", "LH", "M", "B", "BS", "S", "SS", "NG", "J", "C", "K", "T", "P", "H");
my %T = map { $T[$_] => $_ } 0..$#T;

sub hangul_code_to_name ($) {
  my $code = $_[0];
  return undef unless 0xAC00 <= $code and $code <= 0xD7A3;
  $code -= 0xAC00;
  my $l = int ($code / (@V * @T));
  my $v = int (($code % (@V * @T)) / @T);
  my $t = $code % @T;
  return 'HANGUL SYLLABLE ' . $L[$l].$V[$v].$T[$t];
} # hangul_code_to_name

$Data->{code_to_name}->{u $_}->{name} = hangul_code_to_name $_
    for 0xAC00..0xD7A3;

for (0xFDD0..0xFDEF) {
  $Data->{code_to_name}->{u $_}->{label} = 'noncharacter-' . u $_;
}
for (0x00..0x10) {
  for ($_ * 0x10000 + 0xFFFE, $_ * 0x10000 + 0xFFFF) {
    $Data->{code_to_name}->{u $_}->{label} = 'noncharacter-' . u $_;
  }
}

for (0x0000..0x001F, 0x007F, 0x0080..0x009F) {
  $Data->{code_to_name}->{u $_}->{label} = 'control-' . u $_;
}

# XXX src/set/unicode/Script/Han.expr
for (
  [0x3400, 0x4DB5], # Ext A
  [0x4E00, 0x9FCC],
  [0x20000, 0x2A6D6], # Ext B
  [0x2A700, 0x2B734], # Ext C
  [0x2F800, 0x2B81D], # Ext D
) {
  $Data->{range_to_prefix}->{join ' ', u $_->[0], u $_->[1]}->{name}
      = 'CJK UNIFIED IDEOGRAPH-';
}

for (
  [0xE000, 0xF8FF],
  [0xF0000, 0xFFFFD],
  [0x100000, 0x10FFFD],
) {
  $Data->{range_to_prefix}->{join ' ', u $_->[0], u $_->[1]}->{label}
      = 'private-use-';
}

for (
  [0xD800, 0xDFFF],
) {
  $Data->{range_to_prefix}->{join ' ', u $_->[0], u $_->[1]}->{label}
      = 'surrogate-';
}

{
  my $janames_path = $RootPath->child ('src/janames-jisx0213.json');
  my $json = json_bytes2perl $janames_path->slurp;
  for my $key (keys %$json) {
    if ($key =~ / /) {
      $Data->{code_seq_to_name}->{$key}->{ja_name} = $json->{$key};
    } else {
      $Data->{code_to_name}->{$key}->{ja_name} = $json->{$key};
    }
  }
}

$Data->{code_to_name}->{'4EDD'}->{name} ||= 'CJK UNIFIED IDEOGRAPH-4EDD';

{
  my $janames_path = $RootPath->child ('src/janames-jisx0211.json');
  my $json = json_bytes2perl $janames_path->slurp;
  for my $key (keys %$json) {
    $Data->{code_to_name}->{$key}->{ja_name} = $json->{$key};
  }
}

{
  ## JIS X 0202:1998
  use utf8;
  $Data->{code_to_name}->{'0020'}->{ja_name} = 'スペース';
  $Data->{code_to_name}->{'001B'}->{ja_name} = 'エスケープ';
  $Data->{code_to_name}->{'007F'}->{ja_name} = '削除';
}

$Data->{name_alias_types}->{$_} = 1
    for qw(correction control alternate figment abbreviation);

print perl2json_bytes_for_record $Data;

## License: Public Domain.
