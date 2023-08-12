use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;
BEGIN { require 'chars.pl' }
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwh');

my $Data = {};
for (
  ['alljoint.l'],
  ['jis3-0.l'],
  ['jis3-1.l'],
  ['jis3-2.l'],
  ['jis3-3.l'],
) {
  my $path = $TempPath->child ('wadalabfont-kit/jointdata/' . $_->[0]);
  my $file = $path->openr;
  my @item;
  while (<$file>) {
    if (m{^;}) {
      #
    } elsif (/^\(/) {
      push @item, $_;
    } elsif (/^\s.+\S\s*$/) {
      $item[-1] .= $_;
    } elsif (/\S/) {
      die $_;
    }
  }
  my $process_item;
  my $parse_name;
  $process_item = sub {
    my $item = shift;
    my @component;
    while (1) {
      $item =~ s{\((?:[xy]scale|change[xy]unit) [0-9.^+-]+ ([^()]*)\)}{$1}g && redo;
      unless ($item =~ s{\(\w+\s+([^()]+)\)}{
        push @component, $process_item->($1);
        ' ';
      }ge) {
        last;
      }
    }
    push @component, map { $parse_name->($_) } grep { length } split /\s+/, $item;
    return @component;
  };
  my $current;
  $parse_name = sub {
    my $s = shift;
    if ($s =~ /^([\xA1-\xFE])([\xA1-\xFE])$/) {
      return sprintf ':jis1-%d-%d', (ord $1) - 0xA0, (ord $2) - 0xA0;
    } elsif ($s =~ /^(?:[\xA1-\xFE][\xA1-\xFE])+$/) {
      return sprintf ':wadalab-%s', decode_web_charset 'euc-jp', $s;
    } elsif ($s =~ /^1-([0-9]+)-([0-9]+)$/) {
      return sprintf ':jis2-%d-%d', $1, $2;
    } else {
      die "Bad line |$current| (|$s|)";
    }
  };
  for (@item) {
    s/;.+$//;
    s/^(\(setq 1-58-31.+\)\))\)/$1/;
    if (/^\(setq\s+(\S+)\s*['`](.+)\)\s*$/s) {
      $current = $_;
      my $c1 = $parse_name->($1);
      my $s = $2;
      $s =~ s/^([\xA1-\xFE]+)\)$/$1/g;
      my @component = $process_item->($s);
      for my $c2 (@component) {
        $Data->{components}->{$c1}->{$c2}->{'wadalab:jointdata:contains'} = 1;
      }
    } else {
      die $_;
    }
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'components',
    [
    ];

## License: Public Domain.

