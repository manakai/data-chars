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

print_rel_data $Data;

## License: Public Domain.
