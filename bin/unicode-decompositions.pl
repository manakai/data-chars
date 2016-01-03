use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;
use JSON::PS;
use Charinfo::Set;

my $unicode_version = 'latest';

my $root_path = path (__FILE__)->parent->parent;

{
  my $path = $root_path->child ('local/perl-unicode', $unicode_version, 'lib');
  unshift our @INC, $path->stringify;
  require UnicodeNormalize;
}

my @has_compat_decomposition;
my @has_canon_decomposition;
my @canon_decomposition_second;

{
  my $path = $root_path->child ('local/unicode', $unicode_version, 'UnicodeData.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
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
  my $c2 = UnicodeNormalize::NFD ($c1);
  next if $c1 eq $c2;
  push @has_canon_decomposition, [ord $c1, ord $c1];
  my @c2 = split //, $c2;
  shift @c2;
  for my $c2 (@c2) {
    push @canon_decomposition_second, [ord $c2, ord $c2];
  }
}

my $set_path = $root_path->child ('src/set/unicode');
print { $set_path->child ('has_canon_decomposition.expr')->openw }
    Charinfo::Set->serialize_set (\@has_canon_decomposition);
print { $set_path->child ('has_compat_decomposition.expr')->openw }
    Charinfo::Set->serialize_set (\@has_compat_decomposition);
print { $set_path->child ('canon_decomposition_second.expr')->openw }
    Charinfo::Set->serialize_set (\@canon_decomposition_second);

## License: Public Domain.
