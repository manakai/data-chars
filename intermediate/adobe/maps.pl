use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iad');

my $Data = {};
my $IsHan = {};
my $IsKana = {};
my $IsKChar = {};

for (
  [
    'aj17.txt',
    ':aj',
    [
      [22, ''], # UniJIS-UTF32-H -V
      [25, ':2004'], # UniJIS2004
      [26, ':x0213'], # UniJISX0213
      [27, ':x02132004'], # UniJISX02132004
    ],
    [],
    ':u-mac-',
  ],
  [
    'aj20.txt',
    ':aj2-',
    [
      [7, ''], # UniHojo
    ],
    [
      [2, 2, 'jisx0212', ':jis'],
    ],
    undef,
  ],
  [
    'ac17.txt',
    ':ac',
    [
      [12, ''], 
    ],
    [
      [6, 1, 'cns11643', ':cns'],
      [7, 2, 'cns11643', ':cns'],
    ],
    ':u-hkscs-',
  ],
  [
    'ag15.txt',
    ':ag',
    [
      [14, ''], 
    ],
    [
      #[2, 0, 'gb2312', ':gb'], 
      #[5, 0, 'gb12345', ':gb'], 
    ],
    ':u-gb-',
  ],
  [
    'ak9.txt',
    ':ak',
    [
      [4, ''], 
    ],
    [],
    undef,
  ],
  [
    'ak12.txt',
    ':ak1-',
    [
      [11, ''], 
    ],
    [],
    undef,
  ],
) {
  my $path = $TempPath->child ($_->[0]);
  my $prefix = $_->[1];
  my $uni_cols = $_->[2];
  my $gl_cols = $_->[3];
  my $up_prefix = $_->[4];
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^CID/) {
      #
    } elsif (/\S/) {
      my @s = split /\t/, $_;
      my $cid = 0+$s[1-1];
      my $c1 = "$prefix$cid";
      my $key = 'variants';

      for (@$uni_cols) {
        my $index = $_->[0];
        my $suffix = $_->[1];
        my $u = $s[$index-1];
        for (split /,/, $u) {
          if (/^[0-9A-Fa-f]+$/) {
            my $c2 = u_chr hex $_;
            if (is_han $c2 > 0) {
              $key = 'hans';
              $IsHan->{$c1} = 1;
            } elsif (is_kana $c2 > 0) {
              $key = 'kanas';
              $IsKana->{$c1} = 1;
            } elsif (is_kchar $c2 > 0) {
              $key = 'kchars';
              $IsKChar->{$c1} = 1;
            } else {
              if (is_private $c2) {
                my $c2_0 = $c2;
                $c2 = ($up_prefix // die "$c1 $c2") . sprintf '%x', ord $c2;
                $c2 =~ s{^:u-hkscs-(f6b[1-f]|f6[c-f][0-9a-f]|f7[0-9a-f]{2}|f80[0-9a-f]|f81[0-9a-d])$}{:u-bigfive-$1}g;
                $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
              }
            }
            if ($key eq 'kchars' and $c2 eq "\x{3000}") {
              my $key = get_vkey $c2;
              $Data->{$key}->{$c1}->{$c2}->{"adobe:uni".$suffix} = 1;
            } else{
              $Data->{$key}->{$c1}->{$c2}->{"adobe:uni".$suffix} = 1;
            }
          } elsif (/^([0-9A-Fa-f]+)v$/) {
            my $c2 = u_chr hex $1;
            if (is_han $c2 > 0) {
              $key = 'hans';
              $IsHan->{$c1} = 1;
            } elsif (is_kana $c2 > 0) {
              $key = 'kanas';
              $IsKana->{$c1} = 1;
            } elsif (is_kchar $c2 > 0) {
              $key = 'kchars';
              $IsKChar->{$c1} = 1;
            } else {
              if ($key eq 'hans' and not is_han $c2) {
                if (is_private $c2) {
                  my $c2_0 = $c2;
                  $c2 = ($up_prefix // die) . sprintf '%x', ord $c2;
                  $c2 =~ s{^:u-hkscs-(f6b[1-f]|f6[c-f][0-9a-f]|f7[0-9a-f]{2}|f80[0-9a-f]|f81[0-9a-d])$}{:u-bigfive-$1}g;
                  $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
                } else {
                  die $c1;
                }
              }
            }
            $Data->{$key}->{$c1}->{$c2}->{"adobe:uni".$suffix.":v"} = 1;
          } elsif ($_ eq '*') {
            #
          } else {
            die $_;
          }
        }
      } # $uni_cols
      for (@$gl_cols) {
        my $index = $_->[0];
        my $p = $_->[1];
        my $gl_prefix = $_->[3];
        my $suffix = $_->[2];
        my $v = $s[$index-1];
        for (split /,/, $v) {
          if (/^([0-9A-Fa-f]{2})([0-9A-fa-f]{2})$/) {
            my $jis = sprintf '%d-%d-%d', $p, (hex $1)-0x20, (hex $2)-0x20;
            $Data->{$key}->{$c1}->{"$gl_prefix$jis"}->{"adobe:".$suffix} = 1;
          } elsif (/^([0-9A-Fa-f]{2})([0-9A-fa-f]{2})v$/) {
            my $jis = sprintf '%d-%d-%d', $p, (hex $1)-0x20, (hex $2)-0x20;
            $Data->{$key}->{$c1}->{"$gl_prefix$jis"}->{"adobe:".$suffix.':v'} = 1;
          } elsif ($_ eq '*') {
            #
          } else {
            die $_;
          }
        }
      } # $gl_cols
    }
  }
}
{
  for (
    [0x2018, 12173],
    [0x2019, 12174],
    [0x201C,  7956],
    [0x201D,  7957],
    [0x337B, 12044],
    [0x337C, 12043],
    [0x337D, 12042],
    [0x337E, 12041],
    [0xFF1A, 12101],
  ) {
    my $cid = $_->[1];
    my $u = $_->[0];
    $Data->{variants}->{":aj$cid"}->{u_chr $u}->{"adobe:uni:pro"} = 1;
  }
}

