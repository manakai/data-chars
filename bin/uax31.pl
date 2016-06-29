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
  for my $name (keys %{$json->{chars}}) {
    print { $set_d->file ($name . '.expr')->openw }
        '[' . (join '', map { sprintf '\u{%04X}', $_ } sort { $a <=> $b } keys %{$json->{chars}->{$name}}) . ']';
  }
}

## License: Public Domain.
