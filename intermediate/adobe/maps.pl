use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iad');

sub u_chr ($) {
  if ($_[0] <= 0x1F or (0x7F <= $_[0] and $_[0] <= 0x9F)) {
    return sprintf ':u%x', $_[0];
  }
  my $c = chr $_[0];
  if ($c eq ":" or $c eq "." or
      $c =~ /\p{Non_Character_Code_Point}|\p{Surrogate}/) {
    return sprintf ':u%x', $_[0];
  } else {
    return $c;
  }
} # u_chr

sub u_hexs ($) {
  my $s = shift;
  my $i = 0;
  return join '', map {
    my $t = u_chr hex $_;
    if ($i++ != 0) {
      $t = '.' if $t eq ':u2e';
      $t = ':' if $t eq ':u3a';
    }
    if (1 < length $t) {
      return join '', map {
        sprintf ':u%x', hex $_;
      } split /\s+/, $s;
    }
    $t;
  } split /\s+/, $s
} # u_hexs

my $Data = {};

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
  ],
  [
    'ac17.txt',
    ':ac',
    [
      [12, ''], 
    ],
    [
      [6, 1, 'cns11643', ':cns'],
      [6, 2, 'cns11643', ':cns'],
    ],
  ],
  [
    'ag15.txt',
    ':ag',
    [
      [14, ''], 
    ],
    [],
  ],
  [
    'ak9.txt',
    ':ak',
    [
      [4, ''], 
    ],
    [],
  ],
  [
    'ak12.txt',
    ':ak1-',
    [
      [11, ''], 
    ],
    [],
  ],
) {
  my $path = $TempPath->child ($_->[0]);
  my $prefix = $_->[1];
  my $uni_cols = $_->[2];
  my $gl_cols = $_->[3];
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^CID/) {
      #
    } elsif (/\S/) {
      my @s = split /\t/, $_;
      my $cid = 0+$s[1-1];

      for (@$uni_cols) {
        my $index = $_->[0];
        my $suffix = $_->[1];
        my $u = $s[$index-1];
        for (split /,/, $u) {
          if (/^[0-9A-Fa-f]+$/) {
            $Data->{variants}->{"$prefix$cid"}->{u_chr hex $_}->{"adobe:uni".$suffix} = 1;
          } elsif (/^([0-9A-Fa-f]+)v$/) {
            $Data->{variants}->{"$prefix$cid"}->{u_chr hex $1}->{"adobe:uni".$suffix.":v"} = 1;
          } elsif ($_ eq '*') {
            #
          } else {
            warn $_;
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
            $Data->{variants}->{"$prefix$cid"}->{"$gl_prefix$jis"}->{"adobe:".$suffix} = 1;
          } elsif (/^([0-9A-Fa-f]{2})([0-9A-fa-f]{2})v$/) {
            my $jis = sprintf '%d-%d-%d', $p, (hex $1)-0x20, (hex $2)-0x20;
            $Data->{variants}->{"$prefix$cid"}->{"$gl_prefix$jis"}->{"adobe:".$suffix.':v'} = 1;
          } elsif ($_ eq '*') {
            #
          } else {
            warn $_;
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
        [17, 1, 'jis78'],
      ) {
        my $v = $s[$_->[0]-1];
        my $p = $_->[1];
        my $t = $_->[2];
        if ($v eq '*') {
          #
        } elsif ($v =~ /^([0-9]+)-([0-9]+)$/) {
          my $jis = sprintf '%d-%d-%d', $p, $1, $2;
          $Data->{variants}->{":aj$cid"}->{":jis$jis"}->{"adobe:$t"} = 1;
        } else {
          warn $v;
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
          $Data->{variants}->{":aj$cid"}->{":jis$jis"}->{"adobe:$t"} = 1;
        } else {
          warn $v;
        }
      }

      if ($s[11-1] eq '*') {
        #
      } elsif ($s[11-1] =~ /^CID\+([0-9]+)$/) {
        $Data->{variants}->{':aj'.(0+$1)}->{":aj$cid"}->{"adobe:trad"} = 1;
      } else {
        warn $s[11-1];
      }

      my $vss = $s[20-1];
      for (split /:/, $vss) {
        if (m{^<U\+([0-9A-F]+),U\+([0-9A-F]+)>$}) {
          #$Data->{variants}->{":aj$cid"}->{u_hexs $1 . ' ' . $2}->{"adobe:vs"} = 1;
        } else {
          warn $_;
        }
      }
    }
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
      $Data->{variants}->{"$prefix$3"}->{u_hexs $1 . ' ' . $2}->{"adobe:vs"} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

for (
  ['aj17.fea', ':aj'],
  ['ac17.fea', ':ac'],
  ['ag15.fea', ':ag'],
  ['ak12.fea', ':ak1-'],
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
        if ($current_i->{$c1} or
            (keys %{$current_x->{$c1} or {}} and not $feat =~ /alt$/)) {
          $Data->{variants}->{$c1}->{$c2}->{"opentype:$feat:contextual"} = 1;
        } else {
          $Data->{variants}->{$c1}->{$c2}->{"opentype:$feat"} = 1;
        }
      }
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
