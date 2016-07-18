use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $Data = {};

for my $path (path (__FILE__)->parent->parent->child ('src/key')->children (qr/\.txt$/)) {
  $path =~ m{([^/]+)\.txt$};
  my $name = $1;
  my $def = $Data->{key_sets}->{$name} = {};
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^(\S+)\s+([0-9A-Fa-f]+)$/) {
      $def->{key_to_char}->{$1} = sprintf '%04X', hex $2;
    } elsif (/^#(url|sw|label):(.+)$/) {
      $def->{$1} = $2;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
