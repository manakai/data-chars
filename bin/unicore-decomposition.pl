use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;

my @entry;
{
  my $f = file (__FILE__)->dir->parent->file ('local', 'unicode', 'latest', 'UnicodeData.txt');
  for (($f->slurp)) {
    chomp;
    my @d = split /;/, $_;

    unless ($d[5] eq '') {
      push @entry, sprintf "%s\t\t%s\n",
          $d[0], $d[5];
    }
  }
}

my $perldata_d = file (__FILE__)->dir->parent->subdir ('local', 'perl-unicode', 'lib', 'unicore');
$perldata_d->mkpath;
print { $perldata_d->file ('Decomposition.pl')->openw }
    qq{<<'END'\n},
    (sort { $a cmp $b } @entry),
    qq{END\n};

## License: Public Domain.
