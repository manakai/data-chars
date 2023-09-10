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
  } elsif ($s =~ /^<U\+([0-9A-F]+),U\+([0-9A-F]+)>$/) {
    return chr (hex $1) . chr (hex $2);
  } else {
    die "Bad UCS code point |$s|"
  }
} # ucs

my $Data = {};

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
        my $uc = ucs $_->{UCS};
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

    my $ucs = ucs $data->{変換先}->{"UCS"};
    next if $ucs eq '＿';
    my $key = get_vkey $ucs;
    $Data->{$key}->{$c1}->{$ucs}->{'mj:縮退マップから一意な選択'} = 1;

    $data->{変換先}->{"JIS X 0213"} =~ m{^([0-9]+)-([0-9]+)-([0-9]+)$} or die $data->{変換先}->{"JIS X 0213"};
    my $jis = sprintf ':jis%d-%d-%d', $1, $2, $3;
    $Data->{$key}->{$c1}->{$jis}->{'mj:縮退マップから一意な選択'} = 1;
  }
}

{
  my $path = $ThisPath->child ('mj-old.txt');
  for (split /\n/, $path->slurp) {
    if (/^(\S+)\s(\S+)$/) {
      my $key = get_vkey $1;
      $Data->{$key}->{$1}->{$2}->{'mj:version'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

print_rel_data $Data;

## License: Public Domain.

