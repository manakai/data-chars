use strict;
use warnings;

my $header = 1;
while (<>) {
  if ($header) {
    $header = 0;
  } else {
    if (/^(MJ[0-9]+),.+,([^,]+),[^,]*$/) {
      print "$1\t$2\n";
    }
  }
}

## License: Public Domain.
