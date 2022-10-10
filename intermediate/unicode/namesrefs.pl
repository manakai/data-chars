use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib')->stringify;
use JSON::PS;

BEGIN {
  require (path (__FILE__)->parent->parent->parent->child ('intermediate/vgen/chars.pl')->stringify);
}

my $RootPath = path (__FILE__)->parent->parent->parent;

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
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:x",
          "auto";
    } elsif (/^\tx ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:x",
          "auto";
    } elsif (/^\t\* obsolete ligature for the sequence ([0-9A-F]+(?: [0-9A-F]+)*)$/) {
      insert_rel $Data,
          (u_chr $code), (u_hexs $1), "ucd:names:obsoleted",
          "auto";
    } elsif (/^\t\* use of this character is strongly discouraged; (?:the sequence |)([0-9A-F]+(?: [0-9A-F]+)*) should be used instead$/) {
      insert_rel $Data,
          (u_chr $code), (u_hexs $1), "ucd:names:discouraged",
          "auto";
    } elsif (/^\t\* ([0-9A-F]+) is the preferred character$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:preferred",
          "auto";
    } elsif (/^\t\* use of ([0-9A-F]+) is preferred$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:preferred",
          "auto";
    } elsif (/^\t\*.* ([0-9A-F]+) (?:is (?:the |)|)preferred/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:preferred-some",
          "auto";
    } elsif (/^\t\*.*preferred .+ is ([0-9A-F]+(?: [0-9A-F]+)*)\b/) {
      insert_rel $Data,
          (u_chr $code), (u_hexs $1), "ucd:names:preferred-some",
          "auto";
    } elsif (/^\t\*.* preferred (?:representation|spelling).*: ([0-9A-F]+(?: [0-9A-F]+)*)/) {
      insert_rel $Data,
          (u_chr $code), (u_hexs $1), "ucd:names:preferred-some",
          "auto";
    } elsif (/^\t\*.*preferred to ([0-9A-F]+) for/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:prefers-some",
          "auto";
    } elsif (/^\t\*.*preferred .+ alternate for ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:prefers-some",
          "auto";
    } elsif (/^\t\*.+ alternate for the preferred ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:prefers-some",
          "auto";
    } elsif (/^\t\* this is the preferred character.+as opposed to ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:prefers-some",
          "auto";
    } elsif (/^\t\*.+variant (?:for|of) ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:variant",
          "auto";
    } elsif (/^\t\*.* ([0-9A-F]+) is .* variant/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:variant",
          "auto";
    } elsif (/^\t\*.* pair with ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:related",
          "auto";
    } elsif (/^\t\* transliterated as ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:transliterated",
          "auto";
    } elsif (/^\t\* transliterated as (\w{1,3})$/) {
      insert_rel $Data,
          (u_chr $code), $1, "ucd:names:transliterated",
          "auto";
    } elsif (/^\t\* transliterated as (\w) or as (\w)$/) {
      insert_rel $Data,
          (u_chr $code), $1, "ucd:names:transliterated",
          "auto";
      insert_rel $Data,
          (u_chr $code), $2, "ucd:names:transliterated",
          "auto";
    } elsif (/^\t\* transliterated as (\w) or as ([0-9A-F]+)$/) {
      insert_rel $Data,
          (u_chr $code), $1, "ucd:names:transliterated",
          "auto";
      my $code2 = hex $2;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:transliterated",
          "auto";
    } elsif (/^\t\* not to be confused with ([0-9A-F]+(?:(?:,|, or) [0-9A-F]+)*)$/) {
      for (split /,(?: or|) /, $1) {
        my $code2 = hex $_;
        insert_rel $Data,
            (u_chr $code), (u_chr $code2), "ucd:names:confused",
            "auto";
      }
    } elsif (/^\t\* uppercase is ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:uc",
          "auto";
    } elsif (/^\t\* uppercase is ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:uc-some",
          "auto";
    } elsif (/^\t\* lowercase is ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:lc",
          "auto";
    } elsif (/^\t\*.+ lowercase is ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:lc-some",
          "auto";
    } elsif (/^\t\*.+ ([0-9A-F]+) for lowercase\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:lc-some",
          "auto";
    } elsif (/^\t\* lowercase in .+ is ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:lc-some",
          "auto";
    } elsif (/^\t\*.+ lowercase as ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:lc-some",
          "auto";
    } elsif (/^\t\*.+ lowercase of ([0-9A-F]+) as ([0-9A-F]+)\b/) {
      {
        my $code2 = hex $1;
        insert_rel $Data,
            (u_chr $code), (u_chr $code2), "ucd:names:related",
            "auto";
      }
      {
        my $code2 = hex $2;
        insert_rel $Data,
            (u_chr $code), (u_chr $code2), "ucd:names:related",
            "auto";
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
    my $cmode = {qw(
      kana:h2k          kana
      kana:k2h          kana
      kana:large        kana
      kana:normalize    kana
      kana:small        kana
    )}->{$key} || 'auto';
    for my $in (keys %{$def->{char_to_char} or {}}) {
      my $out = $def->{char_to_char}->{$in};
      insert_rel $Data,
          (u_hexs $in), (u_hexs $out), $key,
          $cmode;
    }
    for my $in (keys %{$def->{char_to_seq} or {}}) {
      my $out = $def->{char_to_seq}->{$in};
      insert_rel $Data,
          (u_hexs $in), (u_hexs $out), $key,
          $cmode;
    }
    for my $in (keys %{$def->{seq_to_char} or {}}) {
      my $out = $def->{seq_to_char}->{$in};
      insert_rel $Data,
          (u_hexs $in), (u_hexs $out), $key,
          $cmode;
    }
    for my $in (keys %{$def->{seq_to_seq} or {}}) {
      my $out = $def->{seq_to_seq}->{$in};
      insert_rel $Data,
          (u_hexs $in), (u_hexs $out), $key,
          $cmode;
    }
  }
}

{
  my $path = $RootPath->child ('local/unicode/latest/StandardizedVariants.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F]+) ([0-9A-F]+)\s*;\s*CJK COMPATIBILITY IDEOGRAPH-([0-9A-F]+);/) {
      #
    } elsif (/^([0-9A-F]+) ([0-9A-F]+)\s*;\s*/) {
      my $c1 = u_hexs "$1 $2";
      my $c2 = u_hexs $1;
      insert_rel $Data,
          $c2, $c1, 'unicode:svs',
          'auto';
    } elsif (/^#([0-9A-F]+) ([0-9A-F]+)\s*;\s*/) {
      my $c1 = u_hexs "$1 $2";
      my $c2 = u_hexs $1;
      insert_rel $Data,
          $c2, $c1, 'unicode:svs:obsolete',
          'auto';
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
