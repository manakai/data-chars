use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $Data = {};

sub u_rcv ($) {
  my $s = shift;
  if (2 == length $s) {
    my $c1 = sprintf ':u-rcv-%x-%x',
        (ord substr $s, 0, 1),
        (ord substr $s, 1, 1);
    my $c2 = chr ord substr $s, 0, 1;
    return $c1;
  } else {
    return $s;
  }
} # u_rcv

{
  my $path = $ThisPath->child ('rcv.json');
  my $json = json_bytes2perl $path->slurp;
  for (map { @$_ } $json->{html}) {
    my $c1 = u_rcv $_->[0];
    $Data->{sets}->{rcv_standard}->{$c1} = 1;
    if (defined $_->[1]) {
      my $c2 = u_rcv $_->[1];
      $Data->{sets}->{rcv_simplified}->{$c2} = 1;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
