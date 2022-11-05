use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/imj');

my $Data = {};

{
  my $path = $ThisPath->child ('wakan-kana.txt');
  for (split /\n/, $path->slurp_utf8) {
    if (/^([sk]|s\?) (\S+) (\S+)$/) {
      my $ref_type = {
        s => 'wakan:assoc',
        's?' => 'wakan:assoc?',
        k => 'wakan:section',
      }->{$1};
      my $c1 = $2;
      my $c2 = $3;
      $Data->{kanas}->{$c1}->{$c2}->{$ref_type} = 1;
      if ($ref_type eq 'wakan:section') {
        my $c2_2 = $c2;
        $c2_2 =~ s/^:wakan-//;
        $Data->{kanas}->{$c2}->{$c2_2}->{'manakai:unified'} = 1;
      }
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $ThisPath->child ('ninjal-kana.txt');
  for (split /\n/, $path->slurp_utf8) {
    if (/^([skum]|k2) (\S+) (\S+)$/) {
      use utf8;
      my $ref_type = {
        s => 'ninjal:字母',
        k => 'ninjal:平仮名',
        k2 => 'ninjal:備考:仮名',
        u => 'ninjal:UNICODE',
        m => 'ninjal:MJ文字図形名',
      }->{$1};
      my $c1 = $2;
      my $c2 = $3;
      $Data->{kanas}->{$c1}->{$c2}->{$ref_type} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $ThisPath->child ('mj-kana.txt');
  my $json = json_bytes2perl $path->slurp;
  my $header = shift @$json;
  my $items = [];
  for my $data (@$json) {
    my $item = {};
    for my $i (0..$#$data) {
      $item->{$header->[$i]} = $data->[$i];
    }
    push @$items, $item;
  }

  use utf8;
  for my $item (@$items) {
    my $c1 = ':' . $item->{"MJ文字図形名"};

    if ($item->{"UCS"} =~ m{^U\+([0-9A-Fa-f]+)$}) {
      my $c2 = chr hex $1;
      $Data->{kanas}->{$c1}->{$c2}->{'mj:UCS'} = 1;
    }
    
    if ($item->{"字母のUCS"} =~ m{^U\+([0-9A-Fa-f]+)$}) {
      my $c2 = chr hex $1;
      $Data->{kanas}->{$c1}->{$c2}->{'mj:字母'} = 1;
    }

    if ($item->{"音価１"} =~ m{^(.)$}) {
      my $c2 = $1;
      $Data->{kanas}->{$c1}->{$c2}->{'mj:音価1'} = 1;
    }
    if ($item->{"音価２"} =~ m{^(.)$}) {
      my $c2 = $1;
      $Data->{kanas}->{$c1}->{$c2}->{'mj:音価2'} = 1;
    }
    if ($item->{"音価３"} =~ m{^(.)$}) {
      my $c2 = $1;
      $Data->{kanas}->{$c1}->{$c2}->{'mj:音価3'} = 1;
    }

    if ($item->{"戸籍統一文字番号"} =~ m{^([0-9]+)$}) {
      my $c2 = ":koseki$1";
      $Data->{kanas}->{$c1}->{$c2}->{'mj:戸籍統一文字番号'} = 1;
    }
    if ($item->{"学術用変体仮名番号"} =~ m{^([0-9]+)$}) {
      my $c2 = ":ninjal$1";
      $Data->{kanas}->{$c1}->{$c2}->{'mj:学術用変体仮名番号'} = 1;
    }

    if ($item->{"備考"} =~ m{^(MJ[0-9]+)へ統合$}) {
      my $c2 = ":$1";
      $Data->{kanas}->{$c1}->{$c2}->{'mj:統合'} = 1;
    }
  }
}

print_rel_data $Data;

## License: Public Domain.

