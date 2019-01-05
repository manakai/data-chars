use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $set_path = path (__FILE__)->parent->parent->child ('src/set/uax31');
$set_path->mkpath;

{
  my $json_path = path (__FILE__)->parent->parent->child ('local/tr31.json');
  my $json = json_bytes2perl $json_path->slurp;
  for my $name (keys %{$json->{chars}}) {
    print { $set_path->child ($name . '.expr')->openw }
        '[' . (join '', map { sprintf '\u{%04X}', $_ } sort { $a <=> $b } keys %{$json->{chars}->{$name}}) . ']';
  }

  print { $set_path->child ('candidates_for_exclusion.expr')->openw }
      join "\x0A",
          '#label:Candidate Characters for Exclusion from Identifiers',
          '#url:https://www.unicode.org/reports/tr31/#Table_Candidate_Characters_for_Exclusion_from_Identifiers',
          (join " |\x0A", map {
            '$unicode:Script:' . $_;
          } sort { $a cmp $b } keys %{$json->{scripts}->{excluded}}),
          q{
              # $unicode:Extender & Joining_Type=Join_Causing
            | [\u07FA\u0640]
            | $unicode:Default_Ignorable_Code_Point
            | $unicode:Block:Combining_Diacritical_Marks_for_Symbols
            | $unicode:Block:Musical_Symbols
            | $unicode:Block:Ancient_Greek_Musical_Notation
            | $unicode:Block:Phaistos_Disc
          };

  print { $set_path->child ('recommended.expr')->openw }
      join "\x0A",
          '#label:Recommended Scripts',
          '#url:https://www.unicode.org/reports/tr31/#Table_Recommended_Scripts',
          (join " |\x0A", map {
            '$unicode:Script:' . $_;
          } sort { $a cmp $b } keys %{$json->{scripts}->{recommended}});

  print { $set_path->child ('limited.expr')->openw }
      join "\x0A",
          '#label:Limited Use Scripts',
          '#url:https://www.unicode.org/reports/tr31/#Table_Limited_Use_Scripts',
          (join " |\x0A", map {
            '$unicode:Script:' . $_;
          } sort { $a cmp $b } keys %{$json->{scripts}->{limited}});

}

## License: Public Domain.
