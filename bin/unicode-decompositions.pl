use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use JSON::Functions::XS qw(perl2json_bytes_for_record file2perl);
use Charinfo::Set;
use Unicode::Normalize;

my @has_compat_decomposition;
my @has_canon_decomposition;
my @canon_decomposition_second;

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
        if ($d[5] =~ /^[0-9A-Fa-f]+\s+([0-9A-Fa-f]+)\b/) {
          push @canon_decomposition_second, [hex $1, hex $1];
        }
      }
    }
  }
}

for (0xAC00..0xD7A3) {
  my $c1 = chr $_;
  my $c2 = NFD $c1;
  next if $c1 eq $c2;
  push @has_canon_decomposition, [ord $c1, ord $c1];
  my @c2 = split //, $c2;
  shift @c2;
  for my $c2 (@c2) {
    push @canon_decomposition_second, [ord $c2, ord $c2];
  }
}

my $set_d = file (__FILE__)->dir->parent->subdir ('src', 'set', 'unicode');
print { $set_d->file ('has_canon_decomposition.expr')->openw }
    Charinfo::Set->serialize_set (\@has_canon_decomposition);
print { $set_d->file ('has_compat_decomposition.expr')->openw }
    Charinfo::Set->serialize_set (\@has_compat_decomposition);
print { $set_d->file ('canon_decomposition_second.expr')->openw }
    Charinfo::Set->serialize_set (\@canon_decomposition_second);

## License: Public Domain.
