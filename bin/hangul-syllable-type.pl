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

my $Sets = {};

my $input_path = $input_ucd_path->child ('HangulSyllableType.txt');
for (split /\x0D?\x0A/, $input_path->slurp) {
  if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*([A-Za-z0-9_-]+)\s*\#/) {
    my $from = hex $1;
    my $to = defined $2 ? hex $2 : $from;
    my $type = $3;
    push @{$Sets->{$type} ||= []}, [$from => $to];
  }
}

my $data_path = $output_src_path->child ('Hangul_Syllable_Type');
$data_path->mkpath;

for my $name (keys %$Sets) {
  my $path = $data_path->child ("$name.expr");
  $path->spew_utf8
      (Charinfo::Set->serialize_set (Charinfo::Set::set_merge $Sets->{$name}, []));
}

## License: Public Domain.
