use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use Charinfo::Set;

my $Sets = {};

my $input_f = file (__FILE__)->dir->parent->file ('local', 'unicode', 'latest', 'HangulSyllableType.txt');
for (($input_f->slurp)) {
  if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*([A-Za-z0-9_-]+)\s*\#/) {
    my $from = hex $1;
    my $to = defined $2 ? hex $2 : $from;
    my $type = $3;
    push @{$Sets->{$type} ||= []}, [$from => $to];
  }
}

my $data_d = file (__FILE__)->dir->parent->subdir ('src', 'set', 'unicode', 'Hangul_Syllable_Type');
$data_d->mkpath;

for my $name (keys %$Sets) {
  my $f = $data_d->file ("$name.expr");
  print { $f->openw } Charinfo::Set->serialize_set (Charinfo::Set::set_merge $Sets->{$name}, []);
}

## License: Public Domain.
