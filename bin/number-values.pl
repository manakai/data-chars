use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Math::BigInt;

my $Data = {};

{
  my $json = json_bytes2perl path (__FILE__)->parent->parent->child
      ('local/spec-numbers.json')->slurp;
  for my $input (@{$json->{'cjk-numeral'}}) {
    my $cp = $input->{codepoint}->[0] // die "No |codepoint|";
    $cp =~ s/^U\+//;
    my $char = chr hex $cp;
    my $value = $input->{value}->[0];
    if (defined $value) {
      if (Math::BigInt->new ($value) < 2**32) {
        $Data->{$char}->{cjk_numeral} = 0+$value;
      } else {
        $Data->{$char}->{cjk_numeral} = $value;
      }
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
