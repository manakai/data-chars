use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Time::HiRes qw(time);

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;

binmode STDERR, qw(:encoding(utf-8));

my $Chars;
{
  print STDERR "\rReading... ";
  my $path = $DataPath->child ('merged-chars.json');
  $Chars = json_bytes2perl $path->slurp;
}

my $CharArray = [];
{
  print STDERR "\rAssigning... ";
  my $to_index = {};
  {
    my $x = 5;
    $to_index->{$_} = $x++ for qw(MJ ac ag aj ak aj2- ak1-
                                  jis cns _ gb ks cjkvi swc);
  }

  my $all = 0+keys %$Chars;
  my $current = 0;

  C: for my $c (sort {
    (length $a) <=> (length $b) ||
    $a cmp $b
  } keys %$Chars) {
    if (not ($current++ % 1000)) {
      print STDERR "\r$current/$all [$c] ";
    }
    my $n = 0;
  if (1 == length $c) {
    $n = ord $c;
  } elsif (2 == length $c) {
    my $cc2 = ord substr $c, 1;
    if (0xE0100 <= $cc2) {
      $n = ((($cc2 - 0xE0100) % 8) + 4) * 0x10000 + ord $c;
    } else {
      $n = $cc2 + ord $c;
    }
  } elsif ($c =~ /^:u([0-9a-f]+)/) {
    $n = hex $1;
  } elsif ($c =~ /^:u-[a-z]+-([0-9a-f]+)/) {
    $n = 300000 + hex $1;
  } elsif ($c =~ /\A:([A-Za-z]+)([0-9]+)/) {
    $n = 0+$2;
    my $i = $to_index->{$1};
    $n = ($i // 4) * 100000 + $n;
  } elsif ($c =~ /\A:([A-Za-z]+)([0-9]+)-([0-9]+)-([0-9]+)/) {
    $n = $2*94*94 + $3*94 + $4;
    my $i = $to_index->{$1};
    $n = ($i // 4) * 100000 + $n;
  } elsif ($c =~ /\A:([A-Za-z]+[0-9]-)([0-9]+)/) {
    $n = 0+$2;
    my $i = $to_index->{$1};
    $n = ($i // 4) * 100000 + $n;
  } elsif ($c =~ /\A:(.)/) {
    $n = ord $1;
  } elsif (length $c) {
    $n = ord $c;
  }

  if (not defined $CharArray->[$n]) {
    $CharArray->[$n] = $c;
    next C;
  }

  my $m = $n-1;
  while ($m > 0) {
    if (not defined $CharArray->[$m]) {
      $CharArray->[$m] = $c;
      next C;
    }
    $m--;
  }
  $m = $n+1;
  while (1) {
    if (not defined $CharArray->[$m]) {
      $CharArray->[$m] = $c;
      next C;
    }
    $m++;
  }
} # C
}

{
  my $path = $DataPath->child ('char-cluster-index.jsonl');
  print STDERR "\r Writing |$path|... ";
  my $file = $path->openw;
  for (@$CharArray) {
    print $file perl2json_bytes $_;
    print $file "\x0A";
  }
}

{
  my $time = time - $StartTime;
  print STDERR "\rElapsed: $time [s] \n";
}
