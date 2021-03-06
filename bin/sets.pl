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
  my $prop = Charinfo::Set->get_set_metadata ($name) || {};
  $Data->{sets}->{$name}->{chars} = Charinfo::Set->serialize_set ($set);
  if ($name =~ /^\$rfc([0-9]+):/) {
    $Data->{sets}->{$name}->{spec} = "RFC$1";
  }
  $Data->{sets}->{$name}->{label} = $prop->{label};
  $Data->{sets}->{$name}->{suikawiki_name} = $prop->{sw} // $prop->{label};
  if ($name =~ /^\$[^:]+:(.+)$/) {
    my $label = $1;
    my $swname = $1;
    if ($label =~ s/-char$//) {
      $swname = $label;
      $label = "A character in $label";
    }
    $Data->{sets}->{$name}->{label} //= $label;
    $Data->{sets}->{$name}->{suikawiki_name} //= $swname;
  }
  $Data->{sets}->{$name}->{url} //= $prop->{url} if defined $prop->{url};
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
