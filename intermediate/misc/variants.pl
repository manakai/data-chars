use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');
my $Data = {};

sub ue ($) {
  my $s = shift;
  if ($s =~ m{^\\(.)$}) {
    return $1;
  } elsif ($s =~ m{^"([^"\\]+)"$}) {
    return $1;
  } elsif ($s =~ m{^'([^'\\]+)'$}) {
    return $1;
  }
  $s =~ s{\\u([0-9A-Fa-f]{4})}{chr hex $1}ge;
  $s =~ s{\\u\{([0-9A-Fa-f]+)\}}{chr hex $1}ge;
  if (1 == length $s) {
    return u_chr ord $s;
  }
  return $s;
} # ue

sub private ($) {
  my $c = shift;
  if ($c =~ /^:jis-pubrev-(.+)$/) {
    my $c0 = ':jis' . $1;
    $Data->{codes}->{$c0}->{$c}->{'manakai:private'} = 1;
  }
} # private

{
  my $path = $RootPath->child ('src/han-variants.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^(\w+)\s+([\w\\\{\}\x{20000}-\x{3FFFF}]+|:[\w\p{Ideographic_Description_Characters}-]+)\s+([\w\\\{\}\x{20000}-\x{3FFFF}]+|:[\w\p{Ideographic_Description_Characters}-]+)\s*$/) {
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
        ids => 'manakai:ids',
      }->{$1} // die "Bad type |$1|";
      my $key = 'hans';
      $key = 'idses' if $vtype eq 'manakai:ids';
      $Data->{$key}->{ue $3}->{ue $2}->{$vtype} = 1;
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
      die "$path: Bad line |$_|";
    }
  }
}


{
  my $path = $RootPath->child ('src/other-variants.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^(\w+)\s+([\w\\\{\}\x{20000}-\x{3FFFF}]+|(?>:[\w\p{Ideographic_Description_Characters}-]+)+|\\.|"[^"]+"|'[^']+')\s+([\w\\\{\}\x{20000}-\x{3FFFF}]+|(?>:[\w\p{Ideographic_Description_Characters}-]+)+|\\.|"[^"]+"|'[^']+')\s*$/) {
      my $vtype = {
        related => 'manakai:related',
        differentiated => 'manakai:differentiated',
        variant => 'manakai:equivalent',
        same => 'manakai:same',
        unified => 'manakai:unified',
        alt => 'manakai:alt',
        mistake => 'manakai:typo',
        ne => 'manakai:ne',
        small => 'manakai:small',
        oblique => 'manakai:oblique',
        ligature => 'manakai:ligature',
        rev => 'manakai:revision',
        dotless => 'manakai:dotless',
        lookslike => 'manakai:lookslike',
      }->{$1} // die "Bad type |$1|";
      my $t = $1;
      my $c1 = ue $3;
      my $c2 = ue $2;
      my $key = get_vkey $c2;
      $key = 'kanas' if $c1 =~ /^:u-jitaichou-/;
      $Data->{$key}->{$c1}->{$c2}->{$vtype} = 1;
      private $c1;
      private $c2;
      if ($t eq 'variant' and
          1 == length $c1 and 1 == length $c2 and
          is_kana $c1 > 0 and is_kana $c2 > 0) {
        $Data->{$key}->{$c1."\x{3099}"}->{$c2."\x{3099}"}->{$vtype} = 1;
        $Data->{$key}->{$c1."\x{309A}"}->{$c2."\x{309A}"}->{$vtype} = 1;
      }
    } elsif (/^T1-([0-9A-F]{2})([0-9A-F]{2})\s+U\+([0-9A-F]+),U\+([0-9A-F]+)$/) {
      my $c1 = sprintf ':cns1-%d-%d', (hex$1)-0x20, (hex$2)-0x20;
      my $c2 = (chr hex $3) . (chr hex $4);
      my $key = get_vkey $c2;
      my $vtype = 'manakai:related';
      $Data->{$key}->{$c1}->{$c2}->{$vtype} = 1;
    } elsif (m{^differentiated\s+(\S.+\S|\w)\s*/\s*(\S.+\S|\w)\s*<-\s*(\S.+\S|\w)\s*$}) {
      my $_c1 = $1;
      my $_c2 = $2;
      my $_c3 = $3;
      my $key;
      my @c1 = map { ue $_ } split /\s+/, $_c1;
      my @c2 = map { ue $_ } split /\s+/, $_c2;
      my @c3 = map { ue $_ } split /\s+/, $_c3;
      for my $c (@c1, @c2) {
        $key //= get_vkey $c;
        for my $c3 (@c3) {
          $Data->{$key}->{$c}->{$c3}->{'manakai:hasspecialized'} = 1;
        }
      }
    } elsif (m{^conflict\s+(\S.+\S|\w)\s*<-\s*(\S.+\S|\w)\s*/\s*(\S.+\S|\w)\s*$}) {
      my $_c1 = $1;
      my $_c2 = $2;
      my $_c3 = $3;
      my $key;
      my @c1 = map { ue $_ } split /\s+/, $_c1;
      my @c2 = map { ue $_ } split /\s+/, $_c2;
      my @c3 = map { ue $_ } split /\s+/, $_c3;
      for my $c (@c1) {
        $key //= get_vkey $c;
        for my $c3 (@c2, @c3) {
          $Data->{$key}->{$c}->{$c3}->{'manakai:variant:conflicted'} = 1;
        }
      }
    } elsif (m{^origin\s+(\S.+\S|\w)\s*<-\s*(\S.+\S|\w)\s*$}) {
      my $_c1 = $1;
      my $_c2 = $2;
      my $key;
      my @c1 = map { ue $_ } split /\s+/, $_c1;
      my @c2 = map { ue $_ } split /\s+/, $_c2;
      for my $c1 (@c1) {
        $key //= get_vkey $c1;
        for my $c2 (@c2) {
          $Data->{$key}->{$c1}->{$c2}->{'kana:origin:variant'} = 1;
        }
      }
    } elsif (/\S/) {
      die "$path: Bad line |$_|";
    }
  }
}

