use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;
my $Index = {};

{
  my $to_index = {};
  my $PrefixPattern;
  {
    my $prefixes = [qw(
      MJ MJ00 MJ000 MJ001 MJ002 MJ003 MJ004 MJ005 MJ006
      MJ01 MJ010 MJ011 MJ012 MJ013 MJ014 MJ015
      MJ02 MJ020 MJ021 MJ022 MJ023 MJ024 MJ025
      MJ030 MJ031 MJ032 MJ033 MJ034 MJ035 MJ036 MJ037 MJ038 MJ039
      MJ04 MJ040 MJ041 MJ042 MJ043 MJ044
      MJ05 MJ050 MJ051 MJ052 MJ053 MJ054
      MJ06
      ac ac1 ac2 ag ag1 ag2
      aj1 aj11 aj12 aj13 aj14 aj15 aj16 aj17 aj18 aj19
      aj2 aj3 aj4 aj5 aj6 aj7 aj8 aj9 aj aj2-1 aj2-
      ak ak1 ak2 ak1-
      j jmj jmj-01 jmj-02 jmj-03 jmj-04 jmj-05 jsp
      ju juc juki-3 juki-4 juki-5 juki-6 juki-7 juki-8 juki-9 juki-a juki-f
      jis1 jis1-1 jis1-2 jis1-3 jis1-4 jis1-5 jis1-6 jis1-7 jis1-8 jis1-9
      jis2 jis2-1 jis2-2 jis2-3 jis2-4 jis2-5 jis2-6 jis2-7 jis2-8 jis2-9
      jis-arib u-arib jistype jis-dot
      c cns cns-old cns1 cns1-1 cns2 cns2-1 cns3 cns3-1 cns4 cns4-1
      cns5 cns6 cns7 cns8 cns9 cns10 cns11 cns12 cns13 cns14 cns15
      cns16 cns17 cns18 cns19 u-cns u-cns-f0 u-cns-f1 u-cns-f2 u-cns-f3
      u-cns-f6 u-cns-fd u-cns-ff
      cbeta cdp 
      g gb0 gb0-1 gb0-2 gb1 gb2 gb3 gb8 gb u-gb
      u UK u-uk sat u0
      u1 u10 u11 u12 u13 u1a u1b u1c u1d u1e u1f
      u2 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29
      u2a u2b u2c u2d u2e u2f u2ff
      u2ff0 u2ff0-u4 u2ff0-u5 u2ff0-u6 u2ff0-u7 u2ff0-u2 u2ff0-uf
      u2ff1 u2ff2
      u3 u30 u31 u32 u33 u34 u35 u36 u37 u38 u39 u3a u3b u3c u3d u3e u3f
      u4 u5 u50 u51 u52 u53 u54 u55 u56 u57 u58 u59 u5a u5b u5c u5d u5e u5f
      u6 u60 u61 u62 u63 u64 u65 u66 u67 u68 u69 u6a u6b u6c u6d u6e u6f
      u7 u70 u71 u72 u73 u74 u75 u8 u80 u81 u82 u83 u84 u85 u86 u87 u88 u89
      u9 u90 u91 u92 u93 u94 u95 u96 u97 u98 u99 ua ub uc ud ue uf un u-
      swc
      b b5 b5-8 b5-9 b5-a b5-b b5-c b5-d b5-e b5-f b5-hkscs b5-uao b5-cdp 
      u-bigfive u-hkscs u-uao
      cccii cccii1 cccii2 cccii3 cccii4 cccii9
      k k0 k5 ka ke ks kps cjkvi
      ko koseki koseki0 koseki1 koseki2 koseki3 koseki4 koseki5
      koseki-0 koseki-1 koseki-2 koseki-3 koseki-4 koseki-5 koseki-9
      n ni ny
      t touki twedu toki tron t0 tron1 tron2 tron3 tron4 tron5 tron6 tron7
      tron8 tron9 tron10 tron11 tron12 tron16 tron17
      KS KS0 KS1 KS2 KS3 TK J JA JB JC JD JT I
      d d0 d1 di dot dsf dsff dsfull dsfff dsfff1 dsfff2 dsfff3 dsfff4 dsfff5
      dsffull dsffull1 dsffull2 dsffull3 dsffull4 dsffull5 dsffull6
      dkw dkw-h dkw-0 dkw-1 dkw-2 dkw-3 dkw-4
      m m1 m2 m20 m21 m22 m23 m24 m2a m2b m2c m2d m2e m2f
      m3 m4 m5 m6 m7 m8 m9 F G I r s s0 s1 sa si w v supercjk
      kx kx0 kx1 y
      h hk hkrm-01 hkrm-02 hkrm-03 hkrm-04 hkrm-05 hkrm-06 hi he
      g gt gt1 gt2 gt3 gt4 gt5 gt6 gt7 gt8 gt9 g9
      e ext extd extf
      q
      z z-sat zihai
    )];
    my $x = 0x500;
    $to_index->{$_} = $x++ for @$prefixes;
    $Index->{prefix_to_index} = $to_index;

    $Index->{prefix_pattern} =
    $PrefixPattern = join '|', sort { (length $b) <=> (length $a) || $a cmp $b } @$prefixes;
  }

  sub char_to_index ($) {
    my $c1 = $_[0];
    my $c1l = length $c1;
    if ($c1l == 1) {
      my $c = ord $c1;
      if ($c <= 0x10FFFF) {
        return 1 + int ($c / 0x200);
      }
    } elsif ($c1l == 2) {
      my $code1 = ord $c1;
      my $x = $code1 % 2 ? 0x100 : 0;
      my $vs = ord substr $c1, 1;
      if (0xE0100 <= $vs and $vs <= 0xE01FF) {
        return $vs - 0xE0000 + $x;
      } else {
        return 0xFF;
      }
    } elsif ($c1 =~ /([\x{2FF0}-\x{2FFF}])/) {
      return 0x300 - 0x30 - 0x2FF0 + (ord $1) + (ord substr $c1, -2, 1) % 0x10 + (ord substr $c1, -1, 1) % 0x10;
    } elsif ($c1 =~ /\A:(?:gw-(?:[a-z0-9-]+_|heisei-|)|)($PrefixPattern)/o) {
      ## see also: |site.js|'s |index.prefixPattern|
      return $to_index->{$1} // die $1;
    ## see also: |site.js|'s |SWD.Char.RelData._charToIndex|.
    } elsif ($c1 =~ /^:u-/) {
      return 0x300;
    } elsif (3 <= $c1l and $c1l <= 10) {
      return 0x400 - 2 + $c1l;
    }

    return 0;
  } # char_to_index
  
  sub insert ($$$) {
    my ($char, $data => $out_files) = @_;

    my $index = char_to_index $char;

    push @{$out_files->[$index] ||= []}, $data;
  } # insert
}

