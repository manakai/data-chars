use strict;
use warnings;
use Path::Tiny;
use Web::Encoding;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/ijp');

my $Data = {};

{
  my $path = $ThisPath->child ('doukun-s47.txt');
  my @s = ();
  my $emit = sub {
    return unless @s;

    #warn "<@s>\n";
    use utf8;
    for my $c1 (@s) {
      for my $c2 (@s) {
        next if $c1 eq $c2;
        $Data->{hans}->{$c1}->{$c2}->{'jp:「異字同訓」の漢字の用法'} = 1;
      }
    }
  }; # $emit

  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    use utf8;
    if (/^\s*#/) {
      #
    } elsif (/^\p{sc=Hiragana}+(?:・\p{sc=Hiragana}+)*$/) {
      $emit->();
      @s = ();
    } elsif (/^([\w・]+)－/) {
      for (split /・/, $1) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
    } elsif (/^(?:[\w（）]+。)*$/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  } # lines
  $emit->();
}

{
  my $path = $ThisPath->child ('doukun-h22.txt');
  my @s = ();
  my $emit = sub {
    return unless @s;

    #warn "<@s>\n";
    use utf8;
    for my $c1 (@s) {
      for my $c2 (@s) {
        next if $c1 eq $c2;
        $Data->{hans}->{$c1}->{$c2}->{'jp:「異字同訓」の漢字の用法例'} = 1;
      }
    }
  }; # $emit

  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    use utf8;
    if (/^\s*#/) {
      #
    } elsif (/^\p{sc=Hiragana}+(?:・\p{sc=Hiragana}+)*$/) {
      $emit->();
      @s = ();
    } elsif (/^([\w・]+)\s*\Q......\E/) {
      for (split /・/, $1) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
    } elsif (/^(?:[\w（）]+。)*$/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  } # lines
  $emit->();
}

{
  my $path = $ThisPath->child ('doukun-h26.txt');
  my @s = ();
  my $emit = sub {
    return unless @s;

    #warn "<@s>\n";
    use utf8;
    for my $c1 (@s) {
      for my $c2 (@s) {
        next if $c1 eq $c2;
        $Data->{hans}->{$c1}->{$c2}->{'jp:「異字同訓」の漢字の使い分け例'} = 1;
      }
    }
  }; # $emit

  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    use utf8;
    if (/^\s*#/) {
      #
    } elsif (/^[０-９]+\s*\p{sc=Hiragana}+(?:・\p{sc=Hiragana}+)*（(\w(?:・\w)+)）$/) {
      for (split /・/, $1) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
      $emit->();
      @s = ();
    } elsif (/^[０-９]+\s*\p{sc=Hiragana}+(?:・\p{sc=Hiragana}+)*（(\w(?:・\w)+)）\s*[０-９]+\s*\p{sc=Hiragana}+(?:・\p{sc=Hiragana}+)*（(\w(?:・\w)+)）$/) {
      my $v2 = $2;
      for (split /・/, $1) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
      $emit->();
      
      @s = ();
      for (split /・/, $v2) {
        s/\p{sc=Hiragana}+$//;
        die $_ unless is_han $_;
        push @s, $_;
      }
      $emit->();
      @s = ();
    } elsif (/\S/) {
      die $_;
    }
  } # lines
  $emit->();
}

