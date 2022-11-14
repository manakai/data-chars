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

{
  my $path = $RootPath->child ('src/set/unicode/Script/Han.expr');
  my $expr = $path->slurp_utf8;
  $expr =~ s{^\s*#.*$}{}gm;
  $expr =~ m{^\s*\[(.+)\]\s*$}s or die "Bad |src/set/unicode/Script/Han.expr|";
  my $ranges = $1;
  my $got = [[-1, -1]];
  while (length $ranges) {
    if ($ranges =~ s/^\\u([0-9A-Fa-f]{4}|\{[0-9A-Fa-f]+\})(?:-\\u([0-9A-Fa-f]{4}|\{[0-9A-Fa-f]+\})|)//) {
      my $start = $1;
      my $end = $2 || $1;
      s/[{}]//g for $start, $end;
      $start = hex $start;
      $end = hex $end;
      for ($start..$end) {
        my $v = $Data->{code_to_name}->{u $_};
        if (defined $v and defined $v->{name}) {
          #
        } else {
          if ($got->[-1]->[1] + 1 == $_) {
            $got->[-1]->[1]++;
          } else {
            push @$got, [$_, $_];
          }
        }
      }
    }
  }
  shift @$got;
  for (@$got) {
    $Data->{range_to_prefix}->{join ' ', u $_->[0], u $_->[1]}->{name}
        = 'CJK UNIFIED IDEOGRAPH-';
  }
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
  ## <https://wiki.suikawiki.org/n/%E6%96%87%E5%AD%97%E3%81%AE%E5%90%8D%E5%89%8D#header-section-%E5%90%8D%E5%89%8D%E3%81%A8%E8%A8%80%E8%AA%9E>
  use utf8;
  for (
    ['337E', 'ÈRE MEIJI DISPOSÉ EN CARRÉ', '方形紀元名稱明治'],
    ['337D', 'ÈRE TAÏCHÔ DISPOSÉ EN CARRÉ', '方形紀元名稱大正'],
    ['337C', 'ÈRE CHÔWA DISPOSÉ EN CARRÉ', '方形紀元名稱昭和'],
    ['337B', 'ÈRE HEISEI DISPOSÉ EN CARRÉ', '方形紀元名稱平󠄃成'],
    ['32FF', 'ÈRE REIWA DISPOSÉ EN CARRÉ', undef],
  ) {
    $Data->{code_to_name}->{$_->[0]}->{fr_name} = $_->[1];
    $Data->{code_to_name}->{$_->[0]}->{tw_name} = $_->[2] if defined $_->[2];
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
