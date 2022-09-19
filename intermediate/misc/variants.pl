use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;

sub ue ($) {
  my $s = shift;
  $s =~ s{\\u([0-9A-Fa-f]{4})}{chr hex $1}ge;
  $s =~ s{\\u\{([0-9A-Fa-f]+)\}}{chr hex $1}ge;
  return $s;
} # ue

my $Data;
{
  my $path = $ThisPath->child ('aggregated.json');
  my $json = json_bytes2perl $path->slurp;
  $Data = $json;
}

{
  my $path = $RootPath->child ('data/maps.json');
  my $json = json_bytes2perl $path->slurp;

  my $vtype = 'unicode:canonical-decomposition';
  my $map = $json->{maps}->{"unicode:canon_decomposition"};
  for my $key (keys %{$map->{char_to_char}}) {
    my $cc = hex $key;
    if (0xF900 <= $cc and $cc <= 0xFAFF or
        0x20000 <= $cc and $cc <= 0x2FFFF) {
      $Data->{variants}->{chr $cc}->{chr hex $map->{char_to_char}->{$key}}->{$vtype} = 1;
    }
  }
}

{
  my $path = $RootPath->child ('data/sets.json');
  my $json = json_bytes2perl $path->slurp;
  for (
    ['$kanji:jouyou-1981' => 'jouyou_s56'],
    ['$kanji:jimmei-1997' => 'jinmei_h9'],
  ) {
    my ($key1, $key2) = @$_;
    my $chars = $json->{sets}->{$key1}->{chars};
    $chars =~ s/^\[//;
    $chars =~ s/\]$//;
    while ($chars =~ s/^\\u([0-9A-F]{4}|\{[0-9A-F]+\})//) {
      my $v1 = $1;
      $v1 =~ s/^\{//;
      $v1 =~ s/\}$//;
      my $cc1 = hex $v1;
      my $cc2 = $cc1;
      if ($chars =~ s/^-\\u([0-9A-F]{4}|\{[0-9A-F]+\})//) {
        my $v2 = $1;
        $v2 =~ s/^\{//;
        $v2 =~ s/\}$//;
        $cc2 = hex $v2;
      }
      for ($cc1..$cc2) {
        $Data->{sets}->{$key2}->{chr $_} = 1;
      }
    }
    die $chars if length $chars;
  }
}

{
  my $path = $RootPath->child ('src/han-variants.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^(\w+)\s+([\w\\\{\}\x{20000}-\x{3FFFF}]+)\s+([\w\\\{\}\x{20000}-\x{3FFFF}]+)\s*$/) {
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
      }->{$1} // die "Bad type |$1|";
      $Data->{variants}->{ue $3}->{ue $2}->{$vtype} = 1;
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
        $Data->{variants}->{$c3}->{$c2}->{$vtype} = 1;
        $Data->{variants}->{$c3}->{$c2}->{$vtype2} = 1;
      }
      for my $c31 (@c3) {
        for my $c32 (@c3) {
          next if $c31 eq $c32;
          $Data->{variants}->{$c31}->{$c32}->{$vtype2} = 1;
        }
      }
    } elsif (m{^(vpairs)((?:\s+[\w\\\{\}\x{20000}-\x{3FFFF}]+/[\w\\\{\}\x{20000}-\x{3FFFF}]+)+)$}) {
      my $s = ue $2;
      my @s = map { [split m{/}, $_, 2] } grep { length } split /\s+/, $s;
      my $vtype2 = 'manakai:variant:conflicted';
      for (@s) {
        my $c1 = $_->[0];
        for (@s) {
          my $c2 = $_->[1];
          $Data->{variants}->{$c1}->{$c2}->{$vtype2} = 1;
        }
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
