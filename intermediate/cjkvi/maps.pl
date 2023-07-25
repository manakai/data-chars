use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/icjkvi');

my $Data = {};

{
  my $path = $TempPath->child ('cjkvi-dict/kx2ucs.txt');
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    use utf8;
    if (/^#/) {
      #
    } elsif (/^KX([0-9]+)\.([0-9X]+)\t(?:(\p{Han})|(①)|(\p{Ideographic_Description_Characters}[\p{Han}\p{Ideographic_Description_Characters}]*)|GKX-([0-9]+)\.([0-9]+)|)(\*|)(?:\t# (?:(\p{Ideographic_Description_Characters}[\p{Han}\p{Ideographic_Description_Characters}]+)|Unihan (?:は|is) "(\p{Han})"|同形異字|(\p{Han})|([\(\[](\p{Han})[\)\]])|柵の形が微妙に違う)|)$/) {
      my @v = (undef, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);
      my $c1;
      if ($v[2] =~ /X/) {
        $c1 = sprintf ':cjkvi:KX%s.%s', $v[1], $v[2];
      } else {
        $c1 = sprintf ':kx%d-%d', $v[1], $v[2];
      }
      my $c2;
      if (defined $v[3]) {
        $c2 = $v[3];
      } elsif (defined $v[4]) {
        $c2 = ':cjkvi:' . $v[4];
      } elsif (defined $v[5]) {
        $c2 = (wrap_ids $v[5], ':cjkvi:') // die $v[5];
      } elsif (defined $v[6]) {
        $c2 = sprintf ':kx%d-%d', $v[6], $v[7];
      }
      my $key = 'hans';
      $key = get_vkey $c2 if defined $c2 and not defined $v[6];
      my $vtype = 'cjkvi:kx2ucs';
      $vtype .= ':*' if $v[8];
      if (defined $v[5]) {
        $Data->{idses}->{$c1}->{$c2}->{$vtype} = 1 if defined $c2;
      } else {
        $Data->{$key}->{$c1}->{$c2}->{$vtype} = 1 if defined $c2;
      }
      if (defined $v[9]) {
        my $c9 = (wrap_ids $v[9], ':cjkvi:') // die $v[9];
        $Data->{idses}->{$c1}->{$c9}->{'cjkvi:kx2ucs:#'} = 1;
      }
      if (defined $v[10]) {
        my $c10 = $v[10];
        $Data->{$key}->{$c1}->{$c10}->{'cjkvi:kx2ucs:Unihan'} = 1;
      }
      if (defined $v[11]) {
        my $c11 = $v[11] // $v[12];
        $Data->{$key}->{$c1}->{$c11}->{'cjkvi:kx2ucs:#'} = 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $TempPath->child ('cjkvi-dict/dkw2ucs.txt');
  for (split /\x0A/, decode_web_utf8 $path->slurp) {
    use utf8;
    if (/^#/) {
      #
    } elsif (/^D(H|)([0-9]+)\.([012]) DR([0-9]+) DS([0-9]+|\?\?) DP([HX]?[0-9]+|\Q?????\E)(\s.+|)$/) {
      my $c1 = sprintf ':m%s%d%s', $1 ? 'h' : '', $2, {0 => '', 1 => "'", 2 => "''"}->{$3};
      my $x = $7 . ' ';
      $x =~ s/^\s+//;
      my $in_comment = 0;
      my $key;
      while (length $x) {
        use utf8;
        if ($x =~ s{^U\+([0-9A-F]+)\s+}{}) {
          my $c2 = chr hex $1;
          $key //= get_vkey $c2;
          my $rel_type = 'cjkvi:dkw2ucs';
          $rel_type .= ':#' if $in_comment;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
        } elsif ($x =~ s{^(\p{Han})(本字|)\s+}{}) {
          my $c2 = $1;
          $key //= 'hans';
          die unless $in_comment;
          if ($2) {
            $Data->{$key}->{$c1}->{$c2}->{'cjkvi:dkw2ucs:本字 of'} = 1;
          } else {
            $Data->{$key}->{$c1}->{$c2}->{'cjkvi:dkw2ucs:#'} = 1;
          }
        } elsif ($x =~ s{^U\+([0-9A-F]+)は別字。\s+}{}) {
          my $c2 = chr hex $1;
          $key //= 'hans';
          die unless $in_comment;
          $Data->{$key}->{$c1}->{$c2}->{'cjkvi:dkw2ucs:別字'} = 1;
        } elsif ($x =~ s{^D([0-9]+)\.(0)\s+}{}) {
          my $c2 = sprintf ':m%d', $1;
          $key //= 'hans';
          if ($in_comment) {
            $Data->{$key}->{$c1}->{$c2}->{'cjkvi:dkw2ucs:別字'} = 1;
          } else {
            $Data->{$key}->{$c1}->{$c2}->{'cjkvi:dkw2ucs:重複漢字'} = 1;
          }
        } elsif ($x =~ s{^(\p{Ideographic_Description_Characters}(?>[\p{Han}\p{Ideographic_Description_Characters}？\x{E000}-\x{F7FF}]|&CDP-86E8;)+)\s+}{}) {
          my $c2 = (wrap_ids $1, ':cjkvi:') // die $1;
          die unless $in_comment;
          $Data->{idses}->{$c1}->{$c2}->{'cjkvi:ids'} = 1;
        } elsif ($x =~ s{^# missing\s+$}{}) {
          #
        } elsif ($x =~ s{^# }{}) {
          $in_comment = 1;
        } elsif ($x =~ s{^(moved\[([012])\]) → D([0-9]+)\.([012])\s+}{}) {
          my $c2 = sprintf ':m%s%d%s', '', $3, {0 => '', 1 => "'", 2 => "''"}->{$4};
          $key //= 'hans';
          $Data->{$key}->{$c1}->{$c2}->{'cjkvi:dkw2ucs:' . $1} = 1;
        } elsif ($x =~ s{^(added\[([012])\]) ← D([0-9]+)\.([01])\s+}{}) {
          my $c2 = sprintf ':m%s%d%s', '', $3, {0 => '', 1 => "'", 2 => "''"}->{$4};
          $Data->{$key}->{$c1}->{$c2}->{'cjkvi:dkw2ucs:' . $1 . ' from'} = 1;
        } elsif ($x =~ s{^(added\[([012])\])\s+}{}) {

        } elsif ($x =~ s{^(changed\[(1)\]) (\p{Ideographic_Description_Characters}[\p{Han}\p{Ideographic_Description_Characters}]+) → (\p{Ideographic_Description_Characters}[\p{Han}\p{Ideographic_Description_Characters}]+)\s+}{}) {
          my $c2 = (wrap_ids $3, ':cjkvi:') // die;
          my $c3 = (wrap_ids $4, ':cjkvi:') // die;
          $Data->{idses}->{$c1}->{$c2}->{'cjkvi:dkw2ucs:' . $1 . ':old'} = 1;
          $Data->{idses}->{$c1}->{$c3}->{'cjkvi:dkw2ucs:' . $1 . ':new'} = 1;
        } elsif ($x =~ s{^(changed\[(1)\])\s+}{}) {

        } elsif ($x =~ s{^(replaced\[([12])\]) → D([0-9]+)\.([012]) ← D([0-9]+)\.(0)\s+}{}) {
          my $c2 = sprintf ':m%s%d%s', '', $3, {0 => '', 1 => "'", 2 => "''"}->{$4};
          my $c3 = sprintf ':m%s%d%s', '', $5, {0 => '', 1 => "'", 2 => "''"}->{$6};
          $Data->{$key}->{$c1}->{$c2}->{'cjkvi:dkw2ucs:' . $1 . ' to'} = 1;
          $Data->{$key}->{$c1}->{$c3}->{'cjkvi:dkw2ucs:' . $1 . ' from'} = 1;
        } elsif ($x =~ s{^(removed\[(1)\]) → D([0-9]+)\.(0)\s+}{}) {
          my $c2 = sprintf ':m%s%d%s', '', $3, {0 => '', 1 => "'", 2 => "''"}->{$4};
          $key //= 'hans';
          $Data->{$key}->{$c1}->{$c2}->{'cjkvi:dkw2ucs:' . $1} = 1;
        } elsif ($x =~ s{^(removed\[(1)\])\s+}{}) {

        } else {
          die "Bad line |$_| ($x)";
        }
      }
      
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'maps',
    [
      qr/^:kx1/,
      qr/^:m[12]/,
      qr/^:m/,
    ];

## License: Public Domain.
