use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');
my $Data = {};

{
  for (0x3400..0x4DB5, 0x4E00..0x9FA5) {
    my $c1 = u_chr $_;
    my $c2 = sprintf ':u-gbdot16-%x', $_;
    $Data->{glyphs}->{$c2}->{$c1}->{'manakai:implements:gb18030'} = 1;
  }
}

print_rel_data $Data;

## License: Public Domain.
