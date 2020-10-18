use strict;
use warnings;
use Path::Tiny;

my $version = shift;

my $d = path (__FILE__)->parent->parent->child ('src', 'set', $version eq 'latest' ? 'unicode' : 'unicode' . $version);
$d->mkpath;

my $Sets = {};
my $Chars = {};

$Sets->{Cn}->{label} = "General_Category=Cn";
$Sets->{Cn}->{sw} = 'Cn';
$Sets->{Cn}->{file_name} = 'Cn';

my $prev_code = -1;
while (<>) {
  if (/^([0-9A-F]+);([^;]+);([^;]+)/) {
    my $code = hex $1;
    my $name = $2;
    my $gc = $3;
    my $bidi_mirrored = $10;
    unless ($Chars->{$gc}) {
      $Chars->{$gc} = [];
      $Sets->{$gc}->{label} = "General_Category=$gc";
      $Sets->{$gc}->{sw} = $gc;
      $Sets->{$gc}->{file_name} = $gc;
    }
    if (@{$Chars->{$gc}} and
        ($Chars->{$gc}->[-1]->[1] == $code - 1 or $name =~ /, Last/)) {
      $Chars->{$gc}->[-1]->[1] = $code;
    } else {
      if ($prev_code + 1 != $code) {
        push @{$Chars->{Cn}}, [$prev_code + 1, $code - 1];
      }
      push @{$Chars->{$gc}}, [$code, $code];
    }
    $prev_code = $code;
  }
}
if ($prev_code != 0x10FFFF) {
  push @{$Chars->{Cn}}, [$prev_code + 1, 0x10FFFF];
}

for my $key (keys %$Chars) {
  my $def = $Sets->{$key};
  my $file = $d->child ($def->{file_name} . '.expr')->openw;
  print $file "#label:Unicode $def->{label}\x0A#sw:$def->{sw}\x0A";
  print $file '[' . (join '', map { sprintf '\\u{%04X}-\\u{%04X}', $_->[0], $_->[1] } @{$Chars->{$key}}) . ']';
}

## License: Public Domain.
