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
  ['nan-1.html', 'wikipedia:zh:臺閩字列表:異用字 / 俗字', undef],
  ['nan-2.html', 'wikipedia:zh:臺語本字列表:異用字 / 俗字', undef],
  ['nan-3.html', undef, 'wikipedia:zh:歌仔冊文字'],
) {
  my ($fname, $rel_type1, $rel_type2) = @$_;
  my $path = $TempPath->child ($fname);

  my $i = -"Inf";
  my $c1;
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (/^\|-/) {
      $i = 0;
      undef $c1;
    } elsif (/^\|/) {
      $i++;
      s{<ref[^<>]*>.*?</ref>}{}g;
      s{<ref[^<>]*/>}{}g;
      s{-\{(\w)\}-}{$1}g;
      if ($i == 1) {
        if (/^\|\s*(\p{sc=Han}+)\s*$/) {
          $c1 = $1;
        } else {
          undef $c1;
        }
      } elsif ($i == 2) {
        if (defined $c1 and /^\|\s*(\p{sc=Han}+(?:、\p{sc=Han}+)*)\s*$/) {
          my @c2 = split /、/, $1;
          if (1 == length $c1) {
            for my $c2 (@c2) {
              if (defined $rel_type1 and 1 == length $c2) {
                $Data->{hans}->{$c1}->{$c2}->{$rel_type1} = 1;
              }
              if (defined $rel_type2 and 1 == length $c2) {
                $Data->{hans}->{$c2}->{$c1}->{$rel_type2} = 1;
              }
            }
          } elsif (2 == length $c1) {
            my @c = grep { 2 == length $_ } ($c1, @c2);
            for my $c1 (@c) {
              for my $c2 (@c) {
                if (substr ($c1, 0, 1) eq substr ($c2, 0, 1)) {
                  $Data->{hans}->{substr $c1, 1, 1}->{substr $c2, 1, 1}->{'manakai:related'} = 1;
                } elsif (substr ($c1, 1, 1) eq substr ($c2, 1, 1)) {
                  $Data->{hans}->{substr $c1, 0, 1}->{substr $c2, 0, 1}->{'manakai:related'} = 1;
                }
              }
            }
          }
        } else {
          undef $c1;
        }
      }
    }
  }
}

for (
  ['gb12052.html', 0xA, ':gb20', 'csw:mapping:gb12052'],
  ['ksx1002.html', 0x2, ':ks1', 'csw:mapping:ksx1002'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $prefix = $_->[2];
  my $rel_type = $_->[3];
  my $delta = $_->[1];
  for (split /\x0D?\x0A/, extract_source $path->slurp) {
    if (s/^\|([2-7A-F][0-9A-F])([0-9A-F])\|\|//) {
      my $ku = (hex $1) - ($delta * 0x10);
      my $ten = ((hex $2) - $delta) * 0x10;
      my @v = split /\|\|/, $_;
      for my $s (@v) {
        my $x = $s =~ s{^([^|]*)\|\s*}{} ? $1 : '';
        if (length $s) {
          $s =~ s{<nowiki></nowiki>}{}g;
          unless (1 == length $s or 2 == length $s) {
            if ($s eq q{<sup>O</sup><small>U</small><sub>T</sub>}) {
              $s = ':csw:' . $s;
            } elsif ($s =~ m{^\{\{옛한글\|(\p{Hang}+)\}\}$}) {
              $s = $1;
            } else {
              die "($x) ($s) " . (length $s);
            }
          }
          #warn sprintf "%d-%d (%s)\n", $ku, $ten, $s;
          my $c1 = sprintf '%s-%d-%d', $prefix, $ku, $ten;
          my $c2 = $s;
          my $key = 'variants';
          $key = 'hans' if is_han $c2 > 0;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
        }
        $ten++;
      }
    }
  }
  ## gb20-71-41 - gb20-71-64 "Hunminjeongeum Haerye style" variant
}

{
  my $path = $ThisPath->child ('doukun.txt');
  my $text = decode_web_utf8 $path->slurp;
  $text =~ s{^#.*}{}gm;
  for (split /\x0A/, $text) {
    if (/^\s*#/) {
      #
    } elsif (/^(\p{sc=Hiragana}+)：(.+)$/) {
      my $s = $2;
      $s =~ s/（[^（）]+）//g;
      my @s;
      for (split /[・；、]/, $s) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
      for my $c1 (@s) {
        for my $c2 (@s) {
          next if $c1 eq $c2;
          $Data->{hans}->{$c1}->{$c2}->{'wikipedia:ja:同訓異字'} = 1;
        }
      }
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $ThisPath->child ('gbk.txt');
  my $text = decode_web_utf8 $path->slurp;
  $text =~ s{^#.*}{}gm;
  for (split /\x0A/, $text) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s.*U\+([0-9A-F]+)\s.*$/) {
      my $c1 = chr hex $1;
      my $c2 = chr hex $2;
      my $c1_0 = $c1;
      $c1 = sprintf ':u-gb-%x', ord $c1;
      my $key = 'variants';
      $key = 'hans' if hex $1 >= 0xE800;
      $Data->{$key}->{$c1}->{$c2}->{'manakai:same'} = 1;
      $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  for my $c1 (keys %{$Data->{hans}}) {
    for my $c2 (keys %{$Data->{hans}->{$c1}}) {
      delete $Data->{hans}->{$c1}->{$c2} if $c1 eq $c2;
    }
    delete $Data->{hans}->{$c1} unless keys %{$Data->{hans}->{$c1}};
  }
}

print_rel_data $Data;

## License: Public Domain.
