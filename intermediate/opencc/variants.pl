use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;
BEGIN { require 'chars.pl' }

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/ioc');

my $Data = {};

for (
  ['dictionary', 'HKVariants.txt'],
  ['dictionary', 'JPShinjitaiCharacters.txt'],
  ['dictionary', 'JPVariants.txt'],
  ['dictionary', 'STCharacters.txt'],
  ['dictionary', 'TSCharacters.txt'],
  ['dictionary', 'TWVariants.txt'],
  ['scheme', 'st_multi.txt'],
  ['scheme', 'ts_multi.txt'],
  ['scheme', 'variant.txt'],
) {
  my ($pname, $fname) = @$_;
  my $rel_type = "opencc:$fname";
  $rel_type =~ s/\.txt$//;
  my $path = $TempPath->child ('repo/data', $pname, $fname);
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^([\w\x{30000}-\x{3FFFC}])\t((?:[\w\x{30000}-\x{3FFFC}])(?:\s+[\w\x{30000}-\x{3FFFC}])*)(?:$|\t)/) {
      my $c1 = $1;
      my $c2s = [split /\s+/, $2];
      die $c1 if not is_han $c1;
      for my $c2 (@$c2s) {
        die $c2 if not is_han $c2;
        $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
