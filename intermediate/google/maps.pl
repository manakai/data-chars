use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iad');
my $DataPath = $RootPath->child ('local/maps');
$DataPath->mkpath;

my $Data = {};

for (
  ['DroidSansFallback-ff-dump.json', ':dsfff'],
  ['DroidSansFallback-aosp-dump.json', ':dsf'],
  ['DroidSansFallbackFull-aosp-dump.json', ':dsffull'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $json = json_bytes2perl $path->slurp;
  my $prefix = $_->[1];

  for (@{$json->{cmap}}) {
    for my $code (sort { $a <=> $b } keys %{$_->{glyphIndexMap}}) {
      my $cid = $_->{glyphIndexMap}->{$code};
      my $c1 = u_chr $code;
      my $c2 = sprintf '%s%d', $prefix, $cid;
      $Data->{components}->{$c1}->{$c2}->{'droidsansfallback:cmap'} = 1;
    }
  }

  for (@{$json->{glyphs}}) {
    my $cid1 = $_->[0];
    my $c1 = sprintf '%s%d', $prefix, $cid1;
    my $components = [map { $_->{glyphIndex} } @{$_->[1]}];
    for my $cid2 (@$components) {
      my $c2 = sprintf '%s%d', $prefix, $cid2;
      $Data->{components}->{$c1}->{$c2}->{'opentype:component'} = 1;
    }
  }
}

write_rel_data_sets
    $Data => $DataPath, 'dsf',
    [
    ];

## License: Public Domain.
