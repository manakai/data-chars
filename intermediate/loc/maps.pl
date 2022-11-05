use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/ilo');
my $Data = {};
my $IsHan = {};

{
  my $data1 = [];
  my $data2 = [];
  {
    my $path = $TempPath->child ('eacc2uni.txt');
    my $file = $path->openr;
    while (<$file>) {
      if (m{^([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2}),([0-9A-Fa-f]+),}) {
        push @$data1, [(hex $1)-0x20, (hex $2)-0x20, (hex $3)-0x20, hex $4];
        if (m{^([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2}),([0-9A-Fa-f]+),.+\(((?:unrelated |)variant) of EACC ([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\)}) {
          push @$data2, [(hex $1)-0x20, (hex $2)-0x20, (hex $3)-0x20,
                         (hex $6)-0x20, (hex $7)-0x20, (hex $8)-0x20,
                         $5];
        }
      } elsif (/^\s*#/) {
        #
      } elsif (/\S/) {
        die $_;
      }
    }
  }
  
  for (@$data1) {
    if ($_->[0] == 0x7F-0x20) {
      #$_->[0], $_->[1]+0x20, $_->[2]+0x20, $_->[3];
    } else {
      my $c1 = sprintf ":cccii%d-%d-%d", $_->[0], $_->[1], $_->[2];
      my $c2 = u_chr $_->[3];
      my $c2_0 = $c2;
      my $key = get_vkey $c2;
      $key = 'kanas' if is_kana $c1 > 0;
      $IsHan->{$c1} = 1 if $key eq 'hans';
      if (is_private $c2) {
        $c2 = sprintf ':u-loc-%x', ord $c2;
        $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
      $Data->{$key}->{$c1}->{$c2}->{'marc:mapping'} = 1;
    }
  }
  for (@$data2) {
    my $c1 = sprintf ':cccii%d-%d-%d', $_->[0], $_->[1], $_->[2];
    die if $_->[0] == 95;
    my $c2 = sprintf ':cccii%d-%d-%d', $_->[3], $_->[4], $_->[5];
    die if $_->[3] == 95;
    my $key = 'variants';
      $key = 'kanas' if is_kana $c1 > 0 or is_kana $c2 > 0;
    $key = 'hans' if $IsHan->{$c1} or $IsHan->{$c2};
    $Data->{$key}->{$c1}->{$c2}->{'marc:'.$_->[6]} = 1;
  }
}

{
  my $data1 = [];
  {
    my $path = $TempPath->child ('marcpua1.html');
    my $file = $path->openr;
    local $/ = "<tr>";
    while (<$file>) {
      if (m{^\s*<td>([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})</td><td>([0-9A-Fa-f]+)</td>.*<td>&#x[0-9A-Fa-f]+;\s*\(([0-9A-Fa-f]+)\)</td>}s) {
        push @$data1, [(hex $1)-0x20, (hex $2)-0x20, (hex $3)-0x20, hex $4];
      } elsif (m{^<td>[0-9A-Fa-f]+}) {
        die $_;
      }
    }
  }

  for (@$data1) {
    if ($_->[0] == 0x7F-0x20) {
      #$_->[0], $_->[1]+0x20, $_->[2]+0x20, $_->[3];
      die;
    } else {
      my $c1 = sprintf ":cccii%d-%d-%d", $_->[0], $_->[1], $_->[2];
      my $c2 = u_chr $_->[3];
      my $c2_0 = $c2;
      my $key = get_vkey $c2;
      $key = 'kanas' if is_kana $c1 > 0;
      $key = 'hans' if $IsHan->{$c1};
      $IsHan->{$c1} = 1 if $key eq 'hans';
      if (is_private $c2) {
        $c2 = sprintf ':u-loc-%x', ord $c2;
        $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
      $Data->{$key}->{$c1}->{$c2}->{'marc:mapping'} = 1;
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
