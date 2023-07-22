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

my $Data = {};

{
  my $path = $TempPath->child ('map.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@{$json->{content}}) {
    my $mj = $data->{MJ文字図形名};
    for my $type ('JIS包摂規準・UCS統合規則',
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
        $tt .= ':' . $_->{種別} if defined $_->{種別};
        $tt .= ':' . $_->{表} if defined $_->{表};
        $tt .= ':' . $_->{順位} if defined $_->{順位};
        $tt .= ':' . $_->{ホップ数} if defined $_->{ホップ数} and
            $_->{ホップ数} > 1;
        my $c1 = ":$mj";
        my $key = get_vkey $c1;
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
  my $path = $TempPath->child ('mjsu.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (@{$json->{content}}) {
    my $mj = $data->{MJ文字図形名};
    my $c1 = ':' . $mj;
    my $key = get_vkey $c1;

    $data->{変換先}->{"UCS"} =~ m{^U\+([0-9A-F]+)$} or die $data->{変換先}->{"UCS"};
    my $ucs = chr hex $1;
    next if $ucs eq '＿';
    $Data->{$key}->{$c1}->{$ucs}->{'mj:縮退マップから一意な選択'} = 1;

    $data->{変換先}->{"JIS X 0213"} =~ m{^([0-9]+)-([0-9]+)-([0-9]+)$} or die $data->{変換先}->{"JIS X 0213"};
    my $jis = sprintf ':jis%d-%d-%d', $1, $2, $3;
    $Data->{$key}->{$c1}->{$jis}->{'mj:縮退マップから一意な選択'} = 1;
  }
}

for (
  [1, qr/^:MJ00/],
  [2, qr/^:MJ01/],
  [3, qr/^:MJ02/],
  [4, qr/^:MJ03/],
  [5, qr/^:MJ04/],
  [6, qr/^:MJ05/],
) {
  my ($i, $pattern) = @$_;
  my $path = $ThisPath->child ("fmaps-$i.list");
  my $data = {};
  my @v = grep { /^$pattern/ } keys %{$Data->{hans}};
  for (@v) {
    $data->{hans}->{$_} = delete $Data->{hans}->{$_};
  }
  write_rel_data $data => $path;
}
{
  my $path = $ThisPath->child ('fmaps-0.list');
  write_rel_data $Data => $path;
}

## License: Public Domain.

