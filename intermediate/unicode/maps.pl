use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' }

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iuc');

my $IVDVersion = $ENV{IVD_VERSION} || die "No |IVD_VERSION|";

my $Data = {};

{
  my $path = $TempPath->child ('unihan3.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kCNS1986|kCNS1992)\s+([0-9A-F])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':cns%d-%d-%d', hex $3, (hex $4) - 0x20, (hex $5) - 0x20;
      my $c1 = u_chr hex $1;
      my $type = "unihan3.0:$2";
      my $key = get_vkey $c1;
      if ($3 eq 'E') {
        my $part1 = ((hex $4) <= 0x61 or
                     ((hex $4) == 0x62 and (hex $5) <= 0x46));
        my $part3 = (((hex $4) >= 0x65) or
                     ((hex $4) == 0x64 and (hex $5) >= 0x36));
        my $c2_0 = $c2;
        $c2 =~ s/^:cns/:cns-old-/;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        if ($part1 or $part3) {
          my $c3 = $c2;
          $c3 =~ s/^:cns-old-14/:cns3/;
          $Data->{$key}->{$c2}->{$c3}->{'cns11643:moved'} = 1;
        }
      } else {
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif (/^U\+([0-9A-F]+)\s+(kGB0|kGB1|kGB8)\s+(\d\d)(\d\d)$/) {
      my $c1 = u_chr hex $1;
      my $c2 = sprintf ':gb%d-%d-%d', 0, $3, $4;
      my $rel_type = "unihan3.0:$2";
      my $key = get_vkey $c1;
      if ($c2 =~ /^:gb0-15-(89|9[012])$/) {
        my $c2_0 = $c2;
        $c2 =~ s/^:gb0-/:gb8-/g;
        $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kPseudoGB1)\s+(\d\d)(\d\d)$/) {
      my $c2 = sprintf ':gb%d-%d-%d', 1, $3, $4;
      $Data->{hans}->{u_chr hex $1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kGB3)\s+(\d\d)(\d\d)$/) {
      my $c2 = sprintf ':gb%d-%d-%d', 2, $3, $4;
      $Data->{hans}->{u_chr hex $1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kGB5)\s+(\d\d)(\d\d)$/) {
      my $c2 = sprintf ':gb%d-%d-%d', 4, $3, $4;
      $Data->{hans}->{u_chr hex $1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_GSource)\s+([01358])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':gb%d-%d-%d', {
        0 => '0',
        1 => '0',
        3 => '2',
        5 => '4',
        8 => '0',
      }->{$3}, (hex $4) - 0x20, (hex $5) - 0x20;
      my $c1 = u_chr hex $1;
      my $type = "unihan3.0:$2:$3";
      if ($3 eq "1" and (hex $4) >= 0x7A) {
        my $c2_0 = $c2;
        $c2 =~ s/^:gb0-/:gb1-/;
        $Data->{hans}->{$c1}->{$c2}->{$type} = 1;
        $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      } else {
        if ($c2 =~ /^:gb0-15-(89|9[012])$/) {
          my $c2_0 = $c2;
          $c2 =~ s/^:gb0-/:gb8-/g;
          $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        $Data->{hans}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_TSource)\s+([1-9A-F])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':cns%d-%d-%d', hex $3, (hex $4) - 0x20, (hex $5) - 0x20;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_JSource)\s+([01A])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c1 = u_chr hex $1;
      my $c2 = sprintf ':jis%d-%d-%d', 1 + hex $3, (hex $4) - 0x20, (hex $5) - 0x20;
      if ($3 eq 'A') {
        $c2 = sprintf ':jis%d-%d-%d', hex $3, (hex $4) - 0x20, (hex $5) - 0x20;
      }
      my $rel_type = "unihan3.0:$2";
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_KSource)\s+([0123])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':ks%d-%d-%d', $3, (hex $4) - 0x20, (hex $5) - 0x20;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_VSource)\s+([0])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $code1 = hex $1;
      my $c1 = u_chr $code1;
      my $c2 = sprintf ':v%d-%d-%d', $3, (hex $4) - 0x20, (hex $5) - 0x20;
      if ($3) {
        my $ten = (hex $5) - 0x20 - 9;
        my $ku = (hex $4) - 0x20 + 41;
        if ($ten < 1) {
          $ten += 94;
          $ku--;
        }
        $c2 = sprintf ':v%d-%d-%d', $3, $ku, $ten;
      } elsif ($code1 >= 0x4E00) {
        $c2 = sprintf ':v%d-%d-%d', $3, (hex $4) - 0x20 + 15, (hex $5) - 0x20;
      }
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan3.0:$2:$3"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kAlternateKangXi)\s+([0-9]+)\.([0-9]+)$/) {
      my $c2 = sprintf ':kx%d-%d', $3, $4;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kKangXi|kIRGKangXi)\s+(0000)\.([0-9]{3})$/) {
      my $c2 = sprintf ':kx%d-%d', $3, $4;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan3.0:$2:virtual"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kKangXi|kIRGKangXi)\s+((?!0000)[0-9]+)\.([0-9]{2})0$/) {
      my $c2 = sprintf ':kx%d-%d', $3, $4;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kKangXi|kIRGKangXi)\s+((?!0000)[0-9]+)\.([0-9]{2})(1)$/) {
      my $c2 = sprintf ':kx%d-%d-%d', $3, $4, $5;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan3.0:$2:virtual"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kMorohashi|kAlternateMorohashi)\s+([0-9]+)$/) {
      unless ($3 eq '00000' or $3 eq '99999') {
        my $c2 = sprintf ':m%d', $3;
        my $c1 = u_chr hex $1;
        my $key = get_vkey $c1;
        $Data->{$key}->{$c1}->{$c2}->{"unihan3.0:$2"} = 1;
      }
    } elsif (/^U\+([0-9A-F]+)\s+(kKangXi|kIRGKangXi|kIRG_KSource)\s+/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-g.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_GSource)\s+G([013578EKS])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':gb%d-%d-%d', {
        0 => '0',
        1 => '0',
        3 => '2',
        5 => '4',
        7 => '7',
        E => (hex 'E'),
        8 => '0',
        K => 10 + (ord 'K') - (ord 'A'),
        S => 10 + (ord 'S') - (ord 'A'),
      }->{$3}, (hex $4) - 0x20, (hex $5) - 0x20;
      my $c1 = u_chr hex $1;
      my $type = "unihan:$2:$3";
      if ($3 eq "1" and (hex $4) >= 0x7A) {
        my $c2_0 = $c2;
        $c2 =~ s/^:gb0-/:gb1-/;
        $Data->{hans}->{$c1}->{$c2}->{$type} = 1;
        $Data->{codes}->{$c2}->{$c1}->{'manakai:private'} = 1;
      } else {
        if ($c2 =~ /^:gb0-15-(89|9[012])$/) {
          my $c2_0 = $c2;
          $c2 =~ s/^:gb0-/:gb8-/g;
          $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        $Data->{hans}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_GSource)\s+GH-([0-9]{2})([0-9]{2})$/) {
      my $c1 = u_chr hex $1;
      my $c2 = sprintf ':gb%d-%d-%d', 17, $3, $4;
      my $c2_0 = sprintf ':gb%d-%d-%d', 0, $3, $4;
      my $key = get_vkey $c1;
      $Data->{hans}->{$c1}->{$c2}->{"unihan:$2:H"} = 1;
      $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_GSource)\s+GKX-([0-9]+)\.([0-9]{2})$/) {
      my $c1 = u_chr hex $1;
      my $c2 = sprintf ':kx%d-%d', $3, $4;
      my $key = get_vkey $c1;
      $Data->{hans}->{$c1}->{$c2}->{"unihan:$2:KX"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_GSource)\s+GKX-([0-9]+)\.(104)$/) {
      my $c1 = u_chr hex $1;
      my $c2 = sprintf ':kx%d-%d', $3, $4;
      my $key = get_vkey $c1;
      $Data->{hans}->{$c1}->{$c2}->{"unihan:$2:KX"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_GSource)\s+GKX-/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-t.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_TSource)\s+T([0-9A-F]+)-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2";
      my $c2 = sprintf ':cns%d-%d-%d', (hex $3), (hex $4)-0x20, (hex $5)-0x20;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_TSource)\s+TU-/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_TSource)\s+/) {
      die "Bad line |$_|";
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-s.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_SSource)\s+SAT-([0-9]+)$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2";
      my $c2 = sprintf ':sat%d', $3;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('unihan15-irg-v.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_VSource)\s+VN-([0-9A-Fa-f]+)$/) {
      my $code2 = hex $3;
      if ($code2 >= 0xF0000) {
        my $c1 = u_chr hex $1;
        my $rel_type = "unihan15:$2";
        my $c2 = sprintf ':u-nom-%x', $code2;
        my $key = get_vkey $c1;
        $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
        my $c2_0 = chr $code2;
        $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_VSource)\s+V([01234])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c1 = u_chr hex $1;
      my $c2 = sprintf ':v%d-%d-%d',
          {
            0 => 0,
            1 => 1, 2 => 1,
            3 => 3, 4 => 3,
          }->{$3}, (hex $4) - 0x20, (hex $5) - 0x20;
      my $rel_type = "unihan15:$2";
      $rel_type .= ":$3" if $3 > 0;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-v.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_VSource)\s+VN-([0-9A-Fa-f]+)$/) {
      my $code2 = hex $3;
      if ($code2 >= 0xF0000) {
        my $c1 = u_chr hex $1;
        my $rel_type = "unihan:$2";
        my $c2 = sprintf ':u-nom-%x', $code2;
        my $key = get_vkey $c1;
        $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
        my $c2_0 = chr $code2;
        $Data->{codes}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      }
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_VSource)\s+V([01234])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c1 = u_chr hex $1;
      my $c2 = sprintf ':v%d-%d-%d',
          {
            0 => 0,
            1 => 1, 2 => 1,
            3 => 3, 4 => 3,
          }->{$3}, (hex $4) - 0x20, (hex $5) - 0x20;
      my $rel_type = "unihan:$2";
      $rel_type .= ":$3" if $3 > 0;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('unihan-irg-k.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_KSource)\s+K([0123])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2";
      my $c2 = sprintf ':ks%d-%d-%d', $3, (hex $4)-0x20, (hex $5)-0x20;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_KSource)\s+K([456])-([0-9A-F]{4})$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2";
      my $c2 = sprintf ':ks%d-%x', $3, (hex $4);
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    }
  }
}

