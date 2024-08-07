use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;

binmode STDERR, qw(:encoding(utf-8));
STDERR->autoflush (1);

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
  my $next_random = 0x1000000;
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
    ['u-jeju-',    '',  0xE001,   0xE0A0],
    ['koseki',     '',       0,   999999],
    ['ninjal',     '',    0100,     4799],
    ['jisx0201-',  '',    0x00,     0xFF],
    ['jisx0201-mac-','',  0x00,     0xFF],
    ['jisx0201-ocrk-','', 0x00,     0xFF],
    ['jisx0201-ocrhk-','',0x00,     0xFF],
    ['wakan',      '',       0,(0x93-0x41)*10],
    ['arib-30-',   '',    0x21,     0x7E],
    ['arib-31-',   '',    0x21,     0x7E],
    ['arib-36-',   '',    0x21,     0x7E],
    ['arib-37-',   '',    0x21,     0x7E],
    ['arib-38-',   '',    0x21,     0x7E],
    ['u-nom-',     '', 0xF0000,  0xFFFFF],
    ['touki',      '', 1000000,  1999999],
    ['-heisei-94', '',       1,2*5*94*94], # JA/JC JB/JD FT IA IB
    ['HG',         '',       1,       94],
    ['IP',         '',  0x4E00,   0x9FFF],
    ['JT',         '',  0x3400,   0xC0FF],
    ['KS',         '',       0,   999999],
    ['TK',         '', 1000000,  1999999],
    ['m',          '',       0,    99999],
    ["m'",         '',       0,    49999],
    ['b5-cdp-',    '',  0x8140,   0xFEFE],
    ['kps1',       '',  0x0000,   0xFFFF],
    ['gb7-',       '',       1,    94*94],
    ['gb14-',      '',       1,    94*94],
    ['gb28-',      '',       1,    94*94], # GS
    ['kx',         '',       0,   999999],
    ['extf',       '',       0,     9999],
    ['jis-dot16-1-','',      1,    84*94],
    ['jis-dot24-1-','',      1,    84*94],
    ['sat',        '',       0,    99999],
    ['dsf',        '',       0,    49999],
    ['dsffull',    '',       0,    49999],
    ['dsfff',      '',       0,    49999],
    ['swc',        '',       0,   999999],
  ) {
    $offset->{$x->[0]} = $next - $x->[2];
    $next += $x->[3] - $x->[2] + 1;
    #warn "$x->[0]\t@{[$offset->{$x->[0]}+$x->[2]]}\n";
  }
  $offset->{'jis-dot16v-1-'} = $offset->{'jis-dot16-1-'};
  $offset->{'jis-dot24v-1-'} = $offset->{'jis-dot24-1-'};
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
  } elsif ($c =~ /^:(u-[a-z]+-|b5-(?:[a-z]+-|)|tron[0-9]+-|jisx0201-(?:[a-z]+-|)|arib-3[01678]-)([0-9a-f]+)/) {
    $n = ($offset->{$1} // 0xA00000) + hex $2;
  } elsif ($c =~ /\A:(ninjal)([0-9]{2})([0-9]{3})([0-9]{4})\z/) {
    $n = $offset->{$1} + $2 * 100 + $3 * 10 + $4;
  } elsif ($c =~ /\A:(JA|JB|JC|JD|FT|IA|IB)([0-9]{2})([0-9]{2})(S*)\z/) {
    $n = ($2-1)*94 + ($3-1);
    $n = ($offset->{'-heisei-94'} // 0xA00000) + 94*94*({
      JA => 0,
      JB => 1,
      JC => 0,
      JD => 1,
      FT => 2,
      IA => 3,
      IB => 4,
    }->{$1}) + ($4 ? 1*5*94*94 : 0) + $n;
  } elsif ($c =~ /\A:(JT|IP)([0-9A-F]+)S*$/) {
    $n = ($offset->{$1} // 0xA00000) + hex $2;
  } elsif ($c =~ /\A:m([0-9]+)'+$/) {
    $n = ($offset->{"m'"} // 0xA00000) + $1;
  } elsif ($c =~ /\A:(HG|kps1-)([0-9A-Fa-f]+)S*$/) {
    $n = ($offset->{$1} // 0xA00000) + hex $2;
  } elsif ($c =~ /\A:([A-Za-z]+-?|[A-Za-z]+[0-9]+-)([0-9]+)S*$/) {
    $n = ($offset->{$1} // 0xA00000) + $2;
  } elsif ($c =~ /\A:(a[a-z]|ak1-)([0-9]+):(?:a[a-z]|ak1-)([0-9]+)$/) {
    $n = ($offset->{$1} // 0xA00000) + $2 + $3;
  } elsif ($c =~ /\A:(a[a-z]|ak1-)([0-9]+):(?:a[a-z]|ak1-)([0-9]+):(?:a[a-z]|ak1-)([0-9]+)$/) {
    $n = ($offset->{$1} // 0xA00000) + $2 + $3 + $4;
  } elsif ($c =~ /\A:(a[a-z]|ak1-)([0-9]+):(?:a[a-z]|ak1-)([0-9]+):(?:a[a-z]|ak1-)([0-9]+):(?:a[a-z]|ak1-)([0-9]+)/) {
    $n = ($offset->{$1} // 0xA00000) + $2 + $3 + $4 + $5;
  } elsif ($c =~ /\A:([A-Za-z]+(?:-[a-z][a-z0-9]*-|)[0-9]+-)([0-9]+)-([0-9]+)/) {
    $n = ($2-1)*94 + ($3-1);
    $n = ($offset->{$1} // 0xA00000) + $n;
  } elsif ($c =~ /\A:(wakan)-(\p{sc=Hiragana})(\d\d)\d\z/) {
    $n = $offset->{$1} + ((ord $2) - 0x3042) * 10 + $3;
  } elsif ($c =~ /\A:(kx)([0-9]+)\.([0-9]+)$/) {
    $n = ($offset->{$1} // 0xA00000) + $2*100 + $3;
  } elsif ($c =~ /\A([\x{1100}-\x{11FF}])([\x{1100}-\x{11FF}])$/) {
    $n = 0xA0000 + ((ord $1) - 0x1100) * 0x100 + (ord $2) - 0x1100;
  } elsif ($c =~ /\A([\x{1100}-\x{11FF}])([\x{1100}-\x{11FF}])([\x{1100}-\x{11FF}])$/) {
    $n = 0xA0000 + ((ord $1) - 0x1100) * 0x10000 +
                   ((ord $2) - 0x1100) * 0x100 +
                    (ord $3) - 0x1100;
    } elsif ($c =~ /\A(?::[^:]+:|)\p{Ideographic_Description_Characters}/) {
      $n = $next_random++;
    } elsif ($c =~ /\A(?::[^:]+:|[\\\{]+)(.)(.?)(.?)/) {
      $n = (ord $1) + (defined $2 ? 0x100 * ord $2 : 0) + (defined $3 ? 0x100 * ord $3 : 0);
    } elsif ($c =~ /\A([A-Za-z0-9][\x20-\x7E]+)\z/) {
      $n = 0;
      $n += $_ for map { ord $_ } split //, $1;
    } elsif ($c =~ /\A([^:])(.)$/) {
      $n = (ord $1) + (ord $2);
    } elsif ($c =~ /\A([^:])(.)(.)/) {
      $n = (ord $1) + (ord $2) + (ord $3);
    } elsif ($c =~ /\A([^:])(.)(.)(.)/) {
      $n = (ord $1) + (ord $2) + (ord $3) + (ord $4);
    } elsif ($c =~ /\A([^:])(.)(.)(.)(.)/) {
      $n = (ord $1) + (ord $2) + (ord $3) + (ord $4) + (ord $5);
    } elsif ($c =~ /\A:gw-/) {
      $n = $next_random++;
    } elsif ($c =~ /\A:gw-u([0-9a-f]+)-u([0-9a-f]+)/) {
      $n = 0xC0000 + (hex $1) + (hex $2) * 0x10;
    } elsif ($c =~ /\A:gw-u([0-9a-f]+)(?:-(.))/) {
      $n = 0x200000 + (hex $1) * 0x100 + (defined $2 ? ord $2 : 0x60);
    } elsif ($c =~ /\A:.+([0-9a-f]+)/) {
      $n = 0x80000 + hex $1;
    }

    if (not defined $CharArray->[$n]) {
      $CharArray->[$n] = $c;
      next C;
    }

    my $m = $n-1;
    while ($m > 0) {
    if (not defined $CharArray->[$m]) {
      if ($m - $n > 100) {
        warn "Too many retries for |$c| (1)\n";
      }

      $CharArray->[$m] = $c;
      next C;
    }
    $m--;
  }
    $m = $n+1;
    
  while (1) {
    if (not defined $CharArray->[$m]) {
      if ($m - $n > 100) {
        warn "Too many retries for |$c| (2), $m\n";
      }
      
      $CharArray->[$m] = $c;
      next C;
    }
    #if ($m - $n > 1000) {
    #  die "Really too many retries for |$c| (2)\n";
    #}
    $m++;
  }
  } # C
}

{
  my $n = 0+@$CharArray;
  print STDERR "\rWriting [0/$n]... ";
  my $i = 0;
  for (@$CharArray) {
    print STDERR "\rWriting [$i/$n]... " if ($i++ % 1000000) == 0;
    print perl2json_bytes $_;
    print "\x0A";
  }
}

printf STDERR "\rDone (%d s) \n", time - $StartTime;

## License: Public Domain.
