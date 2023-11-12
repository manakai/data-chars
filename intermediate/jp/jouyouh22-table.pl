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
  my $path = $TempPath->child ('jouyouh22.xml');
  my $mode = 0;
  my $char;
  my $i = 0;
  for (split /\n/, $path->slurp_utf8) {
    if (m{>本　　　表<}) {
      $mode = 1;
    } elsif ($mode == 1 and m{<text top="\d+" left="([0-9]+)" width="\d+" height="\d+" font="37">\s*(\p{Han})\s*</text>}) {
      if ($1 < 200) {
        $char = $2;
        $Data->{jouyou}->{$char}->{index} = ++$i;
      } else {
        push @{$Data->{jouyou}->{$char}->{old} ||= []}, $2;
      }
    } elsif ($mode == 1 and m{<text top="\d+" left="([0-9]+)" width="\d+" height="\d+" font="37">\s*(\p{Han})\s+(\p{Han})\s*</text>}) {
      $char = $2;
      $Data->{jouyou}->{$char}->{index} = ++$i;
      push @{$Data->{jouyou}->{$char}->{old} ||= []}, $3;
    } elsif ($mode == 1 and m{<text top="\d+" left="([0-9]+)" width="\d+" height="\d+" font="39">\s*(\p{Han})\s*</text>}) {
      push @{$Data->{jouyou}->{$char}->{old} ||= []}, $2;
    } elsif ($mode == 1 and m{<text top="\d+" left="([0-9]+)" width="\d+" height="\d+" font="37">\s*（(\p{Han})）\s*</text>}) {
      push @{$Data->{jouyou}->{$char}->{old} ||= []}, $2;
    } elsif ($mode == 1 and m{<text top="\d+" left="([0-9]+)" width="\d+" height="\d+" font="40">\s*［(\p{Han})］\s*</text>}) {
      push @{$Data->{jouyou}->{$char}->{kyoyou} ||= []}, {text => $2, font => 1};
    } elsif ($mode == 1 and m{>[（）]\s*<}) {
      #
    } elsif ($mode == 1 and m{<text top="\d+" left="([0-9]+)" width="\d+" height="\d+" font="37">\s*（\s*）\s*</text>}) {
      $Data->{jouyou}->{$char}->{old_image} = 1;
    } elsif ($mode == 1 and m{<text top="\d+" left="(?:257|260)" width="\d+" height="\d+" font="36">([\p{Hiragana}\p{Katakana}]+)\s*</text>}) {
      push @{$Data->{jouyou}->{$char}->{lines} ||= []}, {onkun => $1};
    } elsif ($mode == 1 and m{<text top="\d+" left="(?:239)" width="\d+" height="\d+" font="36">\s+([\p{Hiragana}\p{Katakana}]+)\s*</text>}) {
      push @{$Data->{jouyou}->{$char}->{lines} ||= []}, {onkun => $1};
    } elsif ($mode == 1 and m{<text top="\d+" left="(?:257|260)" width="\d+" height="\d+" font="36">\s([\p{Hiragana}\p{Katakana}]+)\s*</text>}) {
      push @{$Data->{jouyou}->{$char}->{lines} ||= []}, {onkun => $1, onkun_indented => 1};
    } elsif ($mode == 1 and m{<text top="\d+" left="(?:257|260)" width="\d+" height="\d+" font="36">([\p{Hiragana}\p{Katakana}]+)\s+(\S.*\S)\s*</text>}) {
      push @{$Data->{jouyou}->{$char}->{lines} ||= []}, {onkun => $1, rei => [$2]};
    } elsif ($mode == 1 and m{<text top="\d+" left="(?:368|371)" width="\d+" height="\d+" font="36">(\S.*\S|\S)\s*</text>}) {
      die "|$char|, |$_|", perl2json_bytes $Data->{jouyou}->{$char}
          unless @{$Data->{jouyou}->{$char}->{lines} or []};
      push @{$Data->{jouyou}->{$char}->{lines}->[-1]->{rei} ||= []}, $1;
    } elsif ($mode == 1 and m{<text top="\d+" left="(?:596|599|6[0-5][0-9]|670|680|733|749|753|756)" width="\d+" height="\d+" font="36">(\S.*\S|\S)\s*</text>}) {
      die $_ unless @{$Data->{jouyou}->{$char}->{lines} or []};
      push @{$Data->{jouyou}->{$char}->{lines}->[-1]->{bikou} ||= []}, $1;
    } elsif ($mode == 1 and m{<text top="\d+" left="(?:612|615)" width="\d+" height="\d+" font="41">(\S.*\S|\S)\s*</text>}) {
      push @{$Data->{jouyou}->{$char}->{lines}->[-1]->{bikou} ||= []},
          {text => $1, font => 1};
    } elsif ($mode == 1 and m{>163<}) {
      $mode = 2;
    } elsif ($mode == 2 and m{font="36">(\p{Hiragana}+)\s*</text>}) {
      $char = $Data->{fuhyou}->{$1}->{yomikata} = $1;
    } elsif ($mode == 2 and m{font="36">(\p{Hiragana}*\p{Han}[\p{Hiragana}\p{Han}]+)\s*</text>}) {
      $Data->{fuhyou}->{$char}->{word} = $1;
    } elsif ($mode == 2 and m{font="45">(\S.*\S)\s*</text>}) {
      $Data->{fuhyou}->{$char}->{note} = $1;
    } elsif ($mode == 1 and m{left="124"|left="140"|left="(?:769|784|8[0-5][0-9])"}) {
      #
    } elsif ($mode == 1 and m{<text top="264"|left="70"}) {
      #
    } elsif ($mode == 2 and m{font="(?:34|38|43|44)"}) {
      #
    } elsif ($mode and m{>\s*<|</page>|<page|<fontspec|</pdf2xml>}) {
      #
    } elsif ($mode and /\S/) {
      die $_;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
