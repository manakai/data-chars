use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;

binmode STDERR, qw(:encoding(utf-8));

my $MergedChars;
{
  my $path = $DataPath->child ('merged-chars.json');
  print STDERR "\rLoading |$path|... ";
  $MergedChars = json_bytes2perl $path->slurp;
}

my $CharArray = [];
{
  print STDERR "\rAssigning... ";
  my $offset = {};
  my $next = 0;
  $offset->{'u-immi-'} = ($next += 0x110000) - 0xE000;
  $offset->{'u-juki-'} = ($next += 0xF000 - 0xE000) - 0xA000;
  $offset->{'u-cns-'} = ($next += 0xFB00 - 0xA000) - 0xF0000;
  $offset->{'u-gb-'} = ($next += 0x100000 - 0xF0000) - 0xE000;
  $offset->{'u-bigfive-'} = ($next += 0xF900 - 0xE000) - 0xE000;
  $next = 100000;
  $offset->{$_} = ($next += 100000) for qw(MJ aj aj2- ac ag ak ak1- swc);
  $offset->{jis} = ($next += 100000) - 1*94*94;
  $offset->{gb} = ($next += 2*94*94);
  $offset->{ks} = ($next += 5*94*94);
  $offset->{kps} = ($next += 2*94*94);
  $offset->{oldcns} = ($next += 1*94*94) - 14*94*94;
  $offset->{cns} = ($next += 1*94*94) + 1*94*94;
  
  my $all = 0+keys %$MergedChars;
  my $current = 0;

  C: for my $c (sort {
    (length $a) <=> (length $b) ||
    $a cmp $b
  } keys %$MergedChars) {
    if (not ($current++ % 1000)) {
      print STDERR "\rAssigning $current/$all [$c] ";
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
  } elsif ($c =~ /^:(u-[a-z]+-)([0-9a-f]+)/) {
    $n = $offset->{$1} + hex $2;
  } elsif ($c =~ /\A:([A-Za-z]+|[A-Za-z]+[0-9]+-)([0-9]+)$/) {
    $n = ($offset->{$1} // 0xD0000) + $2;
  } elsif ($c =~ /\A:([A-Za-z]+)([0-9]+)-([0-9]+)-([0-9]+)/) {
    $n = $2*94*94 + ($3-1)*94 + ($4-1);
    $n = ($offset->{$1} // 0xD0000) + $n;
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
      #if ($m - $n > 100) {
      #  warn "Too many retries for |$c|\n";
      #}
      
      $CharArray->[$m] = $c;
      next C;
    }
    $m--;
  }
  $m = $n+1;
  while (1) {
    if (not defined $CharArray->[$m]) {
      #if ($m - $n > 100) {
      #  warn "Too many retries for |$c|\n";
      #}
      
      $CharArray->[$m] = $c;
      next C;
    }
    $m++;
  }
} # C
}

{
  print STDERR "\rWriting [1/1]... ";
  for (@$CharArray) {
    print perl2json_bytes $_;
    print "\x0A";
  }
}

printf STDERR "\rDone (%d s) \n", time - $StartTime;

## License: Public Domain.
