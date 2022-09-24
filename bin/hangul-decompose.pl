use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::Encoding::Normalization;

print "#label:Decompose Hangul Syllables\n";
print "#sw:Hangul syllable\n";
for (0xAC00..0xD7A3) {
  printf "\\u{%04X} -> ", $_;
  print join '', map { sprintf '\\u{%04X}', ord $_ } split //, to_nfd chr $_;
  print "\x0A";
}

## License: Public Domain.
