use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

for my $path ($RootPath->child ('src/key')->children (qr/\.txt$/)) {
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

{
  my $json = json_bytes2perl $RootPath->child ('local/html-charrefs.json')->slurp;
  for my $name (keys %$json) {
    my $chars = $json->{$name}->{codepoints};
    if (@$chars == 1) {
      $Data->{key_sets}->{html}->{key_to_char}->{$name} = sprintf '%04X', $chars->[0];
    } else {
      $Data->{key_sets}->{html}->{key_to_seq}->{$name} = join ' ', map { sprintf '%04X', $_ } @$chars;
    }
  }
  $Data->{key_sets}->{html}->{label} = 'HTML named character references';
  $Data->{key_sets}->{html}->{url} = q<https://html.spec.whatwg.org/?#named-character-references>;
  $Data->{key_sets}->{html}->{sw} = 'character reference';
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
