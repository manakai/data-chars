use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');
my $DataPath = $RootPath->child ('local/generated/charrels/glyphs/gwglyphs');
my $MapsPath = $RootPath->child ('local/maps');
$MapsPath->mkpath;

my $Data = {};
sub gid ($) {
  my $g1 = shift;
  my $g2 = $g1;
  my $g0 = $g1;
  my $impl = 1;

  if ($g2 =~ s/\@[0-9]+$//) {
    $Data->{glyphs}->{':gw-'.$g2}->{':gw-'.$g1}->{'glyphwiki:revision'} = 1;
    $g1 = $g2;
  }

  if ($g2 =~ s/-(var|itaiji)-[0-9]+$//) {
    $Data->{glyphs}->{':gw-'.$g2}->{':gw-'.$g1}->{'glyphwiki:' . $1} = 1;
    $g1 = $g2;
    $impl = 0 if $1 eq 'itaiji';
  }

  if ($g2 =~ s/^(u[0-9a-f]+)-([gtjkvhui]|kp|us|ja|js|[jgktv]v|)(0[1-9]|1[0145]|24|)$/$1/) {
    if (length $2 and length $3) {
      $Data->{glyphs}->{':gw-'.$g2.'-'.$2}->{':gw-'.$g1}->{'glyphwiki:'.$3} = 1;
      $Data->{glyphs}->{':gw-'.$g2}->{':gw-'.$g2.'-'.$2}->{'glyphwiki:'.$2} = 1;
      $g1 = $g2;
    } elsif (length $3) {
      $Data->{glyphs}->{':gw-'.$g2}->{':gw-'.$g1}->{'glyphwiki:'.$3} = 1;
      $g1 = $g2;
    } elsif (length $2) {
      $Data->{glyphs}->{':gw-'.$g2}->{':gw-'.$g1}->{'glyphwiki:'.$2} = 1;
      $g1 = $g2;
    } else {
      $g2 = $g1;
    }
  } elsif ($g2 =~ s/-(0[1-9]|1[0145]|24|vert|halfwidth|fullwidth|small|sans|italic)$//) {
    $Data->{glyphs}->{':gw-'.$g2}->{':gw-'.$g1}->{'glyphwiki:'.$1} = 1;
    $g1 = $g2;
  }

  if ($impl) {
    if ($g1 =~ /^u[0-9a-f]+(?:-u[0-9a-f]+)*$/) {
      my $c2 = wrap_string join '', map { s/^u//; chr hex $_ } split /-/, $g1;
      if ($c2 =~ /^\p{Ideographic_Description_Characters}./) {
        $c2 = wrap_ids $c2, ':gw-';
        $c2 = ':gw-' . $g1 if $c2 =~ /^:gw-/;
        $Data->{descs}->{':gw-'.$g0}->{$c2}->{'glyphwiki:ids'} = 1;
        my @c = split_ids $c2;
        for my $c3 (@c) {
          $Data->{components}->{':gw-'.$g0}->{$c3}->{'glyphwiki:ids:contains'} = 1;
        }
      } else {
        $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
        my @c = split_for_string_contains $c2;
        if (@c > 1) {
          for my $c3 (@c) {
            $Data->{components}->{$c2}->{$c3}->{'string:contains'} = 1;
          }
        }
      }
    } elsif ($g1 =~ /^aj1-([0-9]+)$/) {
      my $c2 = sprintf ':aj%d', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^ak1-([0-9]+)$/) {
      my $c2 = sprintf ':ak1-%d', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^b-([0-9a-f]+)$/) {
      my $c2 = sprintf ':b5-%x', hex $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^hka-([0-9a-f]+)$/) {
      my $c2 = sprintf ':b5-%x', hex $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements:HKA'} = 1;
    } elsif ($g1 =~ /^c([1-9a-f])-([0-9a-f]{2})([0-9a-f]{2})$/) {
      my $c2 = sprintf ':cns%d-%d-%d', hex $1, (hex $2)-0x20, (hex $3)-0x20;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^cdp-([0-9a-f]+)$/) {
      my $c2 = sprintf ':b5-cdp-%x', hex $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^dkw-(h|)([0-9]+)(d{0,2})$/) {
      my $c2 = sprintf ':m%s%d%s', $1, $2, "'" x (length $3);
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^extf-([0-9]+)$/) {
      my $c2 = sprintf ':extf-%d', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^irg2017-([0-9]+)$/) {
      my $c2 = sprintf ':irg2017-%d', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^g([0123458])-([0-9a-f]{2})([0-9a-f]{2})$/) {
      my $c2 = sprintf ':gb%d-%d-%d', {
        0 => 0, 1 => 0, 2 => 2, 3 => 2, 4 => 4, 5 => 4, 8 => 0,
      }->{$1}, (hex $2) - 0x20, (hex $3) - 0x20;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'glyphwiki:implements:g'.$1} = 1;
    } elsif ($g1 =~ /^g([eks])-([0-9a-f]{2})([0-9a-f]{2})$/) {
      my $c2 = sprintf ':gb%d-%d-%d', ((ord $1) - (ord 'a') + 10),
          (hex $2) - 0x20, (hex $3) - 0x20;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^g([h])-([0-9]{2})([0-9]{2})$/) {
      my $c2 = sprintf ':gb%d-%d-%d', 0, $2, $3;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'glyphwiki:implements:g'.$1} = 1;
    } elsif ($g1 =~ /^g-kx([0-9]{4})([0-9]{2})$/) {
      my $c2 = sprintf ':kx%d-%d', $1, $2;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'glyphwiki:implements:g-kx'} = 1;
    } elsif ($g1 =~ /^gt-([0-9]+)$/) {
      my $c2 = sprintf ':gt%d', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^gt-k([0-9]+)$/) {
      my $c2 = sprintf ':gtk%d', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^hb1-([0-9a-f]{4})$/) {
      my $c2 = sprintf ':b5-hkscs-%x', hex $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^heisei-([0-9a-z]+)$/) {
      my $c2 = ':' . uc $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^(j78|j83|j90|jx1-2000|jx1-2004|jx2|jsp)-([0-9a-f]{2})([0-9a-f]{2})$/) {
      my $p = {jx2 => 2, jsp => 2}->{$1} || 1;
      my $c2 = sprintf ':jis%d-%d-%d', $p, (hex $2) - 0x20, (hex $3) - 0x20;
      if ($p == 2) {
        $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
      } else {
        $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'glyphwiki:implements:'.$1} = 1;
      }
    } elsif ($g1 =~ /^j-arib-([0-9a-f]{2})([0-9a-f]{2})$/) {
      my $c2 = sprintf ':jis-arib-%d-%d-%d', 1, (hex $1) - 0x20, (hex $2) - 0x20;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^jk-([0-9]+)$/) {
      my $c2 = sprintf ':m%d', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^jmj-([0-9]{6})$/) {
      my $c2 = ':MJ' . $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^k([01])-([0-9a-f]{2})([0-9a-f]{2})$/) {
      my $c2 = sprintf ':ks%d-%d-%d', $1, (hex $2) - 0x20, (hex $3) - 0x20;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^kp1-([0-9a-f]+)$/) {
      my $c2 = sprintf ':kp1-%x', hex $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^koseki-([0-9]{6})$/) {
      my $c2 = ':koseki' . $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^kx-([0-9]{4})([0-9]{3})$/) {
      my $c2 = sprintf ':kx%d-%d', $1, $2;
    } elsif ($g1 =~ /^simch-kx_t([0-9]{4})([0-9]{2})$/) {
      my $c2 = sprintf ':kx%d-%d', $1, $2;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^nyukan-([0-9a-f]+)$/) {
      my $c2 = sprintf ':u-immi-%x', hex $1;
      my $c2_0 = u_chr hex $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
      $Data->{descs}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    } elsif ($g1 =~ /^ninjal-([0-9]+)$/) {
      my $c2 = sprintf ':ninjal%s', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^toki-([0-9]{8})$/) {
      my $c2 = ':touki' . $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^sat_g9([0-9]+)$/) {
      my $c2 = sprintf ':sat%d', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^z-sat([0-9]+)$/) {
      my $c2 = sprintf ':sat%d', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^tron-([0-9]+)-([0-9a-f]+)$/) {
      my $c2 = sprintf ':tron%d-%x', $1, hex $2;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^((?:uci|utc|uk)-[0-9]+)$/) {
      my $c2 = ':'.uc $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^(md|hu|tu|gu|ku|kpu)-([0-9a-f]+)$/) {
      my $c2 = u_chr hex $2;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements:' . uc $1} = 1;
    } elsif ($g1 =~ /^(vn)-([0-9a-f]+)$/) {
      my $code2 = hex $2;
      if ($code2 < 0xF0000) {
        my $c2 = u_chr $code2;
        $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements:' . uc $1} = 1;
      } else {
        my $c2 = sprintf ':u-nom-%x', hex $2;
        my $c2_0 = u_chr hex $2;
        $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
        $Data->{descs}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
    } elsif ($g1 =~ /^vnpf-([0-9a-f]+)$/) {
      my $c2 = sprintf ':u-nom-%x', hex $1;
      my $c2_0 = u_chr hex $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
      $Data->{descs}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    } elsif ($g1 =~ /^z-sat-([0-9]+)$/) {
      my $c2 = sprintf ':sat%d', $1;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    } elsif ($g1 =~ /^waseikanji-no-jiten-([0-9]+)([a-z]*)$/) {
      my $c2 = sprintf ':wasei%d%s', $1, $2;
      $Data->{glyphs}->{':gw-'.$g0}->{$c2}->{'manakai:implements'} = 1;
    }
  } # $impl
}

