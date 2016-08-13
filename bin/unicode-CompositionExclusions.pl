use strict;
use warnings;

my $chars = [];

while (<>) {
  if (/^([0-9A-Fa-f]+)(?:\s|$)/) {
    push @$chars, hex $1;
  }
}

printf q{
#name:CompisitionExclusions
#url:http://www.unicode.org/unicode/reports/tr15/#Primary_Exclusion_List_Table
#sw:CompositionExclusions
[%s]
},
    join '', map {
      sprintf '\\u{%04X}', $_;
    } sort { $a <=> $b } @$chars;

## License: Public Domain.
