use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib')->stringify;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent->parent;

sub u_chr ($) {
  if ($_[0] <= 0x1F or (0x7F <= $_[0] and $_[0] <= 0x9F)) {
    return sprintf ':u%x', $_[0];
  }
  my $c = chr $_[0];
  if ($c eq ":" or $c eq "." or
      $c =~ /\p{Non_Character_Code_Point}|\p{Surrogate}/) {
    return sprintf ':u%x', $_[0];
  } else {
    return $c;
  }
} # u_chr

sub u_hexs ($) {
  my $s = shift;
  my $i = 0;
  return join '', map {
    my $t = u_chr hex $_;
    if ($i++ != 0) {
      $t = '.' if $t eq ':u2e';
      $t = ':' if $t eq ':u3a';
    }
    if (1 < length $t) {
      return join '', map {
        sprintf ':u%x', hex $_;
      } split /\s+/, $s;
    }
    $t;
  } split /\s+/, $s
} # u_hexs

my $Data = {};

{
  my $names_list_path = $RootPath->child ('local/unicode/latest/NamesList.txt');
  my $code;
  for (split /\x0D?\x0A/, $names_list_path->slurp) {
    s/^\@\+//;
    if (/^\s*#/) {
      #
    } elsif (/^([0-9A-F]{4,})\t(.+)/) {
      $code = hex $1;
    } elsif (/^\tx \(.+ - ([0-9A-F]+)\)$/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:x"} = 1;
    } elsif (/^\tx ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:x"} = 1;
    } elsif (/^\t\* obsolete ligature for the sequence ([0-9A-F]+(?: [0-9A-F]+)*)$/) {
      $Data->{variants}->{u_chr $code}->{u_hexs $1}->{"ucd:names:obsoleted"} = 1;
    } elsif (/^\t\* use of this character is strongly discouraged; (?:the sequence |)([0-9A-F]+(?: [0-9A-F]+)*) should be used instead$/) {
      $Data->{variants}->{u_chr $code}->{u_hexs $1}->{"ucd:names:discouraged"} = 1;
    } elsif (/^\t\* ([0-9A-F]+) is the preferred character$/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:preferred"} = 1;
    } elsif (/^\t\* use of ([0-9A-F]+) is preferred$/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:preferred"} = 1;
    } elsif (/^\t\*.* ([0-9A-F]+) (?:is (?:the |)|)preferred/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:preferred-some"} = 1;
    } elsif (/^\t\*.*preferred .+ is ([0-9A-F]+(?: [0-9A-F]+)*)\b/) {
      $Data->{variants}->{u_chr $code}->{u_hexs $1}->{"ucd:names:preferred-some"} = 1;
    } elsif (/^\t\*.* preferred (?:representation|spelling).*: ([0-9A-F]+(?: [0-9A-F]+)*)/) {
      $Data->{variants}->{u_chr $code}->{u_hexs $1}->{"ucd:names:preferred-some"} = 1;
    } elsif (/^\t\*.*preferred to ([0-9A-F]+) for/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:prefers-some"} = 1;
    } elsif (/^\t\*.*preferred .+ alternate for ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:prefers-some"} = 1;
    } elsif (/^\t\*.+ alternate for the preferred ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:prefers-some"} = 1;
    } elsif (/^\t\* this is the preferred character.+as opposed to ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:prefers-some"} = 1;
    } elsif (/^\t\*.+variant (?:for|of) ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:variant"} = 1;
    } elsif (/^\t\*.* ([0-9A-F]+) is .* variant/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:variant"} = 1;
    } elsif (/^\t\*.* pair with ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:related"} = 1;
    } elsif (/^\t\* transliterated as ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:transliterated"} = 1;
    } elsif (/^\t\* transliterated as (\w{1,3})$/) {
      $Data->{variants}->{u_chr $code}->{$1}->{"ucd:names:transliterated"} = 1;
    } elsif (/^\t\* transliterated as (\w) or as (\w)$/) {
      $Data->{variants}->{u_chr $code}->{$1}->{"ucd:names:transliterated"} = 1;
      $Data->{variants}->{u_chr $code}->{$2}->{"ucd:names:transliterated"} = 1;
    } elsif (/^\t\* transliterated as (\w) or as ([0-9A-F]+)$/) {
      $Data->{variants}->{u_chr $code}->{$1}->{"ucd:names:transliterated"} = 1;
      my $code2 = hex $2;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:transliterated"} = 1;
    } elsif (/^\t\* not to be confused with ([0-9A-F]+(?:(?:,|, or) [0-9A-F]+)*)$/) {
      for (split /,(?: or|) /, $1) {
        my $code2 = hex $_;
        $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:confused"} = 1;
      }
    } elsif (/^\t\* uppercase is ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:uc"} = 1;
    } elsif (/^\t\* uppercase is ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:uc-some"} = 1;
    } elsif (/^\t\* lowercase is ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:lc"} = 1;
    } elsif (/^\t\*.+ lowercase is ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:lc-some"} = 1;
    } elsif (/^\t\*.+ ([0-9A-F]+) for lowercase\b/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:lc-some"} = 1;
    } elsif (/^\t\* lowercase in .+ is ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:lc-some"} = 1;
    } elsif (/^\t\*.+ lowercase as ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:lc-some"} = 1;
    } elsif (/^\t\*.+ lowercase of ([0-9A-F]+) as ([0-9A-F]+)\b/) {
      {
        my $code2 = hex $1;
        $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:related"} = 1;
      }
      {
        my $code2 = hex $2;
        $Data->{variants}->{u_chr $code}->{u_chr $code2}->{"ucd:names:related"} = 1;
      }
    }
  }
}

