use strict;
use warnings;

my $current = {};
while (<>) {
  if (m{<MJ文字情報>}) {
    $current = {};
  } elsif (m{<MJ文字図形名>(MJ[0-9]+)</MJ文字図形名>}) {
    $current->{name} = $1;
  } elsif (m{<平成明朝>(\w+)</平成明朝>}) {
    $current->{heisei} = $1;
    printf "%s\t%s\n",
        $current->{name},
        $current->{heisei};
  }
}

## License: Public Domain.
