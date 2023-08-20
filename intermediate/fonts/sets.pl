use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $Data = {};

{
  my $path = $ThisPath->child ('inherited-tables.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %$json) {
    use utf8;
    my $kk = {
      表一 => 'inherited1',
      表二 => 'inherited2',
    }->{$key};
    $kk = 'inherited3' if $key =~ /^表三/;
    for my $item (@{$json->{$key}}) {
      my $c1 = chr $item->{u}->[0];
      if ($item->{graygreen} and $item->{grayred}) {
        die;
      } elsif ($item->{graygreen}) {
        $Data->{sets}->{$kk . "\tgreen"}->{$c1} = 1;
      } elsif ($item->{grayred}) {
        $Data->{sets}->{$kk . "\tred"}->{$c1} = 1;
      } else {
        $Data->{sets}->{$kk}->{$c1} = 1;
      }
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
