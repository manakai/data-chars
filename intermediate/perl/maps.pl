use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/ipl');
my $Data = {};

{
  my $data1 = [];
  {
    my $path = $TempPath->child ('encode.ucm');
    my $file = $path->openr;
    while (<$file>) {
      if (m{^<U([0-9A-F]+)>\s*\\x([0-9A-F]{2})\\x([0-9A-F]{2})\\x([0-9A-F]{2})\s*\|0$}) {
        push @$data1, [(hex $2)-0x20, (hex $3)-0x20, (hex $4)-0x20, hex $1];
      } elsif (/^\s*#/ or /^</ or /^CHARMAP/ or /^END/) {
        #
      } elsif (/\S/) {
        die $_;
      }
    }
  }
  
  for (@$data1) {
    if ($_->[0] == 0x7F-0x20) {
      #$_->[0], $_->[1]+0x20, $_->[2]+0x20, $_->[3];
    } else {
      my $c1 = sprintf ":cccii%d-%d-%d", $_->[0], $_->[1], $_->[2];
      my $c2 = u_chr $_->[3];
      die if is_private $c2;
      my $key = get_vkey $c2;
      $key = 'kanas' if is_kana $c1 > 0;
      $Data->{$key}->{$c1}->{$c2}->{'pl:mapping'} = 1;
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
