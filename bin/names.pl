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
  return $c < 0x10000 ? sprintf '%04X', $c : sprintf '%06X', $c;
} # uhex

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

print perl2json_bytes_for_record $Data;
