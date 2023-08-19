use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/ivn');
my $Data = {};

{
  ## <https://wiki.suikawiki.org/n/Vietnamese%20alternate%20reading%20mark>
  my $path = $ThisPath->child ('ca.txt');
  for (split /[\x0D\x0A]/, $path->slurp_utf8) {
    if (/^(\S)\t(\S)$/) {
      $Data->{hans}->{$1}->{$2 . "\x{16FF0}"}->{'manakai:same'} = 1;
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('features.txt');
  for (split /[\x0D\x0A]/, $path->slurp_utf8) {
    if (/^\s*sub\s+u(?:ni|)([0-9A-F]+) u(16FF[01])\s+by\s+u([0-9A-F]+);$/) {
      my $c1 = chr hex $3;
      my $c2 = (chr hex $1) . (chr hex $2);
      my $c1_0 = $c1;
      if (is_private $c1) {
        $c1 = sprintf ':u-nom-%x', ord $c1;
        $Data->{hans}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
      }
      $Data->{hans}->{$c1}->{$c2}->{'manakai:same'} = 1;
    }
  }
}

{
  my $path = $TempPath->child ('uvs.txt.2');
  for (split /[\x0D\x0A]/, $path->slurp_utf8) {
    if (/^([0-9A-F]+) ([0-9A-F]+); u(?:ni|)([0-9A-F]+)$/) {
      my $c1 = (chr hex $1) . (chr hex $2);
      my $c1_1 = chr hex $1;
      my $c2 = chr hex $3;
      if ($c1_1 eq $c2) {
        #
      } else {
        my $c2_0 = $c2;
        if (is_private $c2) {
          $c2 = sprintf ':u-nom-%x', ord $c2;
          $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
          $Data->{hans}->{$c1_1}->{$c2}->{'manakai:unified'} = 1;
        }
      }
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempPath->child ('uvs.txt.3');
  for (split /[\x0D\x0A]/, $path->slurp_utf8) {
    if (/^([0-9A-F]+) ([0-9A-F]+); u(?:ni|)([0-9A-F]+)$/) {
      my $c1 = (chr hex $1) . (chr hex $2);
      my $c1_1 = chr hex $1;
      my $c2 = chr hex $3;
      if ($c1_1 eq $c2) {
        #
      } else {
        my $c2_0 = $c2;
        if (is_private $c2) {
          $c2 = sprintf ':u-nom-%x', ord $c2;
          $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
        }
        $Data->{hans}->{$c1_1}->{$c2}->{'manakai:unified'} = 1;
      }
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

sub u_rcv ($) {
  my $s = shift;
  if (2 == length $s) {
    my $c1 = sprintf ':u-rcv-%x-%x',
        (ord substr $s, 0, 1),
        (ord substr $s, 1, 1);
    my $c2 = chr ord substr $s, 0, 1;
    $Data->{codes}->{$c2}->{$c1}->{'hannom-rcv:ivs'} = 1;
    return $c1;
  } else {
    return $s;
  }
} # u_rcv

{
  my $path = $ThisPath->child ('rcv.json');
  my $json = json_bytes2perl $path->slurp;
  for (map { @$_ } $json->{1}, $json->{2}, $json->{html}) {
    if (@$_ > 1) {
      my $c1 = u_rcv $_->[0];
      my $c2 = u_rcv $_->[1];

      use utf8;
      $Data->{hans}->{$c1}->{$c2}->{'hannom-rcv:𡨸漢喃簡體'} = 1;
    }
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'maps',
    [];

## License: Public Domain.