for (
  ['aj-vs.txt', ':aj'],
  ['ac-vs.txt', ':ac'],
  ['ag-vs.txt', ':ag'],
  ['ak-vs.txt', ':ak'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $prefix = $_->[1];
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([0-9A-F]+) ([0-9A-F]+);[^;]+; CID\+([0-9]+)$/) {
      my $c1 = "$prefix$3";
      my $c2_1 = u_chr hex $1;
      my $c2 = u_hexs $1 . ' ' . $2;
      my $key = 'variants';
      if (is_han $c2_1 > 0) {
        $key = 'hans';
        $IsHan->{$c1} = 1;
      } elsif (is_kana $c2_1 > 0) {
        $key = 'kanas';
        $IsKana->{$c1} = 1;
      } elsif (is_kchar $c2_1 > 0) {
        $key = 'kchars';
        $IsKChar->{$c1} = 1;
      }
      $Data->{$key}->{$c1}->{$c2}->{"adobe:vs"} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('aj17-kanji.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (/\S/) {
      my @s = split /\t/, $_;
      my $cid = 0+$s[1-1];

      for (
        [2, 1, 'jp90'],
        [3, 1, 'jp04'],
        [4, 1, 'jp78'],
        [5, 1, 'jp83'],
        [6, 1, 'expt'],
        [9, 2, 'jisx0212'],
        #[14, 1, 'kjis'],
        [15, 1, 'ext'],
        [16, 1, 'add'],
        [17, 1, 'jis78'],
      ) {
        my $v = $s[$_->[0]-1];
        my $p = $_->[1];
        my $t = $_->[2];
        if ($v eq '*') {
          #
        } elsif ($v =~ /^([0-9]+)-([0-9]+)$/) {
          my $jis = sprintf '%d-%d-%d', $p, $1, $2;
          my $c1 = ":aj$cid";
          my $key = 'variants';
          $key = 'hans' if $IsHan->{$c1};
          $key = 'kchars' if $IsKChar->{$c1};
          $Data->{$key}->{$c1}->{":jis$jis"}->{"adobe:$t"} = 1;
        } else {
          die $v;
        }
      }
      
      for (
        [7, 'jisx0213:2000'],
        [8, 'jisx0213:2004'],
      ) {
        my $v = $s[$_->[0]-1];
        my $t = $_->[1];
        if ($v eq '*') {
          #
        } elsif ($v =~ /^([0-9]+)-([0-9]+)-([0-9]+)$/) {
          my $jis = sprintf '%d-%d-%d', $1, $2, $3;
          $Data->{hans}->{":aj$cid"}->{":jis$jis"}->{"adobe:$t"} = 1;
        } else {
          die $v;
        }
      }

      if ($s[11-1] eq '*') {
        #
      } elsif ($s[11-1] =~ /^CID\+([0-9]+)$/) {
        $Data->{hans}->{':aj'.(0+$1)}->{":aj$cid"}->{"adobe:trad"} = 1;
      } else {
        die $s[11-1];
      }

      my $vss = $s[20-1];
      for (split /:/, $vss) {
        if (m{^<U\+([0-9A-F]+),U\+([0-9A-F]+)>$}) {
          #$Data->{variants}->{":aj$cid"}->{u_hexs $1 . ' ' . $2}->{"adobe:vs"} = 1;
        } else {
          die $_;
        }
      }
    }
  }
}

