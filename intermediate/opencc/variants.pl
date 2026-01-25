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
  ['repo2', 'CNTradVariants.txt'],
  ['repo2', 'CNTradVariantsRev.txt'],
  ['repo2', 'HKVariants.txt'],
  ['repo2', 'HKVariantsRev.txt'],
  ['repo2', 'JPVariants.txt'],
  ['repo2', 'JPVariantsRev.txt'],
  ['repo2', 'TWVariants.txt'],
  ['repo2', 'TWVariantsRev.txt'],
  ['repo3', 'GSCharacters.txt'],
  ['repo3', 'SGCharacters.txt'],
) {
  my ($pname, $fname) = @$_;
  my $rel_type = "opencc:$fname";
  my $path = $TempPath->child ('repo/data', $pname, $fname);
  if ($pname eq 'repo2') {
    $path = $TempPath->child ('repo2', $fname);
    $rel_type = "starcc:$fname";
  } elsif ($pname eq 'repo3') {
    $path = $TempPath->child ('repo3/opencc', $fname);
    $rel_type = "gujicc:$fname";
  }
  $rel_type =~ s/\.txt$//;
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^([\w\x{30000}-\x{3FFFC}])\t((?:[\w\x{30000}-\x{3FFFC}])(?:\s+[\w\x{30000}-\x{3FFFC}])*)(?:$|\t)/) {
      my $c1 = $1;
      my $c2s = [split /\s+/, $2];
      die $c1 if not is_han $c1;
      for my $c2 (@$c2s) {
        die $c2 if not is_han $c2;
        $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1 unless $c1 eq $c2;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
