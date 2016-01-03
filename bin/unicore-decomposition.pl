use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;

my $unicode_version = shift or die;

my $root_path = path (__FILE__)->parent->parent;
my $input_ucd_path = $root_path->child ('local/unicode', $unicode_version);
my $output_perl_path = $root_path->child ('local/perl-unicode', $unicode_version);

my @entry;
{
  my $path = $input_ucd_path->child ('UnicodeData.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    chomp;
    my @d = split /;/, $_;

    unless ($d[5] eq '') {
      push @entry, sprintf "%s\t\t%s\n",
          $d[0], $d[5];
    }
  }
}

my $perldata_path = $output_perl_path->child ('lib');
$perldata_path->mkpath;
$perldata_path->child ('unicore-Decomposition.pl')->spew
    (join '',
         qq{<<'END'\n},
         (sort { $a cmp $b } @entry),
         qq{END\n});

## License: Public Domain.