{
  my $path = $TempPath->child ('nyukanseiji.json');
  my $json = json_bytes2perl $path->slurp;
  use utf8;
  for (@{$json->{table4_1}}) {
    my $c1 = chr hex $_->[0];
    my $c2 = chr hex $_->[1];
    my $c1_0 = $c1;
    if (is_private $c1) {
      $c1 = sprintf ':u-immi-%x', ord $c1;
      $Data->{hans}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
    }
    $Data->{hans}->{$c1}->{$c2}->{"jp:法務省告示582号別表第四:一:第1順位"} = 1;
    if (defined $_->[2]) {
      my $c2 = chr hex $_->[2];
      $Data->{hans}->{$c1}->{$c2}->{"jp:法務省告示582号別表第四:一:第2順位"} = 1;
    }
  }
  for (@{$json->{table4_2}}) {
    my $c1 = chr hex $_->[0];
    my $c2 = chr hex $_->[1];
    my $c1_0 = $c1;
    if (is_private $c1) {
      $c1 = sprintf ':u-immi-%x', ord $c1;
      $Data->{hans}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
    }
    $Data->{hans}->{$c1}->{$c2}->{"jp:法務省告示582号別表第四:二:第1順位"} = 1;
    if (defined $_->[2]) {
      my $c2 = chr hex $_->[2];
      $Data->{hans}->{$c1}->{$c2}->{"jp:法務省告示582号別表第四:二:第2順位"} = 1;
    }
  }
}

{
  use utf8;
  my $path = $ThisPath->child ('jissyukutaimap1_0_0.xslx.tsv');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    my @line = split /\t/, $_, -1;
    if (length $line[1]) {
      if ($line[0] eq $line[4]) {
        #
      } elsif (length $line[4] and not $line[1] eq 'Unicode') {
        die "|$_| ($line[1])" unless $line[1] =~ /^u\+[0-9a-f]{4,5}$/;
        die "|$_| ($line[5])" unless $line[5] =~ /^u\+[0-9a-f]{4,5}$/;
        $line[1] =~ s/^u\+//;
        $line[5] =~ s/^u\+//;
        my $c1 = chr hex $line[1];
        my $c2 = chr hex $line[5];
        my $vkey = get_vkey $c1;
        $Data->{$vkey}->{$c1}->{$c2}->{'nta:JIS縮退マップ:コード変換'} = 1;

        $line[0] =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/ or die;
        my $c3 = sprintf ':jis%d-%d-%d', $1, $2, $3;
        $line[4] =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/ or die;
        my $c4 = sprintf ':jis%d-%d-%d', $1, $2, $3;
        $Data->{$vkey}->{$c3}->{$c4}->{'nta:JIS縮退マップ:コード変換'} = 1;
      }
      if (length $line[7] and not $line[1] eq 'Unicode') {
        $line[1] =~ s/^u\+//;
        my $c1 = chr hex $line[1];
        my $c2 = join '', map { my $x = $_; die $x unless $x =~ /^u\+[0-9a-f]{4,5}$/; $x =~ s/^u\+//; chr hex $x } grep { length } $line[11], $line[12], $line[13], $line[14];
        my $vkey = get_vkey $c1;
        $Data->{$vkey}->{$c1}->{$c2}->{'nta:JIS縮退マップ:文字列変換'} = 1;

        $line[0] =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/ or die;
        my $c3 = sprintf ':jis%d-%d-%d', $1, $2, $3;
        my $c4 = join '', map { my $x = $_; $x =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/ or die; sprintf ':jis%d-%d-%d', $1, $2, $3 } grep { length } $line[7], $line[8], $line[9], $line[10];
        $Data->{$vkey}->{$c3}->{$c4}->{'nta:JIS縮退マップ:文字列変換'} = 1;
      }

      if ($line[1] eq 'Unicode') {
        #
      } elsif ($line[16] =~ /^類似字形u\+([0-9a-f]+)は本文字に変換する。$/) {
        my $c1 = chr hex $1;
        $line[1] =~ s/^u\+//;
        my $c2 = chr hex $line[1];
        my $vkey = get_vkey $c2;
        $Data->{$vkey}->{$c1}->{$c2}->{'nta:JIS縮退マップ:類似字形'} = 1;
      } elsif ($line[16] eq '合成文字（本システムでは取り扱わない）') {
        #
      } elsif ($line[16] eq '半角文字（※特に変換しない）') {
        #
      } elsif (length $line[16]) {
        die $line[16];
      }
    } # $line[1]
  }
}

print_rel_data $Data;

## License: Public Domain.
