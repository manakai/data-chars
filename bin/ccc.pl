use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use Charinfo::Set;

my $Data = [];
$Data->[$_] = 0 for 0x0000..0x10FFFF;

my $input_f = file (__FILE__)->dir->parent->file ('local', 'unicode', 'latest', 'DerivedCombiningClass.txt');
for (($input_f->slurp)) {
  if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*([0-9]+)/) {
    my $from = hex $1;
    my $to = defined $2 ? hex $2 : $from;
    $Data->[$_] = 0+$3 for $from..$to;
  }
}

my $Sets = {};
for (0..$#$Data) {
  push @{$Sets->{$Data->[$_]} ||= []}, [$_ => $_];
}

my $data_d = file (__FILE__)->dir->parent->subdir ('src', 'set', 'unicode', 'Canonical_Combining_Class');
$data_d->mkpath;

for my $name (keys %$Sets) {
  my $f = $data_d->file ("$name.expr");
  print { $f->openw } Charinfo::Set->serialize_set (Charinfo::Set::set_merge $Sets->{$name}, []);
}

my $perldata_d = file (__FILE__)->dir->parent->subdir ('local', 'perl-unicode', 'lib', 'unicore');
$perldata_d->mkpath;
print { $perldata_d->file ('CombiningClass.pl')->openw }
    qq{<<'END'\n},
    (map { sprintf "%04X\t\t%d\n", $_, $Data->[$_] } grep { $Data->[$_] } 0..$#$Data),
    qq{END\n};

## License: Public Domain.
