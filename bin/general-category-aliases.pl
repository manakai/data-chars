use strict;
use warnings;
use Path::Tiny;

my $version = shift;
my $group = 'unicode' . ($version eq 'latest' ? '' : $version);
my $path = path (__FILE__)->parent->parent->child ('src/set/' . $group);

my @name = qw(
  Lu Uppercase_Letter
  Ll Lowercase_Letter
  Lt Titlecase_Letter
  Lm Modifier_Letter
  Lo Other_Letter
  Mn Nonspacing_Mark
  Mc Spacing_Mark
  Me Enclosing_Mark
  Nd Decimal_Number
  Nl Letter_Number
  No Other_Number
  Pc Connector_Punctuation
  Pd Dash_Punctuation
  Ps Open_Punctuation
  Pe Close_Punctuation
  Pi Initial_Punctuation
  Pf Final_Punctuation
  Po Other_Punctuation
  Sm Math_Symbol
  Sc Currency_Symbol
  Sk Modifier_Symbol
  So Other_Symbol
  Zs Space_Separator
  Zl Line_Separator
  Zp Paragraph_Separator
  Cc Control
  Cf Format
  Cs Surrogate
  Co Private_Use
  Cn Unassigned

  LC Cased_Letter
  L Letter
  M Mark
  N Number
  P Punctuation
  S Symbol
  Z Separator
  C Other
);
while (@name) {
  my $n = shift @name;
  my $name = shift @name;
  my $p = $path->child ("$name.expr");
  $p->spew (qq{#name:General_Category=$name
#sw:$name
#url:http://www.unicode.org/reports/tr44/#General_Category_Values
\$$group:$n});
}

for (
  [LC => Cased_Letter => [qw(Lu Ll Lt)]],
  [L => Letter => [qw(Lu Ll Lt Lm Lo)]],
  [M => Mark => [qw(Mn Mc Me)]],
  [N => Number => [qw(Nd Nl No)]],
  [P => Punctuation => [qw(Pc Pd Ps Pe Pi Pf Po)]],
  [S => Symbol => [qw(Sm Sc Sk So)]],
  [Z => Separator => [qw(Zs Zl Zp)]],
  [C => Other => [qw(Cc Cf Cs Co Cn)]],
) {
  my ($n, $name, $sets) = @$_;
  my $p = $path->child ("$n.expr");
  $p->spew (qq{#name:General_Category=$n
#sw:$name
#url:http://www.unicode.org/reports/tr44/#General_Category_Values
} . join ' | ', map { '$'.$group.':'.$_ } @$sets);
}

## License: Public Domain.
