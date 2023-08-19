use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;
BEGIN { require 'chars.pl' }
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwh');

my $Data = {};

sub b5_chr ($) {
  my $b5 = shift;
  my $c1 = is_b5_variant $b5 ? sprintf ':b5-hkscs-%x', $b5,
                             : sprintf ':b5-%x', $b5;
  my $c1_0 = $c1;
  $c1_0 =~ s/^:b5-hkscs-/:b5-/g;
  $Data->{codes}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
  return $c1;
} # b5_chr

{
  my $path = $ThisPath->child ('inherited-tables.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %$json) {
    for my $item (@{$json->{$key}}) {
      my $c1 = sprintf ':inherited-%s', chr $item->{u}->[0];
      my $key = get_vkey chr $item->{u}->[0];
      for (@{$item->{b} or []}) {
        my $c2 = b5_chr $_;
        $Data->{$key}->{$c1}->{$c2}->{'inherited:Big5'} = 1;
      }
      for (@{$item->{u} or []}) {
        my $c2 = u_chr $_;
        $Data->{$key}->{$c1}->{$c2}->{'inherited:Unicode'} = 1;
      }
    }
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'maps',
    [
    ];

## License: Public Domain.