{
  my $path = $TempPath->child ('unihan15-irg-kp.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_KPSource)\s+KP0-([A-F][0-9A-F])([A-F][0-9A-F])$/) {
      my $c2 = sprintf ':kps0-%d-%d', (hex $3) - 0xA0, (hex $4) - 0xA0;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan15:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_KPSource)\s+KP1-([0-9A-F]{4})$/) {
      my $c2 = sprintf ':kps1-%x', hex $3;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan15:$2"} = 1;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-kp.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_KPSource)\s+KP0-([A-F][0-9A-F])([A-F][0-9A-F])$/) {
      my $c2 = sprintf ':kps0-%d-%d', (hex $3) - 0xA0, (hex $4) - 0xA0;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_KPSource)\s+KP1-([0-9A-F]{4})$/) {
      my $c2 = sprintf ':kps1-%x', hex $3;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan:$2"} = 1;
    }
  }
}

{
  my $path = $TempPath->child ('unihan-kangxi.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kKangXi|kIRGKangXi)\s+([0-9]+)\.([0-9]{2})([0-9])$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2";
      my $c2 = sprintf ':kx%d-%d', $3, $4;
      if ($3 eq '0000') {
        $c2 = sprintf ':kx%d-%d', $3, $4 * 10 + $5;
        $rel_type .= ':virtual';
      } else {
        $c2 .= '-' . $5 if $5;
        $rel_type .= ':virtual' if $5;
      }
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kKangXi|kIRGKangXi)\s+/) {
      die $_;
    }
  }
}

