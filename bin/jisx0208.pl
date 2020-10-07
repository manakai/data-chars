use strict;
use warnings;
use Path::Tiny;

my $RootPath = path (__FILE__)->parent->parent;
my $DestPath = $RootPath->child ('src/set/jisx0208');

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
    'map-jis-only',
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
    'map-nonjis-only',
    $EncodingsOnly,
    sw => 'JIS X 0208',
    label => 'Alternative characters assigned in JIS X 0208 area of encodings (except for fullwidth variants)';

## License: Public Domain.
