use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use Charinfo::Set;
use JSON::Functions::XS qw(perl2json_bytes_for_record);

my $Data = {};

for my $name (@{Charinfo::Set->get_set_list}) {
  my $set = Charinfo::Set->evaluate_expression ($name);
  $Data->{sets}->{$name}->{chars} = Charinfo::Set->serialize_set ($set);
}

print perl2json_bytes_for_record $Data;
