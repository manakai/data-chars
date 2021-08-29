use strict;
use warnings;
use Path::Tiny;
use Web::Encoding;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');

my $Data = {};

for (
  ['list1.html', 5],
  ['list2.html', 5],
) {
  my ($fname, $index) = @$_;
  my $path = $TempPath->child ($fname);
  my $html = decode_web_utf8 $path->slurp;
  $html =~ s{^.+<textarea[^<>]*>}{}s;
  $html =~ s{</textarea>.*$}{}s;

  for (split /\x0D?\x0A/, $html) {
    if (/^\|/) {
      my @line = split /\|/, $_, -1;
      next unless @line > $index;
      die $_ unless $line[$index] =~ /^[0-9A-Fa-f]+$/;
      my $c = chr hex $line[$index];
      $Data->{sets}->{tw}->{$c} = 1;
    }
  }
}

for (
  ['kredu.html'],
) {
  my ($fname) = @$_;
  my $path = $TempPath->child ($fname);
  my $html = decode_web_utf8 $path->slurp;
  $html =~ s{^.+<textarea[^<>]*>}{}s;
  $html =~ s{</textarea>.*$}{}s;

  for (split /\x0D?\x0A/, $html) {
    if (/^\|\s*\p{Hangul}\s*\|\|(.+)$/) {
      my $s = $1;
      for my $c (grep { length } split /[|,\s]/, $s) {
        $Data->{sets}->{kredu}->{$c} = 1;
      }
    }
  }
  $html =~ s{\x0A\|\s*(\w(?:,\s*\w)+)\x0A\|\s*(\w(?:,\s*\w)+)\x0A}{
    my $l1 = $1;
    my $l2 = $2;

    while ($l1 =~ m{(\w+)}g) {
      $Data->{sets}->{kredu_deleted}->{$1} = 1;
    }
    while ($l2 =~ m{(\w+)}g) {
      $Data->{sets}->{kredu_added}->{$1} = 1;
    }
  }e;
  
  $Data->{stats}->{kredu} = 0+keys %{$Data->{sets}->{kredu}};
  $Data->{stats}->{kredu_added} = 0+keys %{$Data->{sets}->{kredu_added}};
  $Data->{stats}->{kredu_deleted} = 0+keys %{$Data->{sets}->{kredu_deleted}};
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
