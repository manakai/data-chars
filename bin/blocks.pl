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

my $input_path = $input_ucd_path->child ('Blocks.txt');
for (split /\x0D?\x0A/, $input_path->slurp) {
  if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*([A-Za-z0-9_\s-]+)/) {
    my $from = hex $1;
    my $to = defined $2 ? hex $2 : $from;
    my $type = $3;
    $type =~ s/\A\s+//;
    $type =~ s/\s+\z//;
    $type =~ s/\s+/_/g;
    push @{$Sets->{$type} ||= []}, [$from => $to];
  }
}

my $data_path = $output_src_path->child ('Block');
$data_path->mkpath;

for my $name (keys %$Sets) {
  my $path = $data_path->child ("$name.expr");
  $path->spew_utf8
      (Charinfo::Set->serialize_set (Charinfo::Set::set_merge $Sets->{$name}, []));
}

{
  my $path = $data_path->child ('No_Block.expr');
  $path->spew_utf8
      ('[\u0000-\u{10FFFF}]'
       . join '', map { "\x0A- " . '$unicode'.$uv.':Block:' . $_ } sort { $a cmp $b } keys %$Sets);
}

## License: Public Domain.
