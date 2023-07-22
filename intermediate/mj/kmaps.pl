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
      $Data->{kanas}->{$c1}->{$c2}->{'mj:対応するUCS'} = 1;
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

{
  ## Source: <https://moji.or.jp/wp-content/mojikiban/2019/05/f0216ed4b3bf8599632bf32259275e18.html>
  my $path = $ThisPath->child ('mj-voiced.txt');
  for (split /\x0A/, $path->slurp_utf8) {
    if (/^([0-9a-f]+),([0-9a-f]+)\s+(\S+)$/) {
      my $c1 = (chr hex $1) . (chr hex $2);
      my $c2 = $3;
      use utf8;
      $Data->{kanas}->{$c1}->{$c2}->{'mj:音価1'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $VKeys = {};
  my $path = $TempPath->child ('hikanji.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\x{FEFF}*#/) {
      #
    } elsif (/^post name/) {
      #
    } elsif (/\S/) {
      my @line = split /\t/, $_, -1;

      use utf8;

      # post name
      my $c1;
      if ($line[0] =~ /^aj([1-9][0-9]*)$/) {
        $c1 = ':aj' . $1;
      } elsif ($line[0] =~ /^mj([0-9]+)$/) {
        $c1 = ':MJ' . $1;
      } elsif ($line[0] =~ /^IDC([[0-9A-F]+)$/) {
        $c1 = chr hex $1;
      } else {
        die "|$line[0]|";
      }

      # 対応UCS
      my $c2;
      if ($line[1] =~ /^U\+([0-9A-F]+)$/) {
        $c2 = chr hex $1;
      } elsif (length $line[1]) {
        die $line[1];
      }
      my $vkey = get_vkey ($c2 // $c1);
      $VKeys->{$c1} = $vkey;
      if (defined $c2) {
        $Data->{$vkey}->{$c1}->{$c2}->{'mj:対応するUCS'} = 1
            unless $c1 eq $c2;
      }

      # JIS X 0213
      if ($line[3] =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/) {
        my $c3 = sprintf ':jis%d-%d-%d', $1, $2, $3;
        $Data->{$vkey}->{$c1}->{$c3}->{'mj:X0213'} = 1;
      } elsif ($line[3] =~ /\S/) {
        die $line[3];
      }

      # UCS実装
      if ($line[6] =~ /^0x([0-9A-F]+)$/) {
        my $c4 = chr hex $1;
        $Data->{$vkey}->{$c1}->{$c4}->{'mj:実装したUCS'} = 1
            unless $c1 eq $c4;
      } elsif (length $line[6]) {
        die $line[6];
      }

      # 合成列
      if ($line[7] =~ /^<0x([0-9A-F]+),0x([0-9A-F]+)>$/) {
        my $c5 = (chr hex $1) . (chr hex $2);
        $Data->{$vkey}->{$c1}->{$c5}->{'mj:実装したUCS'} = 1;
      } elsif (length $line[7]) {
        die $line[7];
      }

      # 戸籍統一文字番号(参考)
      if ($line[8] =~ /^[0-9]+$/) {
        my $c6 = ':koseki' . $line[8];
        $Data->{$vkey}->{$c1}->{$c6}->{'mj:戸籍統一文字番号'} = 1;
      } elsif (length $line[8]) {
        die $line[8];
      }
      # 登記統一文字番号(参考)
      if ($line[9] eq '00' . $line[8]) {
        #
      } elsif ($line[9] =~ /^[0-9]+$/) {
        my $c7 = ':touki' . $line[9];
        $Data->{$vkey}->{$c1}->{$c7}->{'mj:登記統一文字番号'} = 1;
      } elsif (length $line[9]) {
        die $line[9];
      }
      
      # 備考
      if ($line[11] =~ /^aj([0-9]+)の(HalfWidth|Narrow|FullWidth|Wide|VerticalWriting|斜線入り)$/) {
        my $c8 = ':aj' . $1;
        my $vkey2 = $VKeys->{$c8} // $vkey;
        $Data->{$vkey}->{$c1}->{$c8}->{'mj:' . $2} = 1;
      } elsif (length $line[11]) {
        die $line[11];
      }
    }
  }
}

print_rel_data $Data;

## License: Public Domain.

