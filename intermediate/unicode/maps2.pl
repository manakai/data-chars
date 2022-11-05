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
  my $path = $TempPath->child ('unihan-irg-j.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_JSource)\s+J([0134]|13|14|A3|A4)-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $prefix = {
        '0' => ':jis1',
        '1' => ':jis2',
        '3' => ':jis1',
        '4' => ':jis2',
        '13' => ':jis1',
        '14' => ':jis2',
        'A3' => ':jis1',
        'A4' => ':jis2',
      }->{$3} // die $3;
      my $c1 = u_chr hex $1;
      my $c2 = sprintf '%s-%d-%d', $prefix, (hex $4) - 0x20, (hex $5) - 0x20;
      my $rel_type = "unihan:$2:$3";
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_JSource)\s+JARIB-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':jis-arib-1-%d-%d', (hex $3) - 0x20, (hex $4) - 0x20;
      $Data->{hans}->{u_chr hex $1}->{$c2}->{"unihan:$2:ARIB"} = 1;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-ibmjapan.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIBMJapan)\s+([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sjis_char ':jis-dos-1-', (hex $3), (hex $4);
      $Data->{hans}->{u_chr hex $1}->{$c2}->{"unihan:$2"} = 1;
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
    }
  }
}

for (
  ['bestfit932.txt', 1, undef, ':u-ms'],
  ['bestfit936.txt', 0, ':gb0', ':u-gb'],
  ['bestfit949.txt', 0, ':ks0', ':u-ms'],
  ['bestfit950.txt', 2, undef, ':u-bigfive'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $is_sjis = $_->[1] == 1;
  my $is_b5 = $_->[1] == 2;
  my $prefix = $_->[2];
  my $pprefix = $_->[3];
  my $file = $path->openr;
  my $b1;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^MBTABLE/) {
      #
    } elsif (/^DBCSTABLE\s+(\d+)\s*;LeadByte = 0x([0-9A-Fa-f]{2})\s*$/) {
      $b1 = hex $2;
    } elsif (/^WCTABLE\s/) {
      $b1 = -1;
    } elsif (/^0x([0-9A-Fa-f]{2})\s+0x([0-9A-Fa-f]{4,})\s*;/) {
      if (defined $b1 and $b1 > 0 and
          ($is_sjis or $is_b5 or (0xA1 <= $b1 and $b1 <= 0xFE))) {
        my $b2 = hex $1;
        next unless $is_sjis or $is_b5 or (0xA1 <= $b2 and $b2 <= 0xFE);
        my $c2 = u_chr hex $2;
        my $c2_0 = $c2;
        my $c1 = $is_b5   ? (sprintf ':b5-%x', $b1 * 0x100 + $b2) :
                 $is_sjis ? (sjis_char ':jis-dos-1-', $b1, $b2)
                          : (sprintf '%s-%d-%d', $prefix, $b1-0xA0, $b2-0xA0);
        my $key = get_vkey $c2;
        if (is_private $c2) {
          $c2 = sprintf '%s-%x', $pprefix, ord $c2;
          $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        $Data->{$key}->{$c1}->{$c2}->{'unicode:from cp'} = 1;
        my $c1_0 = $c1;
        if ($c1_0 =~ s/^:jis-dos-/:jis/) {
          $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
        }
      } elsif (not defined $b1 and $is_sjis) {
        my $c2 = u_chr hex $2;
        my $b2 = hex $1;
        my $c1 = sprintf ':jisx0201-%x', $b2;
        my $key = get_vkey $c2;
        my $c2_0 = $c2;
        if (is_private $c2) {
          $c2 = sprintf '%s-%x', $pprefix, ord $c2;
          $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        $Data->{$key}->{$c1}->{$c2}->{'unicode:from cp'} = 1;
      }
    } elsif (/^0x([0-9A-Fa-f]{2})\s+0x([Ee][0-9A-Fa-f]{3,}|[Ff][0-8][0-9A-Fa-f]{2})\s*$/) {
      if (defined $b1 and $b1 > 0 and
          ($is_sjis or $is_b5 or (0xA1 <= $b1 and $b1 <= 0xFE))) {
        my $b2 = hex $1;
        next unless $is_b5 or $is_sjis or (0xA1 <= $b2 and $b2 <= 0xFE);
        my $c2 = u_chr hex $2;
        my $c2_0 = $c2;
        my $c1 = $is_b5   ? (sprintf ':b5-%x', $b1 * 0x100 + $b2) :
                 $is_sjis ? (sjis_char ':jis-dos-1-', $b1, $b2)
                          : (sprintf '%s-%d-%d', $prefix, $b1-0xA0, $b2-0xA0);
        my $key = get_vkey $c2;
        if (is_private $c2) {
          $c2 = sprintf '%s-%x', $pprefix, ord $c2;
          $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        $Data->{$key}->{$c1}->{$c2}->{'unicode:from cp'} = 1;
        my $c1_0 = $c1;
        if ($c1_0 =~ s/^:jis-dos-/:jis/) {
          $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
        }
      }
    } elsif (/^0x([0-9A-Fa-f]{4,})\s+0x([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\s*;/ and $b1 == -1) {
      my $b1 = hex $2;
      my $b2 = hex $3;
      if (($is_sjis and $b1 >= 0x80) or
          (not $is_sjis and 0xA1 <= $b1 and $b1 <= 0xFE and
           0xA1 <= $b2 and $b2 <= 0xFE) or
          $is_b5) {
        my $c1 = $is_b5   ? (sprintf ':b5-%x', $b1 * 0x100 + $b2) :
                 $is_sjis ? (sjis_char ':jis-dos-1-', $b1, $b2)
                          : (sprintf '%s-%d-%d', $prefix, $b1-0xA0, $b2-0xA0);
        my $c2 = u_chr hex $1;
        my $c2_0 = $c2;
        my $key = get_vkey $c2;
        if (is_private $c2) {
          $c2 = sprintf '%s-%x', $pprefix, ord $c2;
          $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        $Data->{$key}->{$c2}->{$c1}->{'unicode:to cp'} = 1;
        my $c1_0 = $c1;
        if ($c1_0 =~ s/^:jis-dos-/:jis/) {
          $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
        }
      } elsif ($is_sjis and $b1 == 0x00) {
        my $c1 = sprintf ':jisx0201-%x', $b2;
        my $c2 = u_chr hex $1;
        my $c2_0 = $c2;
        my $key = get_vkey $c2;
        if (is_private $c2) {
          $c2 = sprintf '%s-%x', $pprefix, ord $c2;
          $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        my $c1_0 = $c1;
        $Data->{$key}->{$c2}->{$c1}->{'unicode:to cp'} = 1;
      }
    } elsif (/^0x((?:[Ee][0-9A-Fa-f]|[Ff][0-8])[0-9A-Fa-f]{2,})\s+0x([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\s*$/ and $b1 == -1) {
      my $b1 = hex $2;
      my $b2 = hex $3;
      if (($is_sjis and $b1 >= 0x80) or
          (not $is_sjis and 0xA1 <= $b1 and $b1 <= 0xFE and
           0xA1 <= $b2 and $b2 <= 0xFE) or
          $is_b5) {
        my $c1 = $is_b5   ? (sprintf ':b5-%x', $b1 * 0x100 + $b2) :
                 $is_sjis ? (sjis_char ':jis-dos-1-', $b1, $b2)
                          : (sprintf '%s-%d-%d', $prefix, $b1-0xA0, $b2-0xA0);
        my $c2 = u_chr hex $1;
        my $c2_0 = $c2;
        my $key = get_vkey $c2;
        if (is_private $c2) {
          $c2 = sprintf '%s-%x', $pprefix, ord $c2;
          $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        my $c1_0 = $c1;
        if ($c1_0 =~ s/^:jis-dos-/:jis/) {
          $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
        }
        $Data->{$key}->{$c2}->{$c1}->{'unicode:to cp'} = 1;
      }
    } elsif (/^0x40\s*0x30fb\s*$/) {
      #
    } elsif (/^(CODEPAGE|CPINFO|DBCSRANGE|ENDCODEPAGE)/ or /;Lead Byte Range/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('unihan3.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^U\+([0-9A-F]+)\s+(kIRG_JSource)\s+([01])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c1 = u_chr hex $1;
      my $c2 = sprintf ':jis%d-%d-%d', 1 + hex $3, (hex $4) - 0x20, (hex $5) - 0x20;
      my $rel_type = "unihan3.0:$2";
      my $key = get_vkey $c1;
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    }
  }
}
    
if (0) {
  my $path = $TempPath->child ('JIS0212.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^0x([[0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\s+0x([0-9A-F]+)\s+#/) {
      my $ku = (hex $1) - 0x20;
      my $ten = (hex $2) - 0x20;
      my $c1 = sprintf ':jis%d-%d-%d', 2, $ku, $ten;
      my $c2 = u_chr hex $3;
      my $key = get_vkey $c2;
      my $rel_type = 'unicode:mapping';
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('KPS9566.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^(#\s*|)0x([BCDE][0-9A-F]|A[1-9A-F]|F[0-9A-E])([BCDE][0-9A-F]|A[1-9A-F]|F[0-9A-E])\s+0x([0-9A-F]+)\s+#/) {
      my $ku = (hex $2) - 0xA0;
      my $ten = (hex $3) - 0xA0;
      my $c1 = sprintf ':kps%d-%d-%d', 0, $ku, $ten;
      my $c1_0 = $c1;
      my $c2 = u_chr hex $4;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-kps-%x', ord $c2;
      }
      my $key = get_vkey $c2;
      my $rel_type = 'unicode:mapping';
      if ($1) {
        if (/mapping in KPS 9566-97/) {
          $c1 =~ s/^:kps/:kps-old-/;
        } elsif (/VERTICAL TILDE/ or /N2374/ or /WHITE ARROW/) {
          #
        } else {
          die $_;
        }
      }
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
      unless ($c1 eq $c1_0) {
        $Data->{$key}->{$c1}->{$c1_0}->{'manakai:private'} = 1;
      }
    } elsif (/^0x(?:[0-9][0-9A-F]|A0|FF)[0-9A-Fa-f]{2}\s/) {
      #
    } elsif (/^0x[0-9A-Fa-f]{2}(?:[0-9][0-9A-F]|A0|FF)\s/) {
      #
    } elsif (/^0x[0-9A-Fa-f]{2}\s/) {
      #
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
  for (
    [72, 0xAE40, 0xF113],
    [73, 0xC77C, 0xF114],
    [74, 0xC131, 0xF115],
    [75, 0xAE40, 0xF116],
    [76, 0xC815, 0xF117],
    [77, 0xC77C, 0xF118],
    [78, 0xAE40, 0xF120],
    [79, 0xC815, 0xF121],
    [80, 0xC740, 0xF122],
  ) {
    my $c1 = sprintf ':kps0-%d-%d', 4, $_->[0];
    my $c2_0 = u_chr $_->[2];
    my $c2 = sprintf ':u-kps-%x', $_->[2];
    my $c3 = u_chr $_->[1];
    my $key = 'kchars';
    $Data->{$key}->{$c1}->{$c2}->{'manakai:same'} = 1;
    $Data->{$key}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    $Data->{$key}->{$c3}->{$c1}->{'manakai:bold'} = 1;
  }
}

for (
  ['CHINSIMP.txt', ':gb0'],
  ['KOREAN.txt', ':ks0'],
  ['KOREAN-old.txt', ':ks0'],
) {
  my $path = $TempPath->child ($_->[0]);
  my $prefix = $_->[1];
  for (split /[\x0D\x0A]+/, $path->slurp) {
    if (/^()0x([BCDE][0-9A-F]|A[1-9A-F]|F[0-9A-E])([BCDE][0-9A-F]|A[1-9A-F]|F[0-9A-E])\s+0x([0-9A-F]+)\s+#/) {
      my $ku = (hex $2) - 0xA0;
      my $ten = (hex $3) - 0xA0;
      my $c1 = sprintf '%s-%d-%d', $prefix, $ku, $ten;
      my $c2 = u_chr hex $4;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-mac-%x', ord $c2;
      }
      my $key = get_vkey $c2;
      my $rel_type = 'unicode:mapping:apple';
      $Data->{$key}->{$c2}->{$c1}->{$rel_type} = 1;
    } elsif (/^()0x([BCDE][0-9A-F]|A[1-9A-F]|F[0-9A-E])([BCDE][0-9A-F]|A[1-9A-F]|F[0-9A-E])\s+(0x[0-9A-F]+(?:\+0x[0-9A-F]+)*)\s+#/) {
      my $ku = (hex $2) - 0xA0;
      my $ten = (hex $3) - 0xA0;
      my $c1 = sprintf '%s-%d-%d', $prefix, $ku, $ten;
      my $c2 = join '', map { s/^0x//; sprintf ':u%x', hex $_ } split /\+/, $4;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-mac-%x', ord $c2;
      }
      $c2 =~ s/:uf([0-8])/:u-mac-f$1/g;
      my $key = get_vkey $c2;
      my $rel_type = 'unicode:mapping:apple';
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^0x(?:[0-9][0-9A-F]|A0|FF)[0-9A-Fa-f]{2}\s/) {
      #
    } elsif (/^0x[0-9A-Fa-f]{2}(?:[0-9][0-9A-F]|A0|FF)\s/) {
      #
    } elsif (/^0x[0-9A-Fa-f]{2}\s/) {
      #
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('JAPANESE.txt');
  for (split /[\x0D\x0A]+/, $path->slurp) {
    if (/^0x([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\s+0x([0-9A-F]+)\s+#/) {
      my $c1 = sjis_char ':jis-mac-1-', hex $1, hex $2;
      my $c1_0 = $c1;
      my $c2 = u_chr hex $3;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-mac-%x', ord $c2;
      }
      my $key = get_vkey $c2;
      my $rel_type = 'unicode:mapping:apple';
      $Data->{$key}->{$c2}->{$c1}->{$rel_type} = 1;
      $c1_0 =~ s/^:jis-mac-/:jis/g;
      unless ($c1 eq $c1_0) {
        $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
        if ($c1 =~ /^:jis-mac-1-(8[5-9])-([0-9]+)$/) {
          my $c3 = sprintf ':jis1-%d-%d', $1 - 84, $2;
          $Data->{$key}->{$c3}->{$c1}->{'apple:ku+84'} = 1;
        }
      }
    } elsif (/^0x([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\s+(0x[0-9A-F]+(?:\+0x[0-9A-F]+)*)\s+#/) {
      my $c1 = sjis_char ':jis-mac-1-', hex $1, hex $2;
      my $c1_0 = $c1;
      my $c2 = join '', map { s/^0x//; sprintf ':u%x', hex $_ } split /\+/, $3;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-mac-%x', ord $c2;
      }
      $c2 =~ s/:uf([0-8])/:u-mac-f$1/g;
      my $key = get_vkey $c2;
      my $rel_type = 'unicode:mapping:apple';
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
      $c1_0 =~ s/^:jis-mac-/:jis/g;
      unless ($c1 eq $c1_0) {
        $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
        if ($c1 =~ /^:jis-mac-1-(8[5-9])-([0-9]+)$/) {
          my $c3 = sprintf ':jis1-%d-%d', $1 - 84, $2;
          $Data->{$key}->{$c3}->{$c1}->{'apple:ku+84'} = 1;
        }
      }
      while ($c2 =~ m{(:u-mac-([0-9a-f]+))}g) {
        my $x = $1;
        my $cc = hex $2;
        my $c = u_chr $cc;
        $Data->{variants}->{$c}->{$x}->{'manakai:private'} = 1;
      }
    } elsif (/^0x(?:[0-9][0-9A-F]|A0|FF)[0-9A-Fa-f]{2}\s/) {
      #
    } elsif (/^0x[0-9A-Fa-f]{2}(?:[0-9][0-9A-F]|A0|FF)\s/) {
      #
    } elsif (/^0x([0-9A-Fa-f]{2})\s0x([0-9A-Fa-f]+)\s*#/) {
      my $cc1 = hex $1;
      my $c1 = sprintf ':jisx0201-%x', $cc1;
      my $c2 = u_chr hex $2;
      my $c1_0 = $c1;
      my $key = get_vkey $c2;
      unless ((0x20 <= $cc1 and $cc1 <= 0x7F) or
              (0xA1 <= $cc1 and $cc1 <= 0xDF)) {
        $c1 = sprintf ':jisx0201-mac-%x', $cc1;
        $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      }
      my $rel_type = 'unicode:mapping:apple';
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
    } elsif (/^0x([0-9A-Fa-f]{2})\s(0x[0-9A-Fa-f]+\+0x[0-9A-Fa-f]+)\s*#/) {
      my $cc1 = hex $1;
      my $c1 = sprintf ':jisx0201-%x', $cc1;
      my $c2 = join '', map { s/^0x//; sprintf ':u%x', hex $_ } split /\+/, $2;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-mac-%x', ord $c2;
      }
      $c2 =~ s/:uf([0-8])/:u-mac-f$1/g;
      my $c1_0 = $c1;
      my $key = get_vkey $c2;
      unless ((0x20 <= $cc1 and $cc1 <= 0x7F) or
              (0xA1 <= $cc1 and $cc1 <= 0xDF)) {
        $c1 = sprintf ':jisx0201-mac-%x', $cc1;
        $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      }
      my $rel_type = 'unicode:mapping:apple';
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
      while ($c2 =~ m{(:u-mac-([0-9a-f]+))}g) {
        my $x = $1;
        my $cc = hex $2;
        my $c = u_chr $cc;
        $Data->{variants}->{$c}->{$x}->{'manakai:private'} = 1;
      }
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
  my $ku = 95;
  my $ten = 1;
  for (0xE000..0xE98B) { # 0xF040 ... 0xFCFC
    my $c2 = u_chr $_;
    my $c1 = sprintf ':jis1-%d-%d', $ku, $ten;
    $Data->{variants}->{$c1}->{$c2}->{'unicode:mapping:apple'} = 1;
    $ten++;
    if ($ten == 95) {
      $ten = 1;
      $ku++;
    }
  }
}
{
  my $path = $TempPath->child ('CHINTRAD.txt');
  for (split /[\x0D\x0A]+/, $path->slurp) {
    if (/^0x([0-9A-Fa-f]+)\s+0x([0-9A-F]+)\s+#/) {
      my $c1 = sprintf ':b5-%x', hex $1;
      my $c1_0 = $c1;
      my $c2 = u_chr hex $2;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-mac-%x', ord $c2;
      }
      my $key = get_vkey $c2;
      my $rel_type = 'unicode:mapping:apple';
      $Data->{$key}->{$c2}->{$c1}->{$rel_type} = 1;
      unless ($c1 eq $c1_0) {
        $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      }
    } elsif (/^0x([0-9A-Fa-f]+)\s+(0x[0-9A-F]+(?:\+0x[0-9A-F]+)*)\s+#/) {
      my $c1 = sprintf ':b5-%x', hex $1;
      my $c1_0 = $c1;
      my $c2 = join '', map { s/^0x//; sprintf ':u%x', hex $_ } split /\+/, $2;
      my $c2_0 = $c2;
      if (is_private $c2) {
        $c2 = sprintf ':u-mac-%x', ord $c2;
      }
      $c2 =~ s/:uf([0-8])/:u-mac-f$1/g;
      my $key = get_vkey $c2;
      my $rel_type = 'unicode:mapping:apple';
      $Data->{$key}->{$c1}->{$c2}->{$rel_type} = 1;
      unless ($c1 eq $c1_0) {
        $Data->{$key}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      }
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('iso-ir-165.ucm');
  for (split /[\x0D\x0A]+/, $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^<U([0-9A-F]+)>\s*\\x([0-9A-Fa-f]{2})\\x([0-9A-Fa-f]{2})\s*\|0$/) {
      my $c2 = u_chr hex $1;
      my $c1 = sprintf ':gb0-%d-%d', (hex $2)-0x20, (hex $3)-0x20;
      my $key = get_vkey $c2;
      $Data->{$key}->{$c2}->{$c1}->{'icu:mapping:iso-ir-165'} = 1;
    } elsif (/^CHARMAP/ or /^END CHARMAP/ or /^</) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

print_rel_data $Data;

## License: Public Domain.

