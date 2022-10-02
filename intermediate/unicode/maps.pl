use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iuc');

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

{
  my $path = $TempPath->child ('unihan3.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kCNS1986|kCNS1992)\s+([0-9A-F])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':cns%d-%d-%d', hex $3, (hex $4) - 0x20, (hex $5) - 0x20;
      $Data->{variants}->{u_chr hex $1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kGB0|kGB1|kGB8|kPseudoGB1)\s+(\d\d)(\d\d)$/) {
      my $c2 = sprintf ':gb%d-%d-%d', 0, $3, $4;
      $Data->{variants}->{u_chr hex $1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kGB3)\s+(\d\d)(\d\d)$/) {
      my $c2 = sprintf ':gb%d-%d-%d', 2, $3, $4;
      $Data->{variants}->{u_chr hex $1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kGB5)\s+(\d\d)(\d\d)$/) {
      my $c2 = sprintf ':gb%d-%d-%d', 4, $3, $4;
      $Data->{variants}->{u_chr hex $1}->{$c2}->{"unihan3.0:$2"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_GSource)\s+([01358])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':gb%d-%d-%d', {
        0 => '0',
        1 => '0',
        3 => '2',
        5 => '4',
        8 => '0',
      }->{$3}, (hex $4) - 0x20, (hex $5) - 0x20;
      $Data->{variants}->{u_chr hex $1}->{$c2}->{"unihan3.0:$2:$3"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_TSource)\s+([1-9A-F])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':cns%d-%d-%d', hex $3, (hex $4) - 0x20, (hex $5) - 0x20;
      $Data->{variants}->{u_chr hex $1}->{$c2}->{"unihan3.0:$2"} = 1;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-g.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_GSource)\s+G([01358])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':gb%d-%d-%d', {
        0 => '0',
        1 => '0',
        3 => '2',
        5 => '4',
        8 => '0',
      }->{$3}, (hex $4) - 0x20, (hex $5) - 0x20;
      $Data->{variants}->{u_chr hex $1}->{$c2}->{"unihan:$2:$3"} = 1;
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_KSource)\s+G([01])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c2 = sprintf ':ks%d-%d-%d', $3, (hex $4) - 0x20, (hex $5) - 0x20;
      $Data->{variants}->{u_chr hex $1}->{$c2}->{"unihan:$2"} = 1;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.