{
  my $path = $RootPath->child ('data/maps.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (qw(
    fwhw:normalize
    fwhw:strict_normalize

    kana:h2k
    kana:k2h
    kana:large
    kana:normalize
    kana:small

    irc:ascii-lowercase
    irc:rfc1459-lowercase
    irc:strict-rfc1459-lowercase

rfc5051:titlecase-canonical

rfc3454:B.1
rfc3454:B.2
rfc3454:B.3
uts46:mapping

unicode:Case_Folding
unicode:Lowercase_Mapping
unicode:NFKC_Casefold
unicode:Titlecase_Mapping
unicode:Uppercase_Mapping
unicode:canon_composition
unicode:canon_decomposition
unicode:compat_decomposition

unicode5.1:Bidi_Mirroring_Glyph
unicode5.1:Bidi_Mirroring_Glyph-BEST-FIT
unicode:Bidi_Mirroring_Glyph
unicode:Bidi_Mirroring_Glyph-BEST-FIT
unicode:Bidi_Paired_Bracket

unicode:security:confusable
unicode:security:intentional
  )) {
    my $def = $json->{maps}->{$key};
    for my $in (keys %{$def->{char_to_char} or {}}) {
      my $out = $def->{char_to_char}->{$in};
      $Data->{variants}->{u_hexs $in}->{u_hexs $out}->{$key} = 1;
    }
    for my $in (keys %{$def->{char_to_seq} or {}}) {
      my $out = $def->{char_to_seq}->{$in};
      $Data->{variants}->{u_hexs $in}->{u_hexs $out}->{$key} = 1;
    }
    for my $in (keys %{$def->{seq_to_char} or {}}) {
      my $out = $def->{seq_to_char}->{$in};
      $Data->{variants}->{u_hexs $in}->{u_hexs $out}->{$key} = 1;
    }
    for my $in (keys %{$def->{seq_to_seq} or {}}) {
      my $out = $def->{seq_to_seq}->{$in};
      $Data->{variants}->{u_hexs $in}->{u_hexs $out}->{$key} = 1;
    }
  }
}

{
  my $path = $RootPath->child ('local/unicode/latest/StandardizedVariants.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F]+) ([0-9A-F]+)\s*;\s*CJK COMPATIBILITY IDEOGRAPH-([0-9A-F]+);/) {
      #
    } elsif (/^([0-9A-F]+) ([0-9A-F]+)\s*;\s*/) {
      my $c1 = (chr hex $1) . (chr hex $2);
      my $c2 = chr hex $1;
      $Data->{variants}->{$c1}->{$c2}->{'unicode:svs'} = 1;
    } elsif (/^#([0-9A-F]+) ([0-9A-F]+)\s*;\s*/) {
      my $c1 = (chr hex $1) . (chr hex $2);
      my $c2 = chr hex $1;
      $Data->{variants}->{$c1}->{$c2}->{'unicode:svs:obsolete'} = 1;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