{
  my $path = $RootPath->child ('src/doukun.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^([\p{sc=Hiragana};]+)\s+(\p{sc=Han}(?:\s+\p{sc=Han}+)+)$/) {
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
{
  my $path = $ThisPath->child ('kakekotoba.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^([\p{sc=Hiragana};]+)\s+(\p{sc=Han}(?:\s+\p{sc=Han})+)$/) {
      my @s = split /\s+/, $2;
      for my $c1 (@s) {
        for my $c2 (@s) {
          $Data->{hans}->{$c1}->{$c2}->{'manakai:kakekotoba'} = 1;
        }
      }
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $ThisPath->child ('engo.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^(\p{sc=Han})\s+(\p{sc=Han})$/) {
      $Data->{hans}->{$1}->{$2}->{'manakai:engo'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('dict.ts');
  my $text = $path->slurp_utf8;
  $text =~ /^const JIS_OLD_KANJI = '([^']+)'/m or die;
  my $old = $1;
  $text =~ /^const JIS_NEW_KANJI = '([^']+)'/m or die;
  my $new = $1;
  my @old = split /,/, $old;
  my @new = split /,/, $new;
  for (0..$#old) {
    my $c1 = $old[$_];
    my $c2 = $new[$_];
    $Data->{hans}->{$c1}->{$c2}->{'geolonia:oldnew'} = 1;
  }
}

for my $c1 (keys %{$Data->{variants}}) {
  delete $Data->{variants}->{$c1}->{$c1};
  delete $Data->{variants}->{$c1} unless keys %{$Data->{variants}->{$c1}};
}
for my $c1 (keys %{$Data->{hans}}) {
  delete $Data->{hans}->{$c1}->{$c1};
  delete $Data->{hans}->{$c1} unless keys %{$Data->{hans}->{$c1}};
}

print_rel_data $Data;

## License: Public Domain.
