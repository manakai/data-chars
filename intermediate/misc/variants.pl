use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $Data = {};

sub ue ($) {
  my $s = shift;
  $s =~ s{\\u([0-9A-Fa-f]{4})}{chr hex $1}ge;
  $s =~ s{\\u\{([0-9A-Fa-f]+)\}}{chr hex $1}ge;
  return $s;
} # ue

{
  my $path = $RootPath->child ('src/han-variants.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^(\w+)\s+([\w\\\{\}\x{20000}-\x{3FFFF}]+)\s+([\w\\\{\}\x{20000}-\x{3FFFF}]+|:[\w\p{Ideographic_Description_Characters}-]+)\s*$/) {
      my $vtype = {
        sconflict => 'manakai:variant:simplifiedconflicted',
        conflict => 'manakai:variant:conflicted',
        related => 'manakai:related',
        overlap => 'manakai:variant',
        taboo => 'manakai:taboo',
        taboovariant => 'manakai:variant:taboo',
        simplified => 'manakai:variant:simplified',
        jpnewstyle => 'manakai:variant:jpnewstyle',
        differentiated => 'manakai:differentiated',
        variant => 'manakai:equivalent',
        same => 'manakai:same',
        unified => 'manakai:unified',
        wu => 'manakai:variant:wu',
        alt => 'manakai:alt',
        mistake => 'manakai:typo',
      }->{$1} // die "Bad type |$1|";
      $Data->{hans}->{ue $3}->{ue $2}->{$vtype} = 1;
    } elsif (/^(\w+)\s+([\w\\\{\}\x{20000}-\x{3FFFF}]+)\s+<-\s+(.+)$/) {
      my $vtype = {
        simplified => 'manakai:variant:simplified',
        jpnewstyle => 'manakai:variant:jpnewstyle',
        variant => 'manakai:equivalent',
      }->{$1} // die "Bad type |$1|";
      my $vtype2 = 'manakai:inset:original';
      my $c2 = ue $2;
      my @c3 = split /\s+/, ue $3;
      for my $c3 (@c3) {
        $Data->{hans}->{$c3}->{$c2}->{$vtype} = 1;
        $Data->{hans}->{$c3}->{$c2}->{$vtype2} = 1;
      }
      for my $c31 (@c3) {
        for my $c32 (@c3) {
          next if $c31 eq $c32;
          $Data->{hans}->{$c31}->{$c32}->{$vtype2} = 1;
        }
      }
    } elsif (m{^(vpairs)((?:\s+[\w\\\{\}\x{20000}-\x{3FFFF}]+/[\w\\\{\}\x{20000}-\x{3FFFF}]+)+)$}) {
      my $s = ue $2;
      my @s = map { [split m{/}, $_, 2] } grep { length } split /\s+/, $s;
      my $vtype2 = 'manakai:differentiated';
      for (@s) {
        my $c1 = $_->[0];
        for (@s) {
          my $c2 = $_->[1];
          $Data->{hans}->{$c1}->{$c2}->{$vtype2} = 1;
        }
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $RootPath->child ('src/doukun.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^([\p{sc=Hiragana};]+)\s+(\p{sc=Han}(?:\s+\p{sc=Han})+)$/) {
      my @s = split /\s+/, $2;
      for my $c1 (@s) {
        for my $c2 (@s) {
          $Data->{hans}->{$c1}->{$c2}->{'manakai:doukun'} = 1;
        }
      }
    } elsif (/\S/) {
      die $_;
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
