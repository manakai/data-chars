use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $Data = {};

{
  my $path = $RootPath->child ('data/sets.json');
  my $json = json_bytes2perl $path->slurp;
  for (
    ['$kanji:jouyou-1981' => 'jouyou_s56'],
    ['$kanji:jimmei-1997' => 'jinmei_h9'],
  ) {
    my ($key1, $key2) = @$_;
    my $chars = $json->{sets}->{$key1}->{chars};
    $chars =~ s/^\[//;
    $chars =~ s/\]$//;
    while ($chars =~ s/^\\u([0-9A-F]{4}|\{[0-9A-F]+\})//) {
      my $v1 = $1;
      $v1 =~ s/^\{//;
      $v1 =~ s/\}$//;
      my $cc1 = hex $v1;
      my $cc2 = $cc1;
      if ($chars =~ s/^-\\u([0-9A-F]{4}|\{[0-9A-F]+\})//) {
        my $v2 = $1;
        $v2 =~ s/^\{//;
        $v2 =~ s/\}$//;
        $cc2 = hex $v2;
      }
      for ($cc1..$cc2) {
        $Data->{sets}->{$key2}->{chr $_} = 1;
      }
    }
    die $chars if length $chars;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
