use strict;
use warnings;
no warnings 'utf8';
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;
use JSON::PS;
use Charinfo::Set;

my $unicode_version = shift or die;

my $root_path = path (__FILE__)->parent->parent;

{
  my $path = $root_path->child ('local/perl-unicode', $unicode_version, 'lib');
  unshift our @INC, $path->stringify;
  require UnicodeNormalize;
}

my $maps = (json_bytes2perl $root_path->child ('data/maps.json')->slurp)->{maps};

my @set;
my @set2;

for my $c (0x0000..0x10FFFF) {
  my $h = UnicodeNormalize::NFKC (chr $c);
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

  my $g = UnicodeNormalize::NFKC ($f);

  push @set, [$c => $c] unless $g eq chr $c;
  push @set2, [$c => $c] unless $h eq chr $c;
}

my $uv = $unicode_version eq 'latest' ? '' : '-' . $unicode_version;
my $uvd = $unicode_version eq 'latest' ? '' : ' (Unicode ' . $unicode_version . ')';

$root_path->child ("src/set/rfc5892$uv")->mkpath;
$root_path->child ("src/set/rfc7564$uv")->mkpath;
$root_path->child ("src/set/rfc5892$uv/Unstable.expr")->spew_utf8
    (join "\n", # toNFKC(toCaseFold(toNFKC(cp))) != cp
     '#label:Unstable'.$uvd,
     '#sw:Unstable',
     '#url:https://tools.ietf.org/html/rfc5892#section-2.2',
     Charinfo::Set->serialize_set (Charinfo::Set::set_merge \@set, []));
$root_path->child ("src/set/rfc7564$uv/HasCompat.expr")->spew_utf8
    (join "\n", # toNFKC(cp) != cp
     '#label:HasCompat'.$uvd,
     '#sw:HasCompat',
     '#url:https://tools.ietf.org/html/rfc7564#section-9.17',
     Charinfo::Set->serialize_set (Charinfo::Set::set_merge \@set2, []));

## License: Public Domain.
