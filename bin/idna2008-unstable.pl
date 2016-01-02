use strict;
use warnings;
no warnings 'utf8';
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;
use lib glob path (__FILE__)->parent->parent->child ('local/perl-unicode/lib')->stringify;
use JSON::PS;
use Unicode::Normalize qw(NFKC);
use Charinfo::Set;

my $root_path = path (__FILE__)->parent->parent;

my $maps = (json_bytes2perl $root_path->child ('data/maps.json')->slurp)->{maps};

my @set;
my @set2;

for my $c (0x0000..0x10FFFF) {
  my $h = NFKC chr $c;
  my $d = [map { sprintf '%04X', ord $_ } split //, $h];

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

  push @set, [$c => $c] unless $g eq chr $c;
  push @set2, [$c => $c] unless $h eq chr $c;
}

$root_path->child ('src/set/rfc5892/Unstable.expr')->spew_utf8
    (join "\n",
     '#label:Unstable', # toNFKC(toCaseFold(toNFKC(cp))) != cp
     '#url:https://tools.ietf.org/html/rfc5892#section-2.2',
     Charinfo::Set->serialize_set (Charinfo::Set::set_merge \@set, []));
$root_path->child ('src/set/rfc7564/HasCompat.expr')->spew_utf8
    (join "\n",
     '#label:HasCompat', # toNFKC(cp) != cp
     '#url:https://tools.ietf.org/html/rfc7564#section-9.17',
     Charinfo::Set->serialize_set (Charinfo::Set::set_merge \@set2, []));

## License: Public Domain.
