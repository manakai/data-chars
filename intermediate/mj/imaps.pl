use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' }

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iuc');
my $DataPath = $RootPath->child ('local/maps');

my $Data = {};

for (
  ['tensho-chars.txt', ':tensho-'],
  ['modmag-chars.txt', ':modmag-'],
  ['kuzushiji-chars.txt', ':kuzushiji-'],
) {
  my $prefix = $_->[1];
  my $path = $ThisPath->child ($_->[0]);
  for (split /\n/, $path->slurp_utf8) {
    if (/^(\S)$/) {
      my $c1 = u_chr ord $1;
      my $c3 = sprintf '%s%s', $prefix, $1;
      $Data->{glyphs}->{$c3}->{$c1}->{'codh:Unicode'} = 1;
    } elsif (/^(\S) (\S)$/) {
      my $c1 = u_chr ord $1;
      my $c2 = u_chr ord $2;
      my $c3 = sprintf '%s%s%s', $prefix, $1, $2;
      $Data->{glyphs}->{$c3}->{$c1}->{'codh:Unicode'} = 1;
      $Data->{glyphs}->{$c3}->{$c2}->{'codh:Unicode'} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

write_rel_data_sets
    $Data => $DataPath, 'imaps',
    [];

## License: Public Domain.