my $FileKey = shift;
my $FileDef = {
  'char-cluster' => {
  },
  'char-leaders' => {
  },
  'merged-rels' => {
    paired => 1,
  },
}->{$FileKey} or die "Bad file-key |$FileKey|";

if ($FileKey eq 'merged-rels') {
  my $path = $DataPath->child ('merged-index.json');
  my $json = json_bytes2perl $path->slurp;
  $Index = {%$Index, %$json};

  my $n = 0;
  for my $rel (sort { $a cmp $b } keys %{$Index->{rel_types}}) {
    $Index->{rel_types}->{$rel}->{id} = $n++;
  }

  $Index->{timestamp} = time;
}

my $OutFiles = [];
{
  my $ext = $FileDef->{paired} ? 'jsonll' : 'jsonl';
  my $path = $DataPath->child ("$FileKey.$ext");
  print STDERR "\rLoading |$path|... ";
  my $file = $path->openr;
  if ($FileDef->{paired}) {
    local $/ = "\x0A\x0A";
    my $i = 0;
    while (<$file>) {
      print STDERR "\rLoading |$path| ($i)... " if $i++ % 1000 == 0;
      my $c1 = json_bytes2perl $_;
      my $c1v = json_bytes2perl scalar <$file>;

      my $value = {};
      for my $c2 (sort { $a cmp $b } keys %$c1v) {
        $value->{$c2} = [];
        for my $rel (sort { $a cmp $b } keys %{$c1v->{$c2}}) {
          next if $rel eq '_' or $rel eq '_u';
          push @{$value->{$c2}}, $Index->{rel_types}->{$rel}->{id};
          $Index->{rel_types}->{$rel}->{_n}++;
        }
      }
      
      insert $c1, [$c1 => $value] => $OutFiles;
    }
  } else {
    local $/ = "\x0A";
    while (<$file>) {
      my $json = json_bytes2perl $_;
      insert $json->[0], $json => $OutFiles;
    }
  }
}

{
  #for my $i (1..$#$OutFiles) {
  #  next unless defined $OutFiles->[$i];
  #  if (@{$OutFiles->[$i]} < 100) {
  #    push @{$OutFiles->[0] ||= []}, @{delete $OutFiles->[$i]};
  #  }
  #}

  $DataPath->child ($FileKey)->mkpath;
  my $ext = $FileDef->{out_paired} ? 'jsonll' : 'jsonl';
  for my $path (($DataPath->child ($FileKey)->children (qr/^part-[0-9]+\.\Q$ext\E$/))) {
    $path->remove;
  }
  my $all = @$OutFiles;
  for my $i (0..$#$OutFiles) {
    next unless defined $OutFiles->[$i];
    next unless @{$OutFiles->[$i]};

    print STDERR "\rWriting[$i/$all] (@{[0+@{$OutFiles->[$i]}]})... "
        if $i % 100 == 0;
    my $path = $DataPath->child ("$FileKey/part-$i.$ext");
    my $file = $path->openw;
    
    if ($FileDef->{out_paired}) {
      @{$OutFiles->[$i]} = sort { $a->[0] cmp $b->[0] } @{$OutFiles->[$i]};
      if ($FileDef->{pretty}) {
        for (@{$OutFiles->[$i]}) {
          print $file perl2json_bytes_for_record $_->[0]; # trailing \x0A
          print $file "\x0A";
          print $file perl2json_bytes_for_record $_->[1]; # trailing \x0A
          print $file "\x0A";
        }
      } else {
        for (@{$OutFiles->[$i]}) {
          print $file perl2json_bytes $_->[0];
          print $file "\x0A";
          print $file perl2json_bytes $_->[1];
          print $file "\x0A";
        }
      }
    } else {
      @{$OutFiles->[$i]} = sort { $a->[0] cmp $b->[0] } @{$OutFiles->[$i]};
      for (@{$OutFiles->[$i]}) {
        print $file perl2json_bytes $_;
        print $file "\x0A";
      }
    }
  } # $i

  {
    $Index->{rel_types} = {map {
      if (delete $Index->{rel_types}->{$_}->{_n}) {
        ($_ => $Index->{rel_types}->{$_});
      } else {
        ();
      }
    } keys %{$Index->{rel_types}}};

    my $path = $DataPath->child ("$FileKey/index.json");
    my $file = $path->openw;
    print $file perl2json_bytes $Index;
  }
}

printf STDERR "\rDone (%d s) \n", time - $StartTime;

## License: Public Domain.
