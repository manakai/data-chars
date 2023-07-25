use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' }

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iuc');

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
        my $c2_0 = $c2;
        $c2 =~ s/^:cns/:cns-old-/;
        $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
        $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
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
        $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
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
        $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      } else {
        if ($c2 =~ /^:gb0-15-(89|9[012])$/) {
          my $c2_0 = $c2;
          $c2 =~ s/^:gb0-/:gb8-/g;
          $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        $Data->{hans}->{$c1}->{$c2}->{$type} = 1;
      }
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_TSource)\s+([1-9A-F])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':cns%d-%d-%d', hex $3, (hex $4) - 0x20, (hex $5) - 0x20;
      my $c1 = u_chr hex $1;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{"unihan3.0:$2"} = 1;
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
    } elsif (/^U\+([0-9A-F]+)\s+(kKangXi|kIRGKangXi)\s+/) {
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
        $Data->{hans}->{$c2}->{$c1}->{'manakai:private'} = 1;
      } else {
        if ($c2 =~ /^:gb0-15-(89|9[012])$/) {
          my $c2_0 = $c2;
          $c2 =~ s/^:gb0-/:gb8-/g;
          $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        $Data->{hans}->{$c1}->{$c2}->{$type} = 1;
      }
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
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_TSource)\s+T([0-9A-F])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2";
      my $c2 = sprintf ':cns%d-%d-%d', (hex $3), (hex $4)-0x20, (hex $5)-0x20;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
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

{
  my $path = $TempPath->child ('unihan-morohashi.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kMorohashi)\s+([0-9]+)('|)$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2";
      my $c2 = sprintf ':m%d%s', $3, $4;
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kMorohashi)\s+/) {
      die $_;
    }
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'maps',
    [
      qr/^[\x{3000}-\x{3FFF}]/,
      qr/^[\x{4000}-\x{4FFF}]/,
      qr/^[\x{5000}-\x{5FFF}]/,
      qr/^[\x{6000}-\x{6FFF}]/,
      qr/^[\x{7000}-\x{7FFF}]/,
      qr/^[\x{8000}-\x{8FFF}]/,
      qr/^[\x{9000}-\x{9FFF}]/,
      qr/^[\x{20000}-\x{22FFF}]/,
      qr/^[\x{23000}-\x{25FFF}]/,
      qr/^[\x{26000}-\x{28FFF}]/,
      qr/^[\x{29000}-\x{2BFFF}]/,
      qr/^[\x{2C000}-\x{2FFFF}]/,
    ];

## License: Public Domain.

