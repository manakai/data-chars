use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;
use Charinfo::Set;

my $unicode_version = shift or die;

my $root_path = path (__FILE__)->parent->parent;
my $input_ucd_path = $root_path->child ('local/unicode', $unicode_version);
my $uv = ($unicode_version eq 'latest' ? '' : $unicode_version);
$uv =~ s/\.0$//;
my $output_src_path = $root_path->child ('src/set/unicode' . $uv);
my $output_perl_path = $root_path->child ('local/perl-unicode', $unicode_version);

my $Data = [];
$Data->[$_] = 0 for 0x0000..0x10FFFF;

{
  my $input_path = $input_ucd_path->child ('DerivedCombiningClass.txt');
  for (split /\x0D?\x0A/, $input_path->slurp) {
    if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*([0-9]+)/) {
      my $from = hex $1;
      my $to = defined $2 ? hex $2 : $from;
      $Data->[$_] = 0+$3 for $from..$to;
    }
  }
}

my $Sets = {};
for (0..$#$Data) {
  push @{$Sets->{$Data->[$_]} ||= []}, [$_ => $_];
}

{
  my $data_path = $output_src_path->child ('Canonical_Combining_Class');
  $data_path->mkpath;
  for my $name (keys %$Sets) {
    my $path = $data_path->child ("$name.expr");
    $path->spew_utf8 (Charinfo::Set->serialize_set (Charinfo::Set::set_merge $Sets->{$name}, []));
  }
}

{
  my $perldata_path = $output_perl_path->child ('lib');
  $perldata_path->mkpath;
  $perldata_path->child ('unicore-CombiningClass.pl')->spew
      (join '',
       qq{<<'END'\n},
       (map { sprintf "%04X\t\t%d\n", $_, $Data->[$_] } grep { $Data->[$_] } 0..$#$Data),
       qq{END\n});
}

## License: Public Domain.
