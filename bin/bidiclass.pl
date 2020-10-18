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
my $output_src_map_path = $root_path->child ('src/map/unicode' . $uv);
$output_src_path->mkpath;
$output_src_map_path->mkpath;

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
    $path->spew_utf8 ("#label:Unicode Bidi_Class=$name\x0A#sw:Bidi_Class\x0A" . Charinfo::Set->serialize_set (Charinfo::Set::set_merge $Sets->{$name}, []));
  }
}

my $Defs = {};
my $Chars = {};

$Defs->{"Bidi_Mirroring_Glyph"} = {
  label => "Bidi_Mirroring_Glyph",
  sw => 'Bidi_Mirroring_Glyph',
  file_name => 'Bidi_Mirroring_Glyph',
};
$Defs->{"Bidi_Mirroring_Glyph-BEST-FIT"} = {
  label => "Bidi_Mirroring_Glyph BEST FIT mirroring",
  sw => 'Bidi_Mirroring_Glyph',
  file_name => 'Bidi_Mirroring_Glyph-BEST-FIT',
};

{
  my $input_path = $input_ucd_path->child ('BidiMirroring.txt');
  for (split /\x0A/, $input_path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([0-9A-F]+); ([0-9A-F]+) # (\[BEST FIT\]|)/) {
      $Chars->{'Bidi_Mirroring_Glyph'}->{hex $1} = hex $2;
      $Chars->{'Bidi_Mirroring_Glyph-BEST-FIT'}->{hex $1} = hex $2 if $3;
    }
  }
}

for my $key (keys %$Chars) {
  my $def = $Defs->{$key};
  my $path = $output_src_path->child ('has-' . $def->{file_name} . '.expr');
  my $file = $path->openw;
  print $file "#label:Unicode has $def->{label}\x0A#sw:$def->{sw}\x0A";
  print $file '[' . (join "\x0A", map { sprintf '\\u{%04X}', $_ } sort { $a <=> $b } keys %{$Chars->{$key}}) . ']';
}
for my $key (keys %$Chars) {
  my $def = $Defs->{$key};
  my $path = $output_src_map_path->child ($def->{file_name} . '.expr');
  my $file = $path->openw;
  print $file "#label:Unicode $def->{label}\x0A#sw:$def->{sw}\x0A";
  print $file (join "\x0A", map { sprintf '\\u{%04X} -> \\u{%04X}', $_ => $Chars->{$key}->{$_} } sort { $a <=> $b } keys %{$Chars->{$key}});
}

## License: Public Domain.
