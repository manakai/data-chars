use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use JSON::Functions::XS qw(perl2json_bytes_for_record);

my $temp_d = file (__FILE__)->dir->parent->subdir ('local', 'unicode', 'latest');
my $names_list_f = $temp_d->file ('NamesList.txt');
my $name_aliases_f = $temp_d->file ('NameAliases.txt');

my $Data = {};

sub uhex ($) {
  my $c = hex $1;
  return sprintf '%04X', $c;
} # uhex

sub u ($) {
  my $c = $_[0];
  return sprintf '%04X', $c;
} # u

for ($names_list_f->slurp) {
  if (/^([0-9A-F]{4,})\t([^<].+)/) {
    $Data->{code_to_name}->{uhex $1}->{name} = $2;
    #$Data->{name_to_code}->{$2} = hex $1;
  }
}

for ($name_aliases_f->slurp) {
  if (/^([0-9A-F]{4,});([^;]+);([^;\s]+)/) {
    #$Data->{name_to_code}->{$2} = hex $1;
    $Data->{code_to_name}->{uhex $1}->{$3}->{$2} = 1;
  }
}

for (0xFDD0..0xFDEF) {
  $Data->{code_to_name}->{u $_}->{label} = 'noncharacter-' . u $_;
}
for (0x00..0x10) {
  for ($_ * 0x10000 + 0xFFFE, $_ * 0x10000 + 0xFFFF) {
    $Data->{code_to_name}->{u $_}->{label} = 'noncharacter-' . u $_;
  }
}

for (0x0000..0x001F, 0x007F, 0x0080..0x009F) {
  $Data->{code_to_name}->{u $_}->{label} = 'control-' . u $_;
}

for (
  [0x3400, 0x4DB5], # Ext A
  [0x4E00, 0x9FCC],
  [0x20000, 0x2A6D6], # Ext B
  [0x2A700, 0x2B734], # Ext C
  [0x2F800, 0x2B81D], # Ext D
) {
  $Data->{range_to_prefix}->{join ' ', u $_->[0], u $_->[1]}->{name}
      = 'CJK UNIFIED IDEOGRAPH-';
}

for (
  [0xE000, 0xF8FF],
  [0xF0000, 0xFFFFD],
  [0x100000, 0x10FFFD],
) {
  $Data->{range_to_prefix}->{join ' ', u $_->[0], u $_->[1]}->{label}
      = 'private-use-';
}

for (
  [0xD800, 0xDFFF],
) {
  $Data->{range_to_prefix}->{join ' ', u $_->[0], u $_->[1]}->{label}
      = 'surrogate-';
}

print perl2json_bytes_for_record $Data;
