use strict;
use warnings;
use Path::Tiny;
use Web::Encoding;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;

my $Data = [];
{
  my $path = $ThisPath->child ('mji.00601.xlsx.xls.csv');
  my $csv = decode_web_utf8 $path->slurp;
  my $lines = [map { [split /,/, $_, -1] } split /\x0D?\x0A/, $csv];
  my $header = shift @$lines;
  for my $line (@$lines) {
    my $data = {};
    for (0..$#$line) {
      $data->{$header->[$_]} = $line->[$_];
    }
    push @$Data, $data;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
