use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $Data = {};

{
  my $json = json_bytes2perl path (__FILE__)->parent->parent->child
      ('local/spec-numbers.json')->slurp;
  for my $input (@{$json->{'cjk-numeral'}}) {
    my $cp = $input->{codepoint}->[0] // die "No |codepoint|";
    $cp =~ s/^U\+//;
    my $char = chr hex $cp;
    my $value = 0 + ($input->{value}->[0] // die "No |value|");
    $Data->{$char}->{cjk_numeral} = $value;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
