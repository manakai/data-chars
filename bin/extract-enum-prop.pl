use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;
use Charinfo::Set;

my $unicode_version = shift or die;
my $PropName = shift or die;

my $root_path = path (__FILE__)->parent->parent;
my $input_ucd_path = $root_path->child ('local/unicode', $unicode_version);
my $uv = ($unicode_version eq 'latest' ? '' : $unicode_version);
$uv =~ s/\.0$//;
my $output_src_path = $root_path->child ('src/set/unicode' . $uv);
my $output_src_map_path = $root_path->child ('src/map/unicode' . $uv);
my $prefix = '$unicode' . $uv;

my $PropDef = {
  'Joining_Type' => {
    data_file_name => 'DerivedJoiningType.txt',
    values => {
      Non_Joining => {
        short => 'U',
      },
      Join_Causing => {
        short => 'C',
      },
      Dual_Joining => {
        short => 'D',
      },
      Right_Joining => {
        short => 'R',
      },
      Left_Joining => {
        short => 'L',
      },
      Transparent => {
        short => 'T',
      },
    },
  },
  'Joining_Group' => {
    data_file_name => 'DerivedJoiningGroup.txt',
    values => {
    },
  },
}->{$PropName} or die "Bad property name |$PropName|";
my $ToPropValue = [];

my $ValueMap = {};
for my $canon (keys %{$PropDef->{values} or {}}) {
  $ValueMap->{$canon} = $canon;
  $ValueMap->{$PropDef->{values}->{$canon}->{short}} = $canon
      if defined $PropDef->{values}->{$canon}->{short};
}

{
  my $input_path = $input_ucd_path->child ($PropDef->{data_file_name});
  for (split /\x0D?\x0A/, $input_path->slurp) {
    if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*([0-9A-Za-z_]+)/) {
      my $from = hex $1;
      my $to = defined $2 ? hex $2 : $from;
      $ToPropValue->[$_] = $ValueMap->{$3} // $3 for $from..$to;
    } elsif (/^#\s*\@missing:\s*([0-9A-F]+)\.\.([0-9A-F]+)\s*;\s*(\S+)\s*$/) {
      my $from = hex $1;
      my $to = hex $2;
      $ToPropValue->[$_] //= $ValueMap->{$3} // $3 for $from..$to;
    } elsif (/^#/) {
      #
    } elsif (/\S/) {
      die "$input_path: Bad line |$_|";
    }
  }
}

my $Props = {};
for my $c (0x0000..0x10FFFF) {
  my $v = $ToPropValue->[$c] // next;
  my $s = $Props->{$v} ||= [];
  if (@$s and $s->[-1]->[1] + 1 == $c) {
    $s->[-1]->[1] = $c;
  } else {
    push @$s, [$c, $c];
  }
}

my $prop_data_path = $output_src_path->child ($PropName);
$prop_data_path->mkpath;
for my $value (keys %$Props) {
  my $vdef = $PropDef->{values}->{$value};
  my $path = $prop_data_path->child ("$value.expr");
  $path->spew_utf8 (sprintf "#label:Unicode %s=%s%s\x0A#sw:%s\x0A%s",
                        $PropName,
                        $value,
                        (defined $vdef->{short} ? ' ('.$vdef->{short}.')' : ''),
                        $PropName,
                        Charinfo::Set->serialize_set ($Props->{$value}));
  if (defined $vdef->{short}) {
    my $path = $prop_data_path->child ("$vdef->{short}.expr");
    $path->spew_utf8 (sprintf "#label:Unicode %s=%s (%s)\x0A#sw:%s\x0A%s",
                          $PropName,
                          $value,
                          $vdef->{short},
                          $PropName,
                          $prefix.':'.$PropName.':'.$value);
  }
}

## License: Public Domain.
