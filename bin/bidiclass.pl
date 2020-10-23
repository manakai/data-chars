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
my $prefix = '$unicode' . $uv;

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
  map => 1,
};
$Defs->{"Bidi_Mirroring_Glyph-BEST-FIT"} = {
  label => "Bidi_Mirroring_Glyph BEST FIT mirroring",
  sw => 'Bidi_Mirroring_Glyph',
  file_name => 'Bidi_Mirroring_Glyph-BEST-FIT',
  map => 1,
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

$Defs->{"Bidi_Mirrored"} = {
  label => "Bidi_Mirrored",
  sw => 'Bidi_Mirrored',
  file_name => 'Bidi_Mirrored',
};
{
  my $input_path = $input_ucd_path->child ('DerivedBinaryProperties.txt');
  for (split /\x0A/, $input_path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([0-9A-F]+)\s*;\s*Bidi_Mirrored\s+/) {
      $Chars->{'Bidi_Mirrored'}->{hex $1} = 1;
    } elsif (/^([0-9A-F]+)\.\.([0-9A-F]+)\s*;\s*Bidi_Mirrored\s+/) {
      for ((hex $1)..(hex $2)) {
        $Chars->{'Bidi_Mirrored'}->{$_} = 1;
      }
    }
  }
}

$Defs->{"Bidi_Paired_Bracket"} = {
  label => "Bidi_Paired_Bracket",
  sw => 'Bidi_Paired_Bracket',
  file_name => 'Bidi_Paired_Bracket',
  map => 1,
};
$Defs->{"Bidi_Paired_Bracket_Type:o"} = {
  label => "Bidi_Paired_Bracket_Type=Open",
  sw => 'Bidi_Paired_Bracket_Type',
  file_name => 'Bidi_Paired_Bracket_Type/Open',
};
$Defs->{"Bidi_Paired_Bracket_Type:c"} = {
  label => "Bidi_Paired_Bracket_Type=Close",
  sw => 'Bidi_Paired_Bracket_Type',
  file_name => 'Bidi_Paired_Bracket_Type/Close',
};
$Defs->{"Bidi_Paired_Bracket_Type:n"} = {
  label => "Bidi_Paired_Bracket_Type=None",
  sw => 'Bidi_Paired_Bracket_Type',
  file_name => 'Bidi_Paired_Bracket_Type/None',
  expr => qq{- $prefix:Bidi_Paired_Bracket_Type:Open
             - $prefix:Bidi_Paired_Bracket_Type:Close},
};
{
  my $input_path = $input_ucd_path->child ('BidiBrackets.txt');
  for (split /\x0A/, $input_path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([0-9A-F]+)\s*;\s*([0-9A-F]+)\s*;\s*([oc])\s+/) {
      $Chars->{'Bidi_Paired_Bracket'}->{hex $1} = hex $2;
      $Chars->{'Bidi_Paired_Bracket_Type:'.$3}->{hex $1} = 1;
    }
  }
}

$Defs->{"Vertical_Orientation:U"} = {
  label => "Vertical_Orientation=U",
  sw => 'Vertical_Orientation',
  file_name => 'Vertical_Orientation/U',
};
$Defs->{"Vertical_Orientation:Tu"} = {
  label => "Vertical_Orientation=Tu",
  sw => 'Vertical_Orientation',
  file_name => 'Vertical_Orientation/Tu',
};
$Defs->{"Vertical_Orientation:Tr"} = {
  label => "Vertical_Orientation=Tr",
  sw => 'Vertical_Orientation',
  file_name => 'Vertical_Orientation/Tr',
};
$Defs->{"Vertical_Orientation:R"} = {
  label => "Vertical_Orientation=R",
  sw => 'Vertical_Orientation',
  file_name => 'Vertical_Orientation/R',
  expr => qq{- $prefix:Vertical_Orientation:U
             - $prefix:Vertical_Orientation:Tu
             - $prefix:Vertical_Orientation:Tr},
};
{
  my $input_path = $input_ucd_path->child ('VerticalOrientation.txt');
  for (split /\x0A/, $input_path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([0-9A-F]+)\s*;\s*([A-Za-z]+)\s+/) {
      $Chars->{'Vertical_Orientation:'.$2}->{hex $1} = 1;
    } elsif (/^([0-9A-F]+)\.\.([0-9A-F]+)\s*;\s*([A-Za-z]+)\s+/) {
      $Chars->{'Vertical_Orientation:'.$3}->{sprintf '\\u{%04X}-\u{%04X}', hex $1, hex $2} = 1;
    }
  }
}

