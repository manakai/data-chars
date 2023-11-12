use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $path = path (shift or die "No JSON path");
my $json = json_bytes2perl $path->slurp;

sub u ($) {
  my $s = shift;
  $s =~ s/^U\+//;
  return sprintf '%04X', hex $s;
} # u

sub uu ($) {
  my $s = shift;
  return join ' ', map { u $_ } split /_/, $s;
} # uu

my $Data = {};
for my $item (@$json) {
  if (length $item->{"実装したUCS"}) {
    printf "%s\t%s\n",
        u $item->{"実装したUCS"},
        $item->{MJ文字図形名};
  }
  if (length $item->{"実装したSVS"}) {
    printf "%s\t%s\n",
        uu $item->{"実装したSVS"},
        $item->{MJ文字図形名};
  }
}

## License: Public Domain.
