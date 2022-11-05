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
      $Data->{hans}->{":$1"}->{$c2}->{"uk:font-code-point"} = 1;
      die "Duplicate $c2" if $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'};
      $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    } elsif (/^(UK-[0-9]+)\t(?:U\+|)([0-9A-F]{4})\t([0-9]{2})-([0-9]{2})$/) {
      my $c2 = sprintf ':u-%s-%x', $up, hex $2;
      my $c2_0 = chr hex $2;
      my $c3 = sprintf ':gb8-%d-%d', $3, $4;
      $Data->{hans}->{":$1"}->{$c2}->{"uk:font-code-point"} = 1;
      die "Duplicate $c2" if $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'};
      $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      $Data->{hans}->{":$1"}->{$c3}->{"uk:gb8"} = 1;
      # SJ/T 11239-2001
    } elsif (/\S/) {
      die $_;
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
