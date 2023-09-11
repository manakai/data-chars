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

sub ucsvs ($) {
  my $s = shift;
  if ($s =~ /^U\+([0-9A-F]+)$/) {
    return chr hex $1;
  } elsif ($s =~ /^<U\+([0-9A-F]+),U\+([0-9A-F]+)>$/) {
    return chr (hex $1) . chr (hex $2);
  } else {
    die "Bad UCS code point |$s|"
  }
} # ucsvs

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
          (0xFA2E <= $cc2 and $cc2 <= 0xFAFF and not (defined $compat and $compat eq chr $cc2))) {
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
      my $cc2 = hex $1;
      if (0xE000 <= $cc2 and $cc2 <= 0xF7FF) {
        my $c2 = sprintf ':u-immi-%x', $cc2;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        insert_rel $Data,
            (u_chr $cc2), $c2, "manakai:private",
            "private";
      } else {
        my $c2 = u_chr hex $1;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
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
    
    my $ko = $data->{戸籍統一文字番号} // '';
    if ($ko =~ /^([0-9]{6})$/) {
      my $type = 'mj:戸籍統一文字番号';
      my $c2 = ':koseki' . $1;
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (length $ko) {
      die $ko;
    }
    my $to = $data->{'登記統一文字番号(参考)'} // '';
    if ($to eq '00' . $ko) {
      #
    } elsif ($to =~ /^(01[0-9]{6})$/) {
      my $type = 'mj:登記統一文字番号';
      my $c2 = ':touki' . $1;
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (length $to) {
      die $to;
    }

    if ($data->{大漢和} =~ m{^([0-9]+)$}) {
      my $type = 'mj:大漢和';
      my $c2 = sprintf ':m%d', $1;
      $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
    } elsif (length $data->{大漢和}) {
      die $data->{大漢和};
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

{
  my $path = $TempPath->child ('daikanwa-ucs.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    use utf8;
    tr/ＵＥＦ/UEF/;
    if (/^#/) {
      #
    } elsif (/^(補|)([0-9]+)('{0,2})\tU\+([0-9A-F]+)\s*$/) {
      my $c1 = sprintf ':m%s%d%s', $1 ? 'h' : '', $2, $3;
      my $c2 = chr hex $4;
      my $key = get_vkey $c2;
      $Data->{$key}->{$c1}->{$c2}->{'mj:daikanwa-ucs'} = 1;
    } elsif (/^(補|)([0-9]+)('{0,2})\tCJKF:([0-9]+)$/) {
      my $c1 = sprintf ':m%s%d%s', $1 ? 'h' : '', $2, $3;
      my $c2 = sprintf ':extf%d', $4;
      my $key = 'hans';
      $Data->{$key}->{$c1}->{$c2}->{'mj:daikanwa-ucs'} = 1;
    } elsif (/^(補|)([0-9]+)('{0,2})\t(\p{Ideographic_Description_Characters}[\p{Han}\p{Ideographic_Description_Characters}]+)$/) {
      my $c1 = sprintf ':m%s%d%s', $1 ? 'h' : '', $2, $3;
      my $c2 = (wrap_ids $4, ':mj:') // $4;
      my $key = 'idses';
      $Data->{$key}->{$c1}->{$c2}->{'mj:daikanwa-ucs'} = 1;
      my @c = split_ids $c2;
      for my $c6 (@c) {
        $Data->{components}->{$c1}->{$c6}->{'mj:ids:contains'} = 1;
      }
    } elsif (/^文字番号/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

my $ToMJOld = {};
{
  ## Source: <https://warp.ndl.go.jp/info:ndljp/pid/8198317/ossipedia.ipa.go.jp/ipamjfont/releasenote/table1.html>
  my $changes = {qw(
    MJ000405 MJ000406 MJ001060 MJ001061 MJ001132 MJ001133 MJ001135
    MJ001136 MJ001251 MJ001250 MJ001841 MJ001840 MJ002140 MJ002139
    MJ004131 MJ004132 MJ004539 MJ004540 MJ004658 MJ004659 MJ009352
    MJ009353 MJ009924 MJ009923 MJ010309 MJ010311 MJ011402 MJ011403
    MJ011519 MJ011520 MJ012202 MJ012203 MJ013032 MJ013031 MJ013497
    MJ013496 MJ017246 MJ017247 MJ019071 MJ019072 MJ022334 MJ022333
    MJ025052 MJ025053 MJ025295 MJ025296 MJ028871 MJ028872 MJ029936
    MJ029935 MJ030629 MJ030630 MJ032097 MJ032098 MJ034080 MJ034079
    MJ037379 MJ037378 MJ044582 MJ044581 MJ045050 MJ045052 MJ050631
    MJ050632 MJ051499 MJ051498 MJ055218 MJ055217
  )};
  my $path = $ThisPath->child ('mj-old.txt');
  for (split /\n/, $path->slurp) {
    if (/^(\S+)\s(\S+)$/) {
      my $key = get_vkey $1;
      $Data->{$key}->{$1}->{$2}->{'mj:version'} = 1;
      $ToMJOld->{$1} = $2;
      my $mj = substr $1, 1;
      if ($changes->{$mj}) {
        my $c3 = $2;
        my $c4 = ':' . $changes->{$mj};
        $Data->{$key}->{$c3}->{$c4}->{'manakai:same'} = 1;
      }
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('mjheisei-00101.txt');
  for (split /\n/, $path->slurp) {
    if (/^(MJ[0-9]+)\t(\w+)$/) {
      my $c1 = ':' . $1;
      my $c2 = ':' . uc $2;
      my $key = get_vkey $c1;
      $c1 = $ToMJOld->{$c1} || $c1;
      $Data->{$key}->{$c1}->{$c2}->{'mj00101:平成明朝'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('mjheisei-00501.txt');
  for (split /\n/, $path->slurp) {
    if (/^(MJ[0-9]+)\t(\w+)$/) {
      my $c1 = ':' . $1;
      my $c2 = ':' . uc $2;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{'mj00501:平成明朝'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('mjivs-00501.txt');
  for (split /\n/, $path->slurp) {
    my @c = split /\t/, $_;
    my $c1 = ':' . $c[0];
    my $key = get_vkey $c1;
    if ($c[1] =~ /^([0-9A-F]+)_([0-9A-F]+)$/) {
      my $c2 = (chr hex $1) . (chr hex $2);
      $Data->{$key}->{$c1}->{$c2}->{'mj00501:実装したMoji_JohoコレクションIVS'} = 1;
    }
    if ($c[2] =~ /^([0-9A-F]+)_([0-9A-F]+)$/) {
      my $c3 = (chr hex $1) . (chr hex $2);
      $Data->{$key}->{$c1}->{$c3}->{'mj00501:対応するHanyo-DenshiコレクションIVS'} = 1;
    }
  }
}
{
  my $path = $TempPath->child ('mjdkw-00101.txt');
  for (split /\n/, $path->slurp) {
    my @c = split /\t/, $_;
    my $c1 = ':' . $c[0];
    my $key = get_vkey $c1;
    $c1 = $ToMJOld->{$c1} || $c1;
    my $rel_type = 'mj00101:大漢和';
    $rel_type .= ':#' if $c[1] =~ s/#$//;
    my $c2;
    if ($c[1] =~ /^([0-9]+)('{0,2})$/) {
      $c2 = sprintf ':m%d%s', $1, $2;
    } elsif ($c[1] =~ /^\x95\xE2([0-9]+)$/) {
      $c2 = sprintf ':mh%d', $1;
    } else {
      die $c[1];
    }
    $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
  }
}

{
  my $path = $TempPath->child ('toukimap.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@{$json->{content}}) {
    my $mj = $data->{登記統一文字番号};
    for my $type ('非漢字',
                  'JIS包摂・UCS統合',
                  'JIS包摂規準・UCS統合規則',
                  '法務省告示582号別表第四',
                  '法務省戸籍法関連通達・通知',
                  '辞書類等による関連字',
                  '読み・字形による類推') {
      for (@{$data->{$type} or []}) {
        if (not $_->{UCS}) {
          use Data::Dumper;
          warn Dumper $_;
        }
        my $uc = ucsvs $_->{UCS};
        my $tt = "mj:$type";
        $tt = 'mj:JIS包摂規準・UCS統合規則' if $tt eq 'mj:JIS包摂・UCS統合';
        $tt .= ':' . $_->{種別} if defined $_->{種別};
        $tt .= ':' . $_->{表} if defined $_->{表};
        $tt .= ':' . $_->{順位} if defined $_->{順位};
        $tt .= ':' . $_->{ホップ数} if defined $_->{ホップ数} and
            $_->{ホップ数} > 1;
        my $c1 = ":touki$mj";
        $c1 =~ s/^:touki00/:koseki/;
        my $key = get_vkey $uc;
        $Data->{$key}->{$c1}->{$uc}->{$tt} = 1;

        if ($_->{"JIS X 0213"} =~ m{^([0-9]+)-([0-9]+)-([0-9]+)$}) {
          my $jis = sprintf ':jis%d-%d-%d', $1, $2, $3;
          $Data->{$key}->{$c1}->{$jis}->{$tt} = 1;
        }
      }
    }
  }
}

{
  my $path = $TempPath->child ('tksu.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@{$json->{content}}) {
    my $mj = $data->{登記統一文字番号};
    my $c1 = ":touki$mj";
    $c1 =~ s/^:touki00/:koseki/;

    my $ucs = ucsvs $data->{変換先}->{"UCS"};
    next if $ucs eq '＿';
    my $key = get_vkey $ucs;
    $Data->{$key}->{$c1}->{$ucs}->{'mj:縮退マップから一意な選択'} = 1;

    $data->{変換先}->{"JIS X 0213"} =~ m{^([0-9]+)-([0-9]+)-([0-9]+)$} or die $data->{変換先}->{"JIS X 0213"};
    my $jis = sprintf ':jis%d-%d-%d', $1, $2, $3;
    $Data->{$key}->{$c1}->{$jis}->{'mj:縮退マップから一意な選択'} = 1;
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'maps',
    [
      qr/^:MJ00[0-4]/,
      qr/^:MJ00/,
      qr/^:MJ01[0-4]/,
      qr/^:MJ01/,
      qr/^:MJ02[0-4]/,
      qr/^:MJ02/,
      qr/^:MJ03[0-4]/,
      qr/^:MJ03/,
      qr/^:MJ04[0-4]/,
      qr/^:MJ04/,
      qr/^:MJ05[0-4]/,
      qr/^:MJ05/,
      qr/^:m1/,
      qr/^:m2/,
      qr/^:m/,
    ];

## License: Public Domain.

