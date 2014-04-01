use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use JSON::Functions::XS qw(perl2json_bytes_for_record file2perl);
use Charinfo::Set;

my @has_compat_decomposition;
my @has_canon_decomposition;

{
  my $f = file (__FILE__)->dir->parent->file ('local', 'unicode', 'latest', 'UnicodeData.txt');
  for (($f->slurp)) {
    chomp;
    my @d = split /;/, $_;

    unless ($d[5] eq '') {
      if ($d[5] =~ s/^<[^<>]+>\s*//) {
        push @has_compat_decomposition, [hex $d[0], hex $d[0]];
      } else {
        push @has_canon_decomposition, [hex $d[0], hex $d[0]];
      }
    }
  }
}

my $set_d = file (__FILE__)->dir->parent->subdir ('src', 'set', 'unicode');
print { $set_d->file ('has_canon_decomposition.expr')->openw }
    Charinfo::Set->serialize_set (\@has_canon_decomposition);
print { $set_d->file ('has_compat_decomposition.expr')->openw }
    Charinfo::Set->serialize_set (\@has_compat_decomposition);

## License: Public Domain.
