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

$Sets->{Bidi_Mirrored}->{sw} = 'Bidi_Mirrored';
$Sets->{Bidi_Mirrored}->{file_name} = 'Bidi_Mirrored';
$Sets->{Bidi_Mirrored}->{label} = 'Bidi_Mirrored=Y';

my $prev_code = -1;
my $in_bidi_mirrored = 0;
while (<>) {
  if (/^([0-9A-F]+)/) {
    my @value = split /;/, $_;
    my $code = hex $value[0];
    my $name = $value[1];
    my $gc = $value[2];
    my $bidi_mirrored = $value[9];
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
    if ($in_bidi_mirrored and
        $bidi_mirrored eq 'Y' and
        ($Chars->{Bidi_Mirrored}->[-1]->[1] == $code - 1 or $name =~ /, Last/)) {
      $Chars->{Bidi_Mirrored}->[-1]->[1] = $code;
    } elsif ($bidi_mirrored eq 'Y') {
      if ($prev_code + 1 != $code) {
        push @{$Chars->{Bidi_Mirrored}}, [$prev_code + 1, $code - 1];
      }
      push @{$Chars->{Bidi_Mirrored}}, [$code, $code];
      $in_bidi_mirrored = 1;
    } else {
      $in_bidi_mirrored = 0;
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
