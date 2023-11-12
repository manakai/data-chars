use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/ijp');
my $Data = {};

{
  my $path = $TempPath->child ('hyougai.xml');
  my $n;
  for (split /\n/, $path->slurp_utf8) {
    if (m{<text top="(\d+)" left="(\d+)" width="\d+" height="\d+" font="([^"]+)">([^<>]*)</text>}) {
      my $top = $1;
      my $font = $3;
      my $text = $4;
      if ($font eq "3" and $text =~ /^([0-9]+)$/) {
        $n = sprintf '%d', $1;
        $Data->{jitai}->{$n}->{hyougai}->{no} = 0+$1;
      } elsif ($font eq "3" and $text =~ /^([0-9]+)\s+(\w+)$/) {
        $n = sprintf '%d', $1;
        $Data->{jitai}->{$n}->{hyougai}->{no} = 0+$1;
        $Data->{jitai}->{$n}->{hyougai}->{onkun} = $2;
      } elsif (($font eq 3 or $font eq 2 or $font eq 9) and
               $text =~ /^[\p{Hiragana}\p{Katakana}]+$/ and
               not defined $Data->{jitai}->{$n}->{hyougai}->{onkun}) {
        $Data->{jitai}->{$n}->{hyougai}->{onkun} = $text;
      } elsif ($font eq 3 and $text =~ /^\x{FF13}部首$/) {
        $Data->{jitai}->{$n}->{hyougai}->{bikou_3bushu} = 1;
      } elsif ($font eq 1 and $text =~ /^\x{FF13}部首\x{FF0C}$/) {
        $Data->{jitai}->{$n}->{hyougai}->{bikou_3bushu} = 1;
      } elsif (($font eq 5 or $font eq 14) and $text eq "\x{FF0A}") {
        $Data->{jitai}->{$n}->{hyougai}->{has_designsa} = 1
            unless $Data->{jitai}->{$n}->{hyougai}->{has_designsa_inhyou} or
            $Data->{jitai}->{$n}->{hyougai}->{has_designsa_kankan};
      } elsif ($font eq 11 and $text eq "＊靭,") {
        $Data->{jitai}->{$n}->{hyougai}->{has_designsa} = 1;
        $Data->{jitai}->{$n}->{hyougai}->{kobetsu_designsa1} = "靭";
      } elsif ($font eq 13 and $text eq "印標") {
        $Data->{jitai}->{$n}->{hyougai}->{has_designsa_inhyou} = 1;
      } elsif ($font eq 13 and $text eq "簡慣") {
        $Data->{jitai}->{$n}->{hyougai}->{has_designsa_kankan} = 1;
      } elsif ($font eq 12 and $text eq "&#34;") {
        $Data->{jitai}->{$n}->{hyougai}->{kobetsu_designsa2} = {font => 1};
      } elsif ($font eq 5) {
        if (defined $Data->{jitai}->{$n}->{hyougai}->{inhyou}) {
          if ($text =~ /^\x{FF0A}(\p{Han})$/) {
            if (defined $Data->{jitai}->{$n}->{hyougai}->{kobetsu_designsa}) {
              die $text;
            } else {
              $Data->{jitai}->{$n}->{hyougai}->{has_designsa} = $1;
              $Data->{jitai}->{$n}->{hyougai}->{kobetsu_designsa} = $1;
            }
          } else {
            if (defined $Data->{jitai}->{$n}->{hyougai}->{kankan}) {
              die $text;
            } else {
              $Data->{jitai}->{$n}->{hyougai}->{kankan} = $text;
            }
          }
        } else {
          $Data->{jitai}->{$n}->{hyougai}->{inhyou} = $text;
        }
      } elsif ($font eq 4 or $font eq 8 or $font eq 10) {
        if (defined $Data->{jitai}->{$n}->{hyougai}->{inhyou}) {
          if (defined $Data->{jitai}->{$n}->{hyougai}->{has_designsa}) {
            if (defined $Data->{jitai}->{$n}->{hyougai}->{kobetsu_designsa}) {
              die;
            } else {
              $Data->{jitai}->{$n}->{hyougai}->{kobetsu_designsa} = {font => 1};
            }
          } else {
            if (defined $Data->{jitai}->{$n}->{hyougai}->{kankan}) {
              die $_;
            } else {
              $Data->{jitai}->{$n}->{hyougai}->{kankan} = {font => 1};
            }
          }
        } else {
          $Data->{jitai}->{$n}->{hyougai}->{inhyou} = {font => 1};
        }
      } elsif (($font eq 7 or $font eq 3 or $font eq 15) and
               $text =~ /^(\w)は別字$/) {
        $Data->{jitai}->{$n}->{hyougai}->{bikou_betsuji} = $1;
      } elsif (($font eq 7 or $font eq 3 or $font eq 15) and
               $text =~ /^([0-9]+)とは別字扱い$/) {
        $Data->{jitai}->{$n}->{hyougai}->{bikou_betsuji_atsukai} = 0+$1;
      } elsif ($font eq 1 and $top eq 222) {
        #
      } elsif ($font eq 0 or $font eq 2 or $font eq 6) {
        #
      } elsif ($text =~ /^\s*$/) {
        #
      } else {
        die $_;
      }
    }
  }
}

print perl2json_bytes_for_record [sort { $a->{no} <=> $b->{no} } map { $_->{hyougai} } values %{$Data->{jitai}}];

## License: Public Domain.