for (
  ['unihan15-morohashi.txt', 'unihan15'],
  ['unihan15-irg-daikanwa.txt', 'unihan15'],
  ['unihan-morohashi.txt', 'unihan'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $prefix = $_->[1];
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (s/^U\+([0-9A-F]+)\t(kMorohashi|kIRGDaiKanwaZiten)\t//) {
      my $c1 = u_chr hex $1;
      my $rel_type = "$prefix:$2";
      my $key = get_vkey $c1;
      for (split / /, $_) {
        if (m{^([0-9]+)(''?|)$}) {
          my $c2 = sprintf ':m%d%s', $1, $2;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
        } elsif (m{^([0-9]+)(''?|):([0-9A-F]+)$}) {
          my $c3 = $c1 . chr hex $3;
          my $c2 = sprintf ':m%d%s', $1, $2;
          $Data->{$key}->{$c3}->{$c2}->{$rel_type} = 1;
        } elsif (m{^H([0-9]+)$}) {
          my $c2 = sprintf ':mh%d', $1;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
        } elsif (m{^H([0-9]+):([0-9A-F]+)$}) {
          my $c3 = $c1 . chr hex $2;
          my $c2 = sprintf ':mh%d', $1;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
        } else {
          die $_;
        }
      }
    }
  }
}

{
  my $path = $TempPath->child ('kVariants.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\S+ \(U\+([0-9A-F]+)\)\s+(\S+)\s+\S+ \(U\+([0-9A-F]+)\)$/) {
      my $c1 = chr hex $1;
      my $c2 = chr hex $3;
      my $vkey = get_vkey $c1;
      $Data->{$vkey}->{$c1}->{$c2}->{'kVariants:' . $2} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('MathClassExt.txt');
  my $file = $path->openr;
  while (<$file>) {
    s/^003B;P;;;/003B;P;;/;
    if (/^\s*#/) {
      #
    } elsif (/\S/) {
      my @r = split /;/, $_;
      if (length $r[3]) {
        my $c1;
        if ($r[0] =~ /^([0-9A-F]+)$/) {
          $c1 = u_chr hex $1;
        } else {
          die $r[0];
        }
        my $c2 = $r[3];
        $Data->{descs}->{$c1}->{$c2}->{'ucd:ISO entity name'} = 1;
      }
    }
  }
}

{
  my $path = $TempPath->child ('unihan-irg-h.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_HSource)\s+H-([0-9A-F]{4})$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2";
      my $c2 = sprintf ':b5-hkscs-%x', hex $3;
      my $c2_0 = $c2;
      $c2_0 =~ s/^:b5-hkscs-/:b5-/g;
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
      $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_HSource)\s+HB[12]-([0-9A-F]{4})$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2";
      my $c2 = sprintf ':b5-%x', hex $3;
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-m.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_MSource)\s+(M[AB][12]?)-([0-9A-F]{4})$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2:$3";
      my $c2 = sprintf ':b5-hkscs-%x', hex $4;
      my $c2_0 = $c2;
      $c2_0 =~ s/^:b5-hkscs-/:b5-/g;
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
      $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-uk.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_UKSource)\s+(UK-[0-9]+)$/) {
      my $c2 = ':' . $3;
      $Data->{hans}->{u_chr hex $1}->{$c2}->{"unihan:$2"} = 1;
    }
  }
}

