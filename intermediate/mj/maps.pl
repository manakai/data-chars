use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/imj');

sub ucs ($) {
  my $s = shift;
  if ($s =~ /^U\+([0-9A-F]+)$/) {
    return chr hex $1;
  } else {
    die "Bad UCS code point |$s|"
  }
} # ucs

sub vs ($) {
  my @r;
  for my $s (split /;/, shift) {
    if ($s =~ /^([0-9A-F]+)_([0-9A-F]+)$/) {
      push @r, chr (hex $1) . chr (hex $2);
    } else {
      die "Bad IVS |$s|"
    }
  }
  return \@r;
} # vs

my $Data = {};

## [MJ] <https://moji.or.jp/mojikiban/mjlist/>
{
  my $path = $TempPath->child ('mj.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@$json) {
    my $c1 = ':' . $data->{MJ文字図形名};
    my $key = get_vkey $c1;
    
    if ($data->{X0212} =~ /^([0-9]+)-([0-9]+)$/) {
      my $c2 = sprintf ':jis2-%d-%d', $1, $2;
      $Data->{$key}->{$c1}->{$c2}->{"mj:X0212"} = 1;
      ## JIS X 0212-1990 [MJ]
    }
    if ($data->{X0213} =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/) {
      my $c2 = sprintf ':jis%d-%d-%d', $1, $2, $3;
      my $suffix = '';
      unless ($data->{"X0213 包摂区分"} eq "0") {
        $suffix = ':' . $data->{"X0213 包摂区分"};
      }
      $Data->{$key}->{$c1}->{$c2}->{"mj:X0213$suffix"} = 1;
      ## JIS X 0213:2012 [MJ]
    }

    my $ivses = vs $data->{実装したMoji_JohoコレクションIVS};
    for (@$ivses) {
      my $type = 'mj:実装したMoji_JohoコレクションIVS';
      $Data->{$key}->{$c1}->{$_}->{$type} = 1;
      ## Unicode IVD 2017-12-12 Moji_Joho [MJ]
    }
    my $svses = vs $data->{実装したSVS};
    for (@$svses) {
      my $type = 'mj:実装したSVS';
      $Data->{$key}->{$c1}->{$_}->{$type} = 1;
      ## ISO/IEC 10646:2017 SVS [MJ]
    }
    
    my $impl_ucs = $data->{実装したUCS} ? ucs $data->{実装したUCS} : undef;
    if (defined $impl_ucs) {
      my $type = 'mj:実装したUCS';
      $Data->{$key}->{$c1}->{$impl_ucs}->{$type} = 1;
    }
    my $ucs = $data->{対応するUCS} ? ucs $data->{対応するUCS} : undef;
    if (defined $ucs) {
      my $type = 'mj:対応するUCS';
      $Data->{$key}->{$c1}->{$ucs}->{$type} = 1;
      ## ISO/IEC 10646:2017 [MJ]
    }
    my $compat = $data->{対応する互換漢字} ? ucs $data->{対応する互換漢字} : undef;
    if (defined $compat) {
      my $type = 'mj:対応する互換漢字';
      $Data->{$key}->{$c1}->{$compat}->{$type} = 1;
      ## ISO/IEC 10646:2017 [MJ]
    }

    my $juki = $data->{住基ネット統一文字コード} // '';
    if ($juki =~ /\AJ\+([0-9A-Fa-f]+)\z/) {
      my $type = 'mj:住基ネット統一文字コード';
      my $cc2 = hex $1;
      if ((0xAA00 <= $cc2 and $cc2 <= 0xD7FF) or
          (0xFA2E <= $cc2 and $cc2 <= 0xFAFF)) {
        my $c2 = sprintf ':u-juki-%x', $cc2;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        insert_rel $Data,
            (u_chr $cc2), $c2, "manakai:private",
            "private";
      } else {
        my $c2 = u_chr $cc2;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif (length $juki) {
      die $juki;
    }

    my $ns = $data->{入管正字コード} // '';
    if ($ns =~ /^0x([0-9A-Fa-f]+)$/) {
      my $type = 'mj:入管正字コード';
      my $c2 = u_chr hex $1;
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      ## 平成23年法務省告示第582号第二項 -> JIS X 0221 [MJ]
    } elsif (length $ns) {
      die $ns;
    }

    my $ng = $data->{入管外字コード} // '';
    if ($ng =~ /^0x([0-9A-Fa-f]+)$/) {
      my $type = 'mj:入管外字コード';
      my $cc2 = hex $1;
      if (0x3400 <= $cc2 and $cc2 <= 0x9FFF) {
        my $c2 = u_chr hex $1;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      } else {
        my $c2 = sprintf ':u-immi-%x', $cc2;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        insert_rel $Data,
            (u_chr $cc2), $c2, "manakai:private",
            "private";
      }
      ## 平成23年法務省告示第582号第二項 [MJ]
    } elsif (length $ng) {
      die $ng;
    }

    if ($data->{備考} =~ m{^(MJ[0-9]+)・(MJ[0-9]+)は、戸籍統一文字において、同一字形であり、字義も同一の内容である。$}) {
      my $type = 'mj:戸籍統一文字:同一';
      $Data->{hans}->{":$1"}->{":$2"}->{$type} = 1;
    } elsif ($data->{備考} =~ m{^(MJ[0-9]+)は、.+新しいMJ文字図形名は(MJ[0-9]+)となる。}) {
      my $type = 'mj:新しいMJ文字図形名';
      $Data->{hans}->{":$1"}->{":$2"}->{$type} = 1;
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
