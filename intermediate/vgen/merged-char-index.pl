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
  for my $x (
    ['u',          '',  0x0000, 0x10FFFF],
    (map {
      [(chr $_),   '',  0x3400,  0x3FFFF],
    } 0xE0100..0xE0104), # IVSes
    ['u-old-',     '',  0x3400,   0x4DFF],
    ['u-immi-',    '',  0xE000,   0xEFFF],
    ['u-juki-',    '',  0x0000,   0xFFFF],
    ['u-cns-',     '', 0xF0000,  0xFFFFF],
    ['u-gb-',      '',  0xE000,   0xF8FF],
    ['u-bigfive-', '',  0xE000,   0xF8FF],
    ['u-uka-',     '',  0xE000,   0xF73F],
    ['u-ukb-',     '',  0xE53B,   0xF7D5],
    ['u-arib-',    '',  0xE000,   0xF8FF],
    ['u-kps-',     '',  0xF000,   0xF1FF],
    ['u-ms-',      '',  0xE000,   0xF8FF],
    ['u-mac-',     '',  0xE000,   0xF8FF],
    ['jis1-',      '',       1,    (94+(0xFC-0xEF)*2)*94],
    ['jis-dos-1-', '',       1,    (94+(0xFC-0xEF)*2)*94],
    ['jis-mac-1-', '',       1,    (94+(0xFC-0xEF)*2)*94],
    ['jis-arib-1-','',       1,    (94+(0xFC-0xEF)*2)*94],
    ['jis2-',      '',       1,    94*94],
    ['gb0-',       '',       1,    94*94],
    ['gb1-',       '',       1,    94*94],
    ['gb2-',       '',       1,    94*94],
    ['gb4-',       '',       1,    94*94],
    ['gb8-',       '',       1,    94*94],
    ['gb20-',      '',       1,    94*94], # GK
    ['ks0-',       '',       1,    94*94],
    ['ks1-',       '',       1,    94*94],
    ['kps0-',      '',       1,    94*94],
    (map {
      ['cccii'.$_.'-',  '',       1,    94*94],
    } 1..94),
    ['cns-old-14-','',       1,    94*94],
    (map {
      ['cns'.$_.'-',  '',       1,    94*94],
    } 1..94), # 1 - 80
    (map {
      ['tron'.$_.'-',  '', 0x2121, 0xFDFD],
    } 1, 9, 'old9', 10),
    ['MJ',         '', 0000000,   999999],
    ['aj',         '',       0,    99999],
    ['aj2-',       '',       0,     6067],
    ['ac',         '',       0,    99999],
    ['ag',         '',       0,    99999],
    ['ak',         '',       0,    99999],
    ['ak1-',       '',       0,    18351],
    ['UK-',        '',   00000,    99999],
    ['b5-',        '',  0x8140,   0xFEFE],
    ['b5-uao-',    '',  0x8140,   0xFEFE],
    ['b5-hkscs-',  '',  0x8140,   0xFEFE],
    ['u-uao-',     '',  0xE000,   0xF8FF],
    ['u-hkscs-',   '',  0xE000,   0xF8FF],
    ['u-loc-',     '',  0xE000,   0xF8FF],
    ['swc',        '',       0,   999999],
  ) {
    $offset->{$x->[0]} = $next - $x->[2];
    $next += $x->[3] - $x->[2] + 1;
    #warn "$x->[0]\t@{[$offset->{$x->[0]}+$x->[2]]}\n";
  }
  # u-old- 0x00E00000 ... 0x00FFFFFF , 0x60000000 - 0x7FFFFFFF
  die if $next > 0x00E00000;
  
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
    if ($c =~ /^[\x{3400}-\x{3FFFF}][\x{E0100}-\x{E0104}]$/) {
      $n = $offset->{chr $cc2} + ord $c;
    } elsif (0xE0100 <= $cc2) {
      $n = ((($cc2 - 0xE0100) % 8) + 4) * 0x10000 + ord $c;
    } else {
      $n = $cc2 + ord $c;
    }
  } elsif ($c =~ /^:u([0-9a-f]+)/) {
    $n = hex $1;
  } elsif ($c =~ /^:(u-old-)([0-9a-f]+)$/) {
    my $cc = hex $2;
    if ($cc <= 0x10FFFF) {
      $n = ($offset->{$1} // 0xA00000) + hex $2;
    } else {
      $n = $cc;
    }
  } elsif ($c =~ /^:(u-[a-z]+-)([0-9a-f]+)/) {
    $n = ($offset->{$1} // 0xA00000) + hex $2;
  } elsif ($c =~ /^:(b5-)([0-9a-f]+)/) {
    $n = ($offset->{$1} // 0xA00000) + hex $2;
  } elsif ($c =~ /^:(b5-[a-z]+-)([0-9a-f]+)/) {
    $n = ($offset->{$1} // 0xA00000) + hex $2;
  } elsif ($c =~ /\A:([A-Za-z]+-?|[A-Za-z]+[0-9]+-)([0-9]+)$/) {
    $n = ($offset->{$1} // 0xA00000) + $2;
  } elsif ($c =~ /\A:([A-Za-z]+(?:-[a-z]+-|)[0-9]+-)([0-9]+)-([0-9]+)/) {
    $n = ($2-1)*94 + ($3-1);
    $n = ($offset->{$1} // 0xA00000) + $n;
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