for (qw(Initial Nobreak Font Compat Canonical Medial Final Isolated
        Circle Super Sub Vertical Wide Narrow Small Square Fraction)) {
  $Defs->{"Decomposition_Type:$_"} = {
    label => "Decomposition_Type=$_",
    sw => 'Decomposition_Type',
    file_name => "Decomposition_Type/$_",
  };
}
$Defs->{"Decomposition_Type:None"} = {
  label => "Decomposition_Type=None",
  sw => 'Decomposition_Type',
  file_name => 'Decomposition_Type/None',
  expr => qq{
    -$prefix:Decomposition_Type:Canonical 
    -$prefix:Decomposition_Type:Font 
    -$prefix:Decomposition_Type:Initial 
    -$prefix:Decomposition_Type:Medial 
    -$prefix:Decomposition_Type:Final 
    -$prefix:Decomposition_Type:Isolated 
    -$prefix:Decomposition_Type:Circle 
    -$prefix:Decomposition_Type:Super 
    -$prefix:Decomposition_Type:Sub 
    -$prefix:Decomposition_Type:Vertical 
    -$prefix:Decomposition_Type:Wide 
    -$prefix:Decomposition_Type:Narrow 
    -$prefix:Decomposition_Type:Small 
    -$prefix:Decomposition_Type:Square 
    -$prefix:Decomposition_Type:Fraction 
    -$prefix:Decomposition_Type:Compat 
    -$prefix:Decomposition_Type:Nobreak
  },
};
{
  my $input_path = $input_ucd_path->child ('DerivedDecompositionType.txt');
  for (split /\x0A/, $input_path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([0-9A-F]+)\s*;\s*([0-9A-Za-z]+)\s+/) {
      $Chars->{'Decomposition_Type:'.$2}->{hex $1} = 1;
    } elsif (/^([0-9A-F]+)\.\.([0-9A-F]+)\s*;\s*([0-9A-Za-z]+)\s+/) {
      for ((hex $1)..(hex $2)) {
        $Chars->{'Decomposition_Type:'.$3}->{$_} = 1;
      }
    }
  }
}

for my $key (keys %$Defs) {
  my $def = $Defs->{$key};
  my $path = $output_src_path->child (($def->{map} ? 'has-' : '') . $def->{file_name} . '.expr');
  my $file = $path->openw;
  print $file "#label:Unicode @{[$def->{map} ? 'has ' : '']}$def->{label}\x0A#sw:$def->{sw}\x0A";
  if (defined $def->{expr}) {
    print $file $def->{expr};
  } else {
    print $file '[' . (join "\x0A", sort { $a cmp $b } map { /^[0-9]+$/ ? sprintf '\\u{%04X}', $_ : $_ } keys %{$Chars->{$key}}) . ']';
  }
}
for my $key (keys %$Defs) {
  my $def = $Defs->{$key};
  next unless $def->{map};
  my $path = $output_src_map_path->child ($def->{file_name} . '.expr');
  my $file = $path->openw;
  print $file "#label:Unicode $def->{label}\x0A#sw:$def->{sw}\x0A";
  print $file (join "\x0A", map { sprintf '\\u{%04X} -> \\u{%04X}', $_ => $Chars->{$key}->{$_} } sort { $a <=> $b } keys %{$Chars->{$key}});
}

## License: Public Domain.
