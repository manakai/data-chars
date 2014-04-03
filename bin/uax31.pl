use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib');
use JSON::Functions::XS qw(perl2json_bytes_for_record file2perl);

my $Data = {};
my $set_d = file (__FILE__)->dir->parent->subdir ('src', 'set', 'uax31');
$set_d->mkpath;

{
  my $json = file2perl file (__FILE__)->dir->parent->file ('local', 'tr31.json');
  print { $set_d->file ('candidates_for_inclusion.expr')->openw } '[' . (join '', map { sprintf '\u{%04X}', $_ } sort { $a <=> $b } keys %{$json->{chars}->{candidates_for_inclusion}}) . ']';
}

## License: Public Domain.
