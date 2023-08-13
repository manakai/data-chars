use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/icjkvi');
my $DataPath = $RootPath->child ('local/maps');

my $Input = {};
print STDERR "Loading... ";
for my $path (($ThisPath->children (qr/^(?:ids-[0-9]+|variants-ids|hd-ids)\.list$/))) {
  my $file = $path->openr;
  parse_rel_data_file $file => $Input;
}
print STDERR "done\n";

my $Data = {};

for my $c1 (keys %{$Input->{idses}}) {
  for my $c2 (keys %{$Input->{idses}->{$c1}}) {
    my @rel_type = keys %{$Input->{idses}->{$c1}->{$c2}};
    my @c = split_ids $c2;
    for my $c3 (@c) {
      die $c2 if not defined $c3;
      for my $rel_type (@rel_type) {
        my $rt = $rel_type.':contains';
        $rt =~ s/^babel:ids:[\w\[\]]+:contains$/babel:ids:contains/;
        $rt =~ s/^cjkvi:.+:contains$/cjkvi:ids:contains/;
        $Data->{components}->{$c1}->{$c3}->{$rt} = 1
            unless $c1 eq $c3;
      }
      if ($c3 =~ /^:yaids:([\p{Han}\p{Hiragana}\p{Katakana}\x{9000}-\x{9FFF}\x{30000}-\x{3FFFF}])([A-Za-z0-9.]+)$/) {
        my $c4 = $1;
        my $rel_type = 'yaids:variant';
        my $vk = 'hans'; # no get_vkey
        $Data->{$vk}->{$c4}->{$c3}->{$rel_type} = 1;
      }
    }
  }
}

write_rel_data_sets
    $Data => $DataPath, 'idsc',
    [
    ];

## License: Public Domain.
