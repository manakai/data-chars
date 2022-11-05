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
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-g.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_GSource)\s+G([01358K])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':gb%d-%d-%d', {
        0 => '0',
        1 => '0',
        3 => '2',
        5 => '4',
        8 => '0',
        K => 10 + (ord 'K') - (ord 'A'),
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

print_rel_data $Data;

## License: Public Domain.

