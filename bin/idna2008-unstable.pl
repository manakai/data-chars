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
  my $d = [map { sprintf '%04X', ord $_ } split //, NFKC chr $c];

  my $e = join ' ', map {
    $maps->{'unicode:Case_Folding'}->{char_to_char}->{$_} //
    $maps->{'unicode:Case_Folding'}->{char_to_seq}->{$_} //
    $maps->{'unicode:Case_Folding'}->{char_to_empty}->{$_} //
    $maps->{'unicode:Case_Folding'}->{seq_to_char}->{$_} //
    $maps->{'unicode:Case_Folding'}->{seq_to_seq}->{$_} //
    $maps->{'unicode:Case_Folding'}->{seq_to_empty}->{$_} // $_;
  } @$d;
  my $f = join '', map { chr hex $_ } split / /, $e;

  my $g = NFKC $f;

  unless ($g eq chr $c) {
    push @set, [$c => $c];
  }
}

print Charinfo::Set->serialize_set (Charinfo::Set::set_merge \@set, []);

## License: Public Domain.
