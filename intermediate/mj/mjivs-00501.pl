use strict;
use warnings;

my $current = {};
while (<>) {
  if (m{<MJ文字情報>}) {
    $current = {};
  } elsif (m{<MJ文字図形名>(MJ[0-9]+)</MJ文字図形名>}) {
    $current->{name} = $1;
  } elsif (m{<実装したMoji_JohoIVS>([^<>]+)</実装したMoji_JohoIVS>}) {
    $current->{mjivs} = $1;
    die if defined $current->{hdivs};
  } elsif (m{<実装したHanyo-DenshiIVS>([^<>]+)</実装したHanyo-DenshiIVS>}) {
    $current->{hdivs} = $1;
    if (defined $current->{mjivs}) {
      printf "%s\t%s\t%s\t%s\n",
          $current->{name},
          $current->{mjivs},
          $current->{hdivs},
          ($current->{mjivs} eq $current->{hdivs} ? 'eq' : 'different');
    } else {
      printf "%s\t-\t%s\t%s\n",
          $current->{name},
          $current->{hdivs},
          'hdonly';
    }
  }
}

## License: Public Domain.