for (
  [q(irgn2107r2-uk.tsv), 'uka'],
  [q(irgn2232r-uk.tsv), 'ukb'],
) {
  my $path = $ThisPath->child ($_->[0]);
  my $up = $_->[1];
  my $file = $path->openr;
  while (<$file>) {
    if (/^(UK-[0-9]+)\t(?:U\+|)([0-9A-F]{4})\t?$/) {
      my $c2 = sprintf ':u-%s-%x', $up, hex $2;
      my $c2_0 = chr hex $2;
      $Data->{glyphs}->{":$1"}->{$c2}->{"uk:font-code-point"} = 1;
      die "Duplicate $c2" if $Data->{glyphs}->{$c2_0}->{$c2}->{'manakai:private'};
      $Data->{glyphs}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    } elsif (/^(UK-[0-9]+)\t(?:U\+|)([0-9A-F]{4})\t([0-9]{2})-([0-9]{2})$/) {
      my $c2 = sprintf ':u-%s-%x', $up, hex $2;
      my $c2_0 = chr hex $2;
      my $c3 = sprintf ':gb8-%d-%d', $3, $4;
      $Data->{glyphs}->{":$1"}->{$c2}->{"uk:font-code-point"} = 1;
      die "Duplicate $c2" if $Data->{glyphs}->{$c2_0}->{$c2}->{'manakai:private'};
      $Data->{glyphs}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      $Data->{hans}->{":$1"}->{$c3}->{"uk:gb8"} = 1;
      # SJ/T 11239-2001
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('USourceData.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } else {
      my @line = split /;/, $_;

      my $c1;
      if ($line[0] =~ m{^(UTC-[0-9]+)$}) {
        $c1 = ':' . $1;
      } elsif ($line[0] =~ m{^(UCI-[0-9]+)$}) {
        $c1 = ':' . $1;
      } elsif ($line[0] =~ m{^(UK-[0-9]+)$}) {
        $c1 = ':' . $1;
      } elsif (/\S/) {
        die "Bad line |$_|";
      } else {
        next;
      }

      my @c2;
      if ($line[2] =~ m{^U\+([0-9A-F]+)$}) {
        push @c2, chr hex $1;
      } elsif ($line[2] =~ m{^U\+([0-9A-F]+) U\+([0-9A-F]+)$}) {
        push @c2, chr hex $1;
        push @c2, chr hex $2;
      } elsif ($line[2] =~ m{^U\+([0-9A-F]+) U\+([0-9A-F]+) U\+([0-9A-F]+)$}) {
        push @c2, chr hex $1;
        push @c2, chr hex $2;
        push @c2, chr hex $3;
      } elsif ($line[2] =~ m{^(UTC-[0-9]+)$}) {
        push @c2, ':' . $1;
      } elsif (length $line[2]) {
        die "Bad line |$_| ($line[2])";
      }
      my $key = 'hans';
      if (@c2) {
        $key = get_vkey $c2[0] unless $line[0] =~ /^UTC-/;
        for my $c2 (@c2) {
          if ($line[1] =~ m{^(URO|Comp|Ext[A-Z]+)$}) {
            $Data->{$key}->{$c1}->{$c2}->{'ucd:Unicode'} = 1;
          } else {
            $Data->{$key}->{$c1}->{$c2}->{'ucd:Unicode:related'} = 1;
          }
        }
      }

      if (length $line[5]) {
        my $c5 = wrap_ids $line[5], ':utc:';
        if (not defined $c5 and $line[5] =~ /^\p{Han}{2}$/) {
          $c5 = ':utc:' . $line[5];
        }
        die $line[5] unless defined $c5;
        $Data->{idses}->{$c1}->{$c5}->{'ucd:IDS'} = 1;
        my @c = split_ids $c5;
        for my $c6 (@c) {
          $Data->{components}->{$c1}->{$c6}->{'ucd:IDS:contains'} = 1;
        }
      }

      for my $line (split /[:*]/, $line[6]) {
        if ($line =~ m{^WL (E[0-9A-F]{3})$}) {
          my $c6 = sprintf ':u-wl-%x', hex $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        } elsif ($line =~ m{^Adobe-Japan1 C\+([0-9]+)$}) {
          my $c6 = sprintf ':aj%d', $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        } elsif ($line =~ m{^Adobe-CNS1 C\+([0-9]+)$}) {
          my $c6 = sprintf ':ac%d', $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        } elsif ($line =~ m{^TUS U\+([0-9]+)$}) {
          my $c6 = chr hex $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        } elsif ($line =~ m{^(UTC-[0-9]+)$}) {
          my $c6 = ':' . $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        } elsif ($line =~ m{, KP1-([0-9A-F]{4}), }) {
          my $c6 = sprintf ':kps1-%x', hex $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        }
      }

      for my $line (split /[:]/, $line[7] // '') {
        if ($line =~ m{^(kSpoofingVariant|kSimplifiedVariant|kTraditionalVariant) U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $2;
          $Data->{$key}->{$c1}->{$c7}->{'unihan:' . $1} = 1;
        } elsif ($line =~ m{^(kSpoofingVariant|kSimplifiedVariant|kTraditionalVariant) (UTC-[0-9]+)$}) {
          my $c7 = ':' . $2;
          $Data->{$key}->{$c1}->{$c7}->{'unihan:' . $1} = 1;
        } elsif ($line =~ m{^Unifiable with U\+([0-9A-F]+)\x{2014}both are y-variants of U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $1;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:unifiable'} = 1;
          my $c8 = chr hex $2;
          $Data->{$key}->{$c1}->{$c8}->{'ucd:y-variant'} = 1;
        } elsif ($line =~ m{^U\+([0-9A-F]+) is a y-variant and U\+([0-9A-F]+) is a z-variant$}) {
          my $c7 = chr hex $1;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:unifiable'} = 1;
          my $c8 = chr hex $2;
          $Data->{$key}->{$c1}->{$c8}->{'unihan:kZVariant'} = 1;
        } elsif ($line =~ m{^Traditional form of U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $1;
          $Data->{$key}->{$c1}->{$c7}->{'unihan:kSimplifiedVariant'} = 1;
        } elsif ($line =~ m{^(Misidentification) of U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $2;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:'.$1.' of'} = 1;
        } elsif ($line =~ m{misinterpreted and (incorrect) form of (UTC-[0-9]+)}) {
          my $c7 = ':' . $2;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:'.$1.' of'} = 1;
        } elsif ($line =~ m{^(variant) of (\p{Han})$}) {
          my $c7 = $2;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:'.$1.' of'} = 1;
        } elsif ($line =~ m{^Variant of U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $1;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:variant of'} = 1;
        } elsif ($line =~ m{^(ligature) form of (\p{Han}\p{Han})$}) {
          my $c7 = $2;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:'.$1.' of'} = 1;
        } elsif ($line =~ m{^Similar to U\+([0-9A-F]+) U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $1;
          my $c8 = chr hex $2;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:similar'} = 1;
          $Data->{$key}->{$c1}->{$c8}->{'ucd:similar'} = 1;
        }
      } # $line[7]
    }
  }
}

my $path = $TempPath->child ('Unihan_Variants.txt');
for (split /\x0D?\x0A/, $path->slurp) {
  if (/^U\+([0-9A-F]+)\s+(\w+)\s+(.+)$/) {
    my $c1 = chr hex $1;
    my $type = 'unihan:' . $2;
    my $v = $3;
    for (split /\s+/, $v) {
      s/<.+//;
      if (/^U\+([0-9A-F]+)$/) {
        my $c2 = chr hex $1;
        my $key = get_vkey $c1;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
      } else {
        die "Bad char |$_|";
      }
    }
  }
}

{
  my $path = $TempPath->child ($IVDVersion . '/IVD_Sequences.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (s/^([0-9A-F]+) ([0-9A-F]+);\s*//) {
      my $c1 = chr hex $1;
      my $c2 = chr hex $2;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1.$c2}->{$c1}->{"ivd:base"} = 1;
      if (/^Adobe-Japan1; CID\+([0-9]+)$/) {
        $Data->{$key}->{$c1.$c2}->{':aj' . (0+$1)}->{"ivd:Adobe-Japan1"} = 1;
      } elsif (/^Hanyo-Denshi; ([A-Z0-9]+)$/) {
        $Data->{$key}->{$c1.$c2}->{':' . $1}->{"ivd:Hanyo-Denshi"} = 1;
      } elsif (/^Moji_Joho; (MJ[0-9]+)$/) {
        $Data->{$key}->{$c1.$c2}->{':' . $1}->{"ivd:Moji_Joho"} = 1;
      } elsif (/^MSARG; MA_([0-9A-F]+)$/) {
        $Data->{$key}->{$c1.$c2}->{sprintf ':b5-hkscs-%x', (hex $1)}->{"ivd:MSARG"} = 1;
      } elsif (/^MSARG; MB_([0-9A-F]+)$/) {
        $Data->{$key}->{$c1.$c2}->{sprintf ':b5-%x', (hex $1)}->{"ivd:MSARG"} = 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $TempPath->child ($IVDVersion . '/IVD_Stats.txt');
  my $in_scope = 0;
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^# Duplicate Sequence Identifiers: /) {
      $in_scope = 1;
    } elsif ($in_scope and /^# \S+ \([^:\s]+: <([0-9A-F]+),([0-9A-F]+)>, <([0-9A-F]+),([0-9A-F]+)>\)$/) {
      my $c1 = (chr hex $1) . (chr hex $2);
      my $c2 = (chr hex $3) . (chr hex $4);
      $Data->{hans}->{$c1}->{$c2}->{"ivd:duplicate"} = 1;
    } elsif ($in_scope and /^# Shared IVSes: /) {
      $in_scope = 0;
    #} elsif ($in_scope and /^#/) {
    #  warn "<$_>";
    }
  }
}

{
  my $path = $TempPath->child ('EquivalentUnifiedIdeograph.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (/^([0-9A-F]+)\s*;\s*([0-9A-F]+)\s*#/) {
      my $c1 = chr hex $1;
      my $c2 = chr hex $2;
      $Data->{hans}->{$c1}->{$c2}->{"ucd:Equivalent_Unified_Ideograph"} = 1;
    } elsif (/^([0-9A-F]+)\.\.([0-9A-F]+)\s*;\s*([0-9A-F]+)\s*#/) {
      my $cc11 = hex $1;
      my $cc12 = hex $2;
      my $c2 = chr hex $3;
      for ($cc11..$cc12) {
        my $c1 = chr $_;
        $Data->{hans}->{$c1}->{$c2}->{"ucd:Equivalent_Unified_Ideograph"} = 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

for (
  ['unihan-k0.txt', 'unihan:kKSC0', ':ks0'],
  ['unihan-k1.txt', 'unihan:kKSC1', ':ks1'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $rel_type = $_->[1];
  my $prefix = $_->[2];
  my $dups = {};
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\s+\S+\s+([0-9]{2})([0-9]{2})/) {
      my $c1 = chr hex $1;
      my $ku = 0+$2;
      my $ten = 0+$3;
      my $c2 = sprintf '%s-%d-%d', $prefix, $ku, $ten;
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
    }
  }
}

{
  my $path = $RootPath->child ('local/unicode/latest/StandardizedVariants.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F]+) ([0-9A-F]+)\s*;\s*CJK COMPATIBILITY IDEOGRAPH-([0-9A-F]+);/) {
      my $c1 = (chr hex $1) . (chr hex $2);
      my $c2 = chr hex $3;
      my $c3 = chr hex $1;
      $Data->{hans}->{$c2}->{$c1}->{'unicode:svs:cjk'} = 1;
      $Data->{hans}->{$c1}->{$c3}->{'unicode:svs:base'} = 1;
    }
  }
}

{
  my $names_list_path = $RootPath->child ('local/unicode/latest/NamesList.txt');
  my $code;
  for (split /\x0D?\x0A/, $names_list_path->slurp) {
    s/^\@\+//;
    if (/^\s*#/) {
      #
    } elsif (/^([0-9A-F]{4,})\t(.+)/) {
      $code = hex $1;
    } elsif (/^\tx \(.+ - ([0-9A-F]+)\)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:x",
          "auto";
    } elsif (/^\tx ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:x",
          "auto";
    } elsif (/^\t\* obsolete ligature for the sequence ([0-9A-F]+(?: [0-9A-F]+)*)$/) {
      insert_rel $Data,
          (u_chr $code), (u_hexs $1), "ucd:names:obsoleted",
          "auto";
    } elsif (/^\t\* use of this character is strongly discouraged; (?:the sequence |)([0-9A-F]+(?: [0-9A-F]+)*) should be used instead$/) {
      insert_rel $Data,
          (u_chr $code), (u_hexs $1), "ucd:names:discouraged",
          "auto";
    } elsif (/^\t\* ([0-9A-F]+) is the preferred character$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:preferred",
          "auto";
    } elsif (/^\t\* use of ([0-9A-F]+) is preferred$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:preferred",
          "auto";
    } elsif (/^\t\*.* ([0-9A-F]+) (?:is (?:the |)|)preferred/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:preferred-some",
          "auto";
    } elsif (/^\t\*.*preferred .+ is ([0-9A-F]+(?: [0-9A-F]+)*)\b/) {
      insert_rel $Data,
          (u_chr $code), (u_hexs $1), "ucd:names:preferred-some",
          "auto";
    } elsif (/^\t\*.* preferred (?:representation|spelling).*: ([0-9A-F]+(?: [0-9A-F]+)*)/) {
      insert_rel $Data,
          (u_chr $code), (u_hexs $1), "ucd:names:preferred-some",
          "auto";
    } elsif (/^\t\*.*preferred to ([0-9A-F]+) for/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:prefers-some",
          "auto";
    } elsif (/^\t\*.*preferred .+ alternate for ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:prefers-some",
          "auto";
    } elsif (/^\t\*.+ alternate for the preferred ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:prefers-some",
          "auto";
    } elsif (/^\t\* this is the preferred character.+as opposed to ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:prefers-some",
          "auto";
    } elsif (/^\t\*.+variant (?:for|of) ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:variant",
          "auto";
    } elsif (/^\t\*.* ([0-9A-F]+) is .* variant/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:variant",
          "auto";
    } elsif (/^\t\*.* pair with ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:related",
          "auto";
    } elsif (/^\t\* transliterated as ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:transliterated",
          "desc";
    } elsif (/^\t\* transliterated as (\w{1,3})$/) {
      insert_rel $Data,
          (u_chr $code), $1, "ucd:names:transliterated",
          "desc";
    } elsif (/^\t\* transliterated as (\w) or as (\w)$/) {
      insert_rel $Data,
          (u_chr $code), $1, "ucd:names:transliterated",
          "desc";
      insert_rel $Data,
          (u_chr $code), $2, "ucd:names:transliterated",
          "desc";
    } elsif (/^\t\* transliterated as (\w) or as ([0-9A-F]+)$/) {
      insert_rel $Data,
          (u_chr $code), $1, "ucd:names:transliterated",
          "desc";
      my $code2 = hex $2;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:transliterated",
          "desc";
    } elsif (/^\t\* not to be confused with ([0-9A-F]+(?:(?:,|, or) [0-9A-F]+)*)$/) {
      for (split /,(?: or|) /, $1) {
        my $code2 = hex $_;
        insert_rel $Data,
            (u_chr $code), (u_chr $code2), "ucd:names:confused",
            "auto";
      }
    } elsif (/^\t\* uppercase is ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:uc",
          "auto";
    } elsif (/^\t\* uppercase is ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:uc-some",
          "auto";
    } elsif (/^\t\* lowercase is ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:lc",
          "auto";
    } elsif (/^\t\*.+ lowercase is ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:lc-some",
          "auto";
    } elsif (/^\t\*.+ ([0-9A-F]+) for lowercase\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:lc-some",
          "auto";
    } elsif (/^\t\* lowercase in .+ is ([0-9A-F]+)$/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:lc-some",
          "auto";
    } elsif (/^\t\*.+ lowercase as ([0-9A-F]+)\b/) {
      my $code2 = hex $1;
      insert_rel $Data,
          (u_chr $code), (u_chr $code2), "ucd:names:lc-some",
          "auto";
    } elsif (/^\t\*.+ lowercase of ([0-9A-F]+) as ([0-9A-F]+)\b/) {
      {
        my $code2 = hex $1;
        insert_rel $Data,
            (u_chr $code), (u_chr $code2), "ucd:names:related",
            "auto";
      }
      {
        my $code2 = hex $2;
        insert_rel $Data,
            (u_chr $code), (u_chr $code2), "ucd:names:related",
            "auto";
      }
    }
  }
}

{
  my $path = $RootPath->child ('data/maps.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (qw(
    fwhw:normalize
    fwhw:strict_normalize

    kana:h2k
    kana:k2h
    kana:large
    kana:normalize
    kana:small

    irc:ascii-lowercase
    irc:rfc1459-lowercase
    irc:strict-rfc1459-lowercase

rfc5051:titlecase-canonical

rfc3454:B.1
rfc3454:B.2
rfc3454:B.3
uts46:mapping

unicode:Case_Folding
unicode:Lowercase_Mapping
unicode:NFKC_Casefold
unicode:Titlecase_Mapping
unicode:Uppercase_Mapping
unicode:canon_composition
unicode:canon_decomposition
unicode:compat_decomposition

unicode5.1:Bidi_Mirroring_Glyph
unicode5.1:Bidi_Mirroring_Glyph-BEST-FIT
unicode:Bidi_Mirroring_Glyph
unicode:Bidi_Mirroring_Glyph-BEST-FIT
unicode:Bidi_Paired_Bracket

unicode:security:confusable
unicode:security:intentional
  )) {
    my $def = $json->{maps}->{$key};
    my $cmode = {qw(
      kana:h2k          kana
      kana:k2h          kana
      kana:large        kana
      kana:normalize    autok
      kana:small        kana
    )}->{$key} || 'auto';
    for my $in (keys %{$def->{char_to_char} or {}}) {
      my $out = $def->{char_to_char}->{$in};
      insert_rel $Data,
          (u_hexs $in), (u_hexs $out), $key,
          $cmode;
    }
    for my $in (keys %{$def->{char_to_seq} or {}}) {
      my $out = $def->{char_to_seq}->{$in};
      insert_rel $Data,
          (u_hexs $in), (u_hexs $out), $key,
          $cmode;
    }
    for my $in (keys %{$def->{seq_to_char} or {}}) {
      my $out = $def->{seq_to_char}->{$in};
      insert_rel $Data,
          (u_hexs $in), (u_hexs $out), $key,
          $cmode;
    }
    for my $in (keys %{$def->{seq_to_seq} or {}}) {
      my $out = $def->{seq_to_seq}->{$in};
      insert_rel $Data,
          (u_hexs $in), (u_hexs $out), $key,
          $cmode;
    }
  }
}

{
  my $path = $RootPath->child ('local/unicode/latest/StandardizedVariants.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9A-F]+) ([0-9A-F]+)\s*;\s*CJK COMPATIBILITY IDEOGRAPH-([0-9A-F]+);/) {
      #
    } elsif (/^([0-9A-F]+) ([0-9A-F]+)\s*;\s*/) {
      my $c1 = u_hexs "$1 $2";
      my $c2 = u_hexs $1;
      insert_rel $Data,
          $c2, $c1, 'unicode:svs',
          'auto';
      insert_rel $Data,
          $c1, $c2, 'unicode:svs:base',
          'auto';
    } elsif (/^#([0-9A-F]+) ([0-9A-F]+)\s*;\s*/) {
      my $c1 = u_hexs "$1 $2";
      my $c2 = u_hexs $1;
      insert_rel $Data,
          $c2, $c1, 'unicode:svs:obsolete',
          'auto';
      insert_rel $Data,
          $c1, $c2, 'unicode:svs:base',
          'auto';
    }
  }
}

my $Jouyou = {};
{
  my $path = $ThisPath->parent->child ('jp/jouyouh22-table.json');
  my $json = json_bytes2perl $path->slurp;
  for my $char (keys %{$json->{jouyou}}) {
    my $in = $json->{jouyou}->{$char};
    $Jouyou->{$char} = $in->{index};
  }
}
{
  my $path = $TempPath->child ('unihan-joyo.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kJoyoKanji)\s+2010$/) {
      my $jouyou = $Jouyou->{chr hex $1};
      my $c2 = sprintf ':jouyou-h22-%d', $jouyou;
      $Data->{hans}->{u_chr hex $1}->{$c2}->{"unihan:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kJoyoKanji)\s+U\+([0-9A-F]+)$/) {
      my $c2 = chr hex $3;
      $Data->{hans}->{u_chr hex $1}->{$c2}->{"unihan:$2"} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-jinmei.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kJinmeiyoKanji)\s+[0-9]+$/) {
      my $c1 = chr hex $1;
      my $c2 = sprintf ':jinmei-%s', $c1;
      $Data->{hans}->{$c1}->{$c2}->{"unihan:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kJinmeiyoKanji)\s+[0-9]+:U\+([0-9A-F]+)$/) {
      my $c1 = chr hex $1;
      my $c2 = sprintf ':jinmei-%s', $c1;
      $Data->{hans}->{$c1}->{$c2}->{"unihan:$2"} = 1;
      my $c3 = chr hex $3;
      $Data->{hans}->{$c1}->{$c3}->{"unihan:$2:standard"} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('cjk-symbols-map.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\d+\tu(?:ni|)([0-9a-f]+)$/) {
      my $code = hex $1;
      next unless $code > 0x7F;
      my $c1 = u_chr $code;
      my $c2 = sprintf ':u-cjksym-%x', $code;
      $Data->{glyphs}->{$c2}->{$c1}->{'manakai:implements'} = 1;
    }
  }

  ## <https://github.com/unicode-org/cjk-symbols>
  ## <https://www.unicode.org/charts/PDF/Unicode-14.0/#GlyphChanges>
  for my $code (
    0x2460..0x24FF,
    0x2776..0x2793,
    0x3001..0x3029, 0x3030..0x303D, 0x303F,
    0x31C0..0x31E3,
    0x31F0..0x31FF,
    0x3200..0x321E, 0x3220..0x32FF,
    0x3300..0x33FF,
    0xFE10..0xFE19,
    0xFE30..0xFE4F,
    0xFE50..0xFE52, 0xFE54..0xFE66, 0xFE68..0xFE6B,
    0xFF01..0xFF9F, 0xFFA1..0xFFBE, 0xFFC2..0xFFC7, 0xFFCA..0xFFCF,
    0xFFD2..0xFFD7, 0xFFDA..0xFFDC, 0xFFE0..0xFFE6, 0xFFE8..0xFFEE,
    0x1F100..0x1F1AD, 0x1F1E6..0x1F1FF,
    0x1F200..0x1F202, 0x1F210..0x1F23B, 0x1F240..0x1F248,
    0x1F250..0x1F251, 0x1F260..0x1F265,
  ) {
    my $c1 = u_chr $code;
    my $c2 = sprintf ':u-cjksym-%x', $code; # version 1.001
    $Data->{glyphs}->{$c1}->{$c2}->{'unicode14:glyph'} = 1;
    ## version 2.000 (Unicode 16.0): U+31E4, U+31E5, U+3029, U+31D2
  }
}

{
  my $path = $ThisPath->child ('ucsj-heisei.txt');
  for (split /\n/, $path->slurp) {
    my @line = split /\t/, $_;
    my $c1 = chr hex $line[0];
    my $c2 = ':' . $line[2];
    next if $line[1] eq 'b';
    my $rel_type = {
      a => 'unicode:j:glyph',
    }->{$line[1]} // die $line[1];
    my $key = get_vkey $c1;
    $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
  }
}

$Data->{hans}->{"\x{9FB9}"}->{"\x{20509}"}->{"iso10646:annexp:withoutposition"} = 1;
$Data->{hans}->{"\x{9FBA}"}->{"\x{2099D}"}->{"iso10646:annexp:withoutposition"} = 1;
$Data->{hans}->{"\x{9FBB}"}->{"\x{470C}"}->{"iso10646:annexp:withoutposition"} = 1;

write_rel_data_sets
    $Data => $ThisPath, 'maps',
    [
      qr/^[\x{0080}-\x{0FFF}]/,
      qr/^[\x{1000}-\x{1FFF}]/,
      qr/^[\x{2000}-\x{2FFF}]/,
      qr/^[\x{3000}-\x{37FF}]/,
      qr/^[\x{3800}-\x{3FFF}]/,
      qr/^[\x{4000}-\x{47FF}]/,
      qr/^[\x{4800}-\x{4FFF}]/,
      qr/^[\x{5000}-\x{57FF}]/,
      qr/^[\x{5800}-\x{5FFF}]/,
      qr/^[\x{6000}-\x{67FF}]/,
      qr/^[\x{6800}-\x{6FFF}]/,
      qr/^[\x{7000}-\x{77FF}]/,
      qr/^[\x{7800}-\x{7FFF}]/,
      qr/^[\x{8000}-\x{87FF}]/,
      qr/^[\x{8800}-\x{8FFF}]/,
      qr/^[\x{9000}-\x{97FF}]/,
      qr/^[\x{9800}-\x{9FFF}]/,
      qr/^[\x{A000}-\x{DFFF}]/,
      qr/^[\x{10000}-\x{17FFF}]/,
      qr/^[\x{18000}-\x{1FFFF}]/,
      qr/^[\x{20000}-\x{21FFF}]/,
      qr/^[\x{22000}-\x{23FFF}]/,
      qr/^[\x{24000}-\x{25FFF}]/,
      qr/^[\x{26000}-\x{27FFF}]/,
      qr/^[\x{28000}-\x{29FFF}]/,
      qr/^[\x{2A000}-\x{2BFFF}]/,
      qr/^[\x{2C000}-\x{2DFFF}]/,
      qr/^[\x{2E000}-\x{2FFFF}]/,
      qr/^[\x{30000}-\x{3FFFF}]/,
      qr/^[\x{E000}-\x{FFFF}]/,
      qr/^:[Uu]/,
      qr/^:/,
    ];

## License: Public Domain.

