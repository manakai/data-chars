use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use JSON::Functions::XS qw(perl2json_bytes_for_record file2perl);
use Unicode::Normalize qw(NFKC);
use Charinfo::Set;

my $maps = (file2perl file (__FILE__)->dir->parent->file ('data', 'maps.json'))->{maps};

my @set;

for my $c (0x0000..0x10FFFF) {
  my $d = NFKC chr $c;
  if (1 != length $d) {
    push @set, [$c => $c];
    next;
  }

  my $d_x = sprintf '%04X', ord $d;
  my $e = $maps->{'unicode:Case_Folding'}->{char_to_char}->{$d_x} ||
          $maps->{'unicode:Case_Folding'}->{char_to_seq}->{$d_x} ||
          $maps->{'unicode:Case_Folding'}->{char_to_empty}->{$d_x} ||
          $maps->{'unicode:Case_Folding'}->{seq_to_char}->{$d_x} ||
          $maps->{'unicode:Case_Folding'}->{seq_to_seq}->{$d_x} ||
          $maps->{'unicode:Case_Folding'}->{seq_to_empty}->{$d_x};
  next unless $e;
  $e = [split / /, $e];
  if (1 != @$e) {
    push @set, [$c => $c];
    next;
  }

  if ($c != hex $e->[0]) {
    push @set, [$c => $c];
    next;
  }

  my $f = NFKC chr hex $e->[0];
  if (1 != length $f) {
    push @set, [$c => $c];
    next;
  }

  if ($c != ord $f) {
    push @set, [$c => $c];
    next;
  }
}

print Charinfo::Set->serialize_set (Charinfo::Set::set_merge \@set, []);
