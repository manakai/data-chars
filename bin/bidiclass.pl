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

my $Data = [];
$Data->[$_] = 'L' for 0x0000..0x10FFFF; # Left_To_Right

{
  my $input_path = $input_ucd_path->child ('DerivedBidiClass.txt');
  for (split /\x0D?\x0A/, $input_path->slurp) {
    if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*([0-9A-Za-z_]+)/) {
      my $from = hex $1;
      my $to = defined $2 ? hex $2 : $from;
      $Data->[$_] = $3 for $from..$to;
    } elsif (/^#/) {
      #
    } elsif (/\S/) {
      die "Bad line |$_| (DerivedBidiClass.txt)";
    }
  }
}

my $Sets = {};
for (0..$#$Data) {
  push @{$Sets->{$Data->[$_]} ||= []}, [$_ => $_];
}

{
  my $data_path = $output_src_path->child ('Bidi_Class');
  $data_path->mkpath;
  for my $name (keys %$Sets) {
    my $path = $data_path->child ("$name.expr");
    $path->spew_utf8 ("#sw:Bidi_Class\n" . Charinfo::Set->serialize_set (Charinfo::Set::set_merge $Sets->{$name}, []));
  }
}

## License: Public Domain.
