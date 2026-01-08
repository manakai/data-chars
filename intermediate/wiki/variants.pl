use strict;
use warnings;
use utf8;
use Path::Tiny;
use Web::Encoding;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');

my $Data = {};

sub extract_source ($) {
  my $html = $_[0];
  $html =~ s{^.+<textarea[^<>]*>}{}s;
  $html =~ s{</textarea>.*$}{}s;
  $html =~ s/&lt;/</g;
  $html =~ s/&amp;/&/g;

  $html = decode_web_utf8 $html;
  $html =~ s/&#x([0-9a-f]+);/chr hex $1/ge;
  $html =~ s/&#([0-9]+);/chr $1/ge;
  return $html;
} # extract_source

for (
  ['list1.html', 5],
  ['list2.html', 5],
) {
  my ($fname, $index) = @$_;
  my $path = $TempPath->child ($fname);
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
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

  my $wiki = extract_source $path->slurp;
  for (split /\x0D?\x0A/, $wiki) {
    if (/^\|\s*\p{sc=Hangul}\s*\|\|(.+)$/) {
      my $s = $1;
      for my $c (grep { length } split /[|,\s]/, $s) {
        my $d = $c;
        $d =~ s<\{\{.+?\}\}><>g;
        for (split //, $d) {
          $Data->{sets}->{kredu}->{$_} = 1;
        }
      }
    }
  }
  $wiki =~ s{\x0A\|\s*(\w(?:,\s*\w)+)\x0A\|\s*(\w(?:,\s*\w)+)\x0A}{
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

{
  my $path = $ThisPath->child ('hyougai.txt');
  my $text = decode_web_utf8 $path->slurp;

  $text =~ s{^#.*}{}gm;
  while ($text =~ m{(\w)}g) {
    my $c = $1;
    $Data->{sets}->{hyougai}->{$c} = 1;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