{
  my $data = {};
  my $path = $TempPath->child ('gwalias.txt');
  my $file = $path->openr;
  while (<$file>) {
    my ($g1, $g2) = split /\s+/, $_;
    $data->{glyphs}->{':gw-' . $g1}->{':gw-' . $g2}->{'glyphwiki:alias'} = 1;
    gid $g1;
    gid $g2;
    if ($g1 =~ /^juki-([0-9a-f]+)$/) {
      my $x1 = $1;
      my $code1 = hex $1;
      if (($g2 =~ /^u([0-9a-f]+)/ and $1 eq $x1) or
          0xFF00 <= $code1) {
        my $c2 = u_chr $code1;
        $Data->{glyphs}->{':gw-'.$g1}->{$c2}->{'manakai:implements:juki'} = 1;
      } else {
        my $c2 = sprintf ':u-juki-%x', $code1;
        my $c2_0 = u_chr $code1;
        $Data->{glyphs}->{':gw-'.$g1}->{$c2}->{'manakai:implements'} = 1;
        $Data->{descs}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
    }
  }

  write_rel_data_sets
      $data => $MapsPath, 'gwaliases',
      [];
}
{
  my $data = {};
  my $path = $TempPath->child ('gwrelated.txt');
  my $file = $path->openr;
  while (<$file>) {
    my ($g1, $g2) = split /\s+/, $_;
    if ($g1 eq $g2) {
      #
    } elsif ($g2 =~ /^u([0-9a-f]+)$/) {
      my $c2 = u_chr hex $1;
      $data->{glyphs}->{':gw-' . $g1}->{$c2}->{'glyphwiki:related'} = 1;
    } else {
      $data->{glyphs}->{':gw-' . $g1}->{':gw-' . $g2}->{'glyphwiki:related'} = 1;
    }
    gid $g1;
    if ($g1 =~ /^juki-([0-9a-f]+)$/) {
      my $code1 = hex $1;
      if ($g2 eq 'u'.$1 or $code1 < 0xA000 or 0xFF00 <= $code1) {
        my $c2 = u_chr $code1;
        $Data->{glyphs}->{':gw-'.$g1}->{$c2}->{'manakai:implements:juki'} = 1;
      } else {
        my $c2 = sprintf ':u-juki-%x', $code1;
        my $c2_0 = u_chr $code1;
        $Data->{glyphs}->{':gw-'.$g1}->{$c2}->{'manakai:implements'} = 1;
        $Data->{descs}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
    }
  }

  write_rel_data_sets
      $data => $MapsPath, 'gwrelated',
      [];
}
{
  my $path = $TempPath->child ('gwothers.txt');
  my $file = $path->openr;
  while (<$file>) {
    my ($g1) = split /\s+/, $_;
    gid $g1;
  }
}
{
  my $data = {};
  my $path = $TempPath->child ('gwcontains.txt');
  my $file = $path->openr;
  while (<$file>) {
    my ($g1, $g2) = split /\s+/, $_;
    $data->{components}->{':gw-' . $g1}->{':gw-' . $g2}->{'glyphwiki:contains'} = 1;
  }

  write_rel_data_sets
      $data => $MapsPath, 'gwcontains',
      [];
}

write_rel_data_sets
    $Data => $MapsPath, 'gwrels',
    [];

## License: Public Domain.