for (
  ['aj17.fea', ':aj'],
  ['ac17.fea', ':ac'],
  ['ag15.fea', ':ag'],
  ['akr9.fea', ':ak'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $prefix = $_->[1];
  my $items = {};
  my $copies = {};
  my $feat;
  my $lookup_name;
  my $lookups = {};
  my $current;
  my $current_x;
  my $current_i;
  my $feat_data = {};
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^feature ([A-Za-z0-9]{4}) (?:useExtension |)\{$/) {
      $feat = $1;
      $current = {};
      $current_x = {};
      $current_i = {};
      $feat_data->{$feat} = {items => $current, items_x => $current_x,
                             items_i => $current_i};
    } elsif (/^\s*lookup (\w+) \{$/) {
      $lookup_name = $1;
      $current = {};
      $current_x = {};
      $current_i = {};
      $lookups->{$lookup_name} = {
        items => $current,
        items_x => $current_x,
        items_i => $current_i,
      };
    } elsif (/^\s*\}\s*\w+;$/) {
      if (defined $lookup_name) {
        if (defined $feat) {
          for my $c1 (keys %$current_x) {
            for my $c2 (keys %{$current_x->{$c1}}) {
              $feat_data->{$feat}->{items_x}->{$c1}->{$c2} = 1;
            }
          }
          for my $c1 (keys %$current) {
            for my $c2 (keys %{$current->{$c1}}) {
              $feat_data->{$feat}->{items}->{$c1}->{$c2} = 1;
            }
          }
          for my $c (keys %$current_i) {
            $feat_data->{$feat}->{items_i}->{$c} = 1;
          }
          $current = $feat_data->{$feat}->{items};
          $current_x = $feat_data->{$feat}->{items_x};
          $current_i = $feat_data->{$feat}->{items_i};
        } else { # no $feat
          undef $current;
          undef $current_x;
          undef $current_i;
        }
        undef $lookup_name;
      } elsif (defined $feat) {
        undef $feat;
        undef $current;
        undef $current_x;
        undef $current_i;
      } else {
        die;
      }
    } elsif (/^\s*feature (\w+);$/) {
      $copies->{$1}->{$feat} = 1;
    } elsif (/^\s*substitute \\([0-9]+) by \\([0-9]+);\s*$/) {
      $current->{"$prefix$1"}->{"$prefix$2"} = 1;
    } elsif (/^\s*substitute ([\\0-9 ]+) by \\([0-9]+);\s*$/) {
      my $t = $2;
      my $f = join '', map { "$prefix$_" } map { s/^\\//; $_ } split /\s+/, $1;
      $current->{$f}->{"$prefix$t"} = 1;
    } elsif (/^\s*substitute \\([0-9]+) from \[([\\0-9 ]+)\];\s*$/) {
      my $f = $1;
      my $t = [map { s/^\\//; $_ } split /\s+/, $2];
      for (@$t) {
        $current->{"$prefix$f"}->{"$prefix$_"} = 1;
      }
    } elsif (/^\s*substitute \[([\\0-9 -]+)\] by \\([0-9]+);\s*$/) {
      my $t = $2;
      my $f = [map {
        if (/^\\([0-9]+)-\\([0-9]+)$/) {
          $1..$2;
        } else {
          s/^\\//;
          $_;
        }
      } split /\s+/, $1];
      for (@$f) {
        $current->{"$prefix$_"}->{"$prefix$t"} = 1;
      }
    } elsif (/^\s*substitute \\([0-9]+)' \\([0-9]+)' by \\([0-9]+);\s*$/) {
      $current->{"$prefix$1$prefix$2"}->{"$prefix$3"} = 1;
    } elsif (/^\s*\@(\w+) = \[([\\0-9 -]+)\];\s*$/) {
      my $name = $1;
      my $v = [map {
        if (/^\\([0-9]+)-\\([0-9]+)$/) {
          $1..$2;
        } else {
          s/^\\//;
          $_;
        }
      } split /\s+/, $2];
      $items->{$name} = $v;
    } elsif (/^\s*substitute \[[^\[\]]+\] \\([0-9]+)' \[[^\[\]]+\] by \\([0-9]+);\s*$/) {
      $current_x->{"$prefix$1"}->{"$prefix$2"} = 1;
    } elsif (/^\s*substitute \[[^\[\]]+\] \@(\w+)' by \@(\w+);\s*$/) {
      my $n1 = $1;
      my $n2 = $2;
      for (0..$#{$items->{$n1}}) {
        my $v1 = $items->{$n1}->[$_];
        my $v2 = $items->{$n2}->[$_];
        $current_x->{"$prefix$v1"}->{"$prefix$v2"} = 1;
      }
    } elsif (/^\s*substitute \@(\w+)' lookup (\w+);\s*$/) {
      my $item = $items->{$1} or die $1;
      my $lookup = $lookups->{$2} or die $2;
      for (@$item) {
        my $v1 = "$prefix$_";
        for my $v2 (keys %{$lookup->{items}->{$v1}}) {
          $current->{$v1}->{$v2} = 1;
        }
        for my $v2 (keys %{$lookup->{items_x}->{$v1}}) {
          $current_x->{$v1}->{$v2} = 1;
        }
        $current_i->{$v1} = 1 if $lookup->{items_i}->{$v1};
      }
    } elsif (/^\s*substitute \@(\w+)' lookup (\w+) \@\w+(?: \@\w+)*;\s*$/) {
      my $item = $items->{$1} or die $1;
      my $lookup = $lookups->{$2} or die $2;
      for (@$item) {
        my $v1 = "$prefix$_";
        for my $v2 (keys %{$lookup->{items}->{$v1}}) {
          $current_x->{$v1}->{$v2} = 1;
        }
        for my $v2 (keys %{$lookup->{items_x}->{$v1}}) {
          $current_x->{$v1}->{$v2} = 1;
        }
        $current_i->{$v1} = 1 if $lookup->{items_i}->{$v1};
      }
    } elsif (/^\s*substitute \@\w+ \@(\w+)' lookup (\w+);\s*$/) {
      my $item = $items->{$1} or die $1;
      my $lookup = $lookups->{$2} or die $2;
      for (@$item) {
        my $v1 = "$prefix$_";
        for my $v2 (keys %{$lookup->{items}->{$v1}}) {
          $current_x->{$v1}->{$v2} = 1;
        }
        for my $v2 (keys %{$lookup->{items_x}->{$v1}}) {
          $current_x->{$v1}->{$v2} = 1;
        }
        $current_i->{$v1} = 1 if $lookup->{items_i}->{$v1};
      }
    } elsif (/\s*ignore substitute \\([0-9]+)' \\([0-9]+)' \@\w+;$/) {
      $current_i->{"$prefix$1$prefix$2"} = 1;
    } elsif (/^\s*lookup (\w+);$/) {
      my $name = $1;
      my $lookup = $lookups->{$name} or die $name;
      my $items = $lookup->{items};
      my $items_x = $lookup->{items_x};
      my $items_i = $lookup->{items_i};
      for my $c1 (keys %$items) {
        for my $c2 (keys %{$items->{$c1}}) {
          $current->{$c1}->{$c2} = 1;
        }
      }
      for my $c1 (keys %$items_x) {
        for my $c2 (keys %{$items_x->{$c1}}) {
          $current_x->{$c1}->{$c2} = 1;
        }
      }
      for my $c (keys %$items_i) {
        $current_i->{$c} = 1;
      }
    } elsif (/^languagesystem/) {
      #
    } elsif (/^\s*language/) {
      #
    } elsif (/^\s*script/) {
      #
    } elsif (/^\s*position/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
  for my $from_feat (keys %$copies) {
    for my $to_feat (keys %{$copies->{$from_feat}}) {
      my $current = $feat_data->{$from_feat}->{items};
      my $current_x = $feat_data->{$from_feat}->{items_x};
      my $current_i = $feat_data->{$from_feat}->{items_i};
      for my $c1 (keys %$current_x) {
        for my $c2 (keys %{$current_x->{$c1}}) {
          $feat_data->{$to_feat}->{items_x}->{$c1}->{$c2} = 1;
        }
      }
      for my $c1 (keys %$current) {
        for my $c2 (keys %{$current->{$c1}}) {
          $feat_data->{$to_feat}->{items}->{$c1}->{$c2} = 1;
        }
      }
      for my $c (keys %$current_i) {
        $feat_data->{$to_feat}->{items_i}->{$c} = 1;
      }
    }
  } # $from_feat
  L: {
    my $found = 0;
    for my $feat (keys %$feat_data) {
      my $current = $feat_data->{$feat}->{items};
      for my $c1 (keys %$current) {
        for my $c2 (keys %{$current->{$c1}}) {
          if ($IsHan->{$c1} and $IsHan->{$c2}) {
            #
          } elsif ($IsKana->{$c1} and $IsKana->{$c2}) {
            #
          } elsif ($IsKChar->{$c1} and $IsKChar->{$c2}) {
            #
          } elsif ($IsHan->{$c1} or $IsHan->{$c2}) {
            if ({
              jp78 => 1,
              jp83 => 1,
              expt => 1,
              trad => 1,
              hojo => 1,
              nlck => 1,
            }->{$feat}) {
              $IsHan->{$c1} = $IsHan->{$c2} = 1;
              $found = 1;
            } else {
              warn $feat unless {
                aalt => 1, nalt => 1,
                ruby => 1, hngl => 1,
              }->{$feat};
            }
          } elsif ($IsKana->{$c1} or $IsKana->{$c2}) {
            if ({
              fwid => 1,
              hwid => 1,
              pwid => 1,
              vert => 1,
              vrt2 => 1,
              ruby => 1,
              pkna => 1,
              hkna => 1,
              vkna => 1,
            }->{$feat}) {
              $IsKana->{$c1} = $IsKana->{$c2} = 1;
              $found = 1;
            } else {
              warn $feat unless {
                aalt => 1, nalt => 1, dlig => 1,
              }->{$feat};
            }
          } elsif ($IsKChar->{$c1} or $IsKChar->{$c2}) {
            if ({
              tjmo => 1,
              vjmo => 1,
              ljmo => 1,
              
              vert => 1,
              vrt2 => 1,
              
              ccmp => 1,
            }->{$feat}) {
              $IsKChar->{$c1} = 1;
              $IsKChar->{$c2} = 1;
              $found = 1;
            } else {
              warn $feat unless {
                aalt => 1, ccmp => 1,
              }->{$feat};
            }
          }
          if (not $IsKana->{$c1} and
              $feat eq 'ccmp' and
              $c1 =~ m{^(:aj[0-9]+)(:aj[0-9]+)$} and
              $IsKana->{$1} and $IsKana->{$2}) {
            $IsKana->{$c1} = $IsKana->{$c2} = 1;
            $found = 1;
          }
        }
      }
    }
    redo if $found;
  } # L
  for my $feat (keys %$feat_data) {
    my $current = $feat_data->{$feat}->{items};
    my $current_x = $feat_data->{$feat}->{items_x};
    my $current_i = $feat_data->{$feat}->{items_i};
    for my $c1 (keys %$current_x) {
      for my $c2 (keys %{$current_x->{$c1}}) {
        $Data->{variants}->{$c1}->{$c2}->{"opentype:$feat:contextual"} = 1;
      }
    }
    for my $c1 (keys %$current) {
      for my $c2 (keys %{$current->{$c1}}) {
        my $key = 'variants';
        if ($IsHan->{$c1} and $IsHan->{$c2}) {
          $key = 'hans';
        } elsif ($IsKana->{$c1} and $IsKana->{$c2}) {
          $key = 'kanas';
        } elsif ($IsKChar->{$c1} and $IsKChar->{$c2}) {
          $key = 'kchars';
        } else {
          if ($IsHan->{$c1} or $IsHan->{$c2}) {
            if ($feat eq 'hngl' or $feat eq 'aalt') {
              #
            } else {
            #  warn $feat, $c1, $c2;
            }
          } elsif (is_han $c1) {
            #warn $feat, $c1, $c2;
          }
        }
        if ($current_i->{$c1} or
            (keys %{$current_x->{$c1} or {}} and not $feat =~ /alt$/)) {
          $Data->{$key}->{$c1}->{$c2}->{"opentype:$feat:contextual"} = 1;
        } else {
          $Data->{$key}->{$c1}->{$c2}->{"opentype:$feat"} = 1;
        }
      }
    }
  }
}

{
  my $path = $TempPath->child ('akr9-hangul.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (/\S/) {
      my @s = split /\t/, $_;
      my $cid = 0+$s[3-1];

      for (
        [5, ':ks0', 'mapping'],
        [6, ':ks1', 'mapping'],
        [7, ':kps0', 'mapping'],
        [8, ':gb20', 'mapping'],
      ) {
        my $v = $s[$_->[0]-1];
        my $p = $_->[1];
        my $t = $_->[2];
        if ($v eq '*') {
          #
        } elsif ($v =~ /^([0-9]+)-([0-9]+)$/) {
          my $c2 = sprintf '%s-%d-%d', $p, $1, $2;
          my $c1 = ":ak$cid";
          my $key = 'kchars';
          $Data->{$key}->{$c1}->{$c2}->{"adobe:$t"} = 1;
        } else {
          die $v;
        }
      }
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
