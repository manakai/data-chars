use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $DataPath = path (".");
my $StartTime = time;

my $Merged;
my $LevelByIndex = [];
{
  my $path = $DataPath->child ('merged-index.json');
  $Merged = json_bytes2perl $path->slurp;
  $LevelByIndex->[$_->{index}] = $_ for values %{$Merged->{cluster_levels}};
}
my $ClusterIndex;
{
  my $path = $DataPath->child ('cluster-index.json');
  $ClusterIndex = json_bytes2perl $path->slurp;
}

my $Tables = {};
my $Others = {};
my $TableData = {};

{
  my $i = 0;
  my $path = $DataPath->child ("char-cluster.jsonl");
  my $file = $path->openr;
  local $/ = "\x0A";
  while (<$file>) {
    $i++;
    printf STDERR "\r%d... ", $i if ($i % 10000) == 0;
    my $json = json_bytes2perl $_;
    my $c = $json->[0];
    for (0..$#{$json->[1]}) {
      my $level = $LevelByIndex->[$_];
      next unless $level->{key} eq 'EQUIV';
      my $cid = $json->[1]->[$_] + 1;
      if (1 == length $c) {
        my $cc = ord $c;
        $TableData->{$level->{key}}->{unicode}->{$cc} = [$cid, $c];
        next;
      } elsif ($c =~ /\A(.)(\p{Variation_Selector}|[\x{3099}-\x{309C}])\z/s) {
        my $cc1 = ord $1;
        my $cc2 = ord $2;
        $TableData->{$level->{key}}->{'unicode-suffix-' . $cc2}->{$cc1} = [$cid, $c];
        next;
      } elsif ($c =~ /\A([\x{1100}-\x{D7FF}])([\x{1160}-\x{11A7}])\z/) {
        my $cc1 = (ord $1) - 0x1100;
        my $cc2 = (ord $2) - 0x1160;
        my $cc = $cc1 * (0xA7-0x5F) + $cc2;
        $TableData->{$level->{key}}->{'unicode-hangul2'}->{$cc} = [$cid, $c];
        next;
      } elsif ($c =~ /\A([\x{1100}-\x{D7FF}])([\x{1160}-\x{1175}])([\x{11A8}-\x{11C2}])\z/) {
        my $cc1 = (ord $1) - 0x1100;
        my $cc2 = (ord $2) - 0x1160;
        my $cc3 = (ord $3) - 0x11A8;
        my $cc = $cc1 * (0x75-0x5F) * (0xC2-0xA7) + $cc2 * (0xC2-0xA7) + $cc3;
        $TableData->{$level->{key}}->{'unicode-hangul3'}->{$cc} = [$cid, $c];
        next;
      } elsif ($c =~ /\A:(MJ|aj|ac|ag|ak|aj2-|ak1-|UK-|swc)([0-9]+)\z/) {
        my $prefix = $1;
        my $cc = 0+$2;
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        next;
      } elsif ($c =~ /\A:(u-[a-z]+-)([0-9a-f]+)\z/) {
        my $prefix = $1;
        my $cc = hex $2;
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        next;
      } elsif ($c =~ /\A:(b5-)([0-9a-f]+)\z/) {
        my $prefix = $1;
        my $cc = hex $2;
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        next;
      } elsif ($c =~ /\A:(b5-[a-z]+-)([0-9a-f]+)\z/) {
        my $prefix = $1;
        my $cc = hex $2;
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        next;
      } elsif ($c =~ /\A:(jis|jis-[a-z]+-)([0-9]+)-([0-9]+)-([0-9]+)\z/) {
        my $prefix = $1;
        my $cc = $2*(94+(0xFC-0xEF)*2)*94 + ($3-1)*94 + ($4-1);
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        next;
      } elsif ($c =~ /\A:(cns|cns-[a-z]+-|gb|ks|kps|cccii)([0-9]+)-([1-9][0-9]*)-([1-9][0-9]*)\z/) {
        my $prefix = $1;
        my $cc = $2*(94)*94 + ($3-1)*94 + ($4-1);
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        next;
      }

      $Others->{$level->{key}}->{$c} = $cid;
    } # $level
  }
}
for my $level_key (keys %$TableData) {
  for my $key (keys %{$TableData->{$level_key}}) {
    my $cs = [];
    for my $cc (keys %{$TableData->{$level_key}->{$key}}) {
      $cs->[int ($cc / 0x100)]++;
    }
    my $ranges = [];
    my $in_range = 0;
    my $to_range = {};
    for (0..$#$cs) {
      if (($cs->[$_] || 0) > 0x100/3) {
        if ($in_range or
            (@$ranges and $_ * 0x100 - $ranges->[-1]->[1] < 0x100*2)) {
          $ranges->[-1]->[1] = $_ * 0x100 + 0x100;
        } else {
          $in_range = 1;
          push @$ranges, [$_ * 0x100, $_ * 0x100 + 0x100];
        }
        $to_range->{$_} = $ranges->[-1];
      } else {
        if ($in_range) {
          $in_range = 0;
        } else {
          #
        }
      }
    }
    for my $cc (keys %{$TableData->{$level_key}->{$key}}) {
      my $range = $to_range->{int ($cc / 0x100)};
      my $cv = $TableData->{$level_key}->{$key}->{$cc};
      if (defined $range) {
        $Tables->{sprintf "%s:%s:%09d", $level_key, $key, $range->[0]}->[$cc - $range->[0]] = $cv->[0];
      } else {
        $Others->{$level_key}->{$cv->[1]} = $cv->[0];
      }
    } # $cc
  } # $key
} # $level_key

my $Rels = {};
{
  for my $c1 (keys %{$ClusterIndex->{inset_pairs}}) {
    for my $c2 (keys %{$ClusterIndex->{inset_pairs}->{$c1}}) {
      $ClusterIndex->{inset_pairs}->{$c2}->{$c1} = 1;
    }
  }
  my $u = $Merged->{inset_mergeable_weight};
  
  my $path = $DataPath->child ('merged-rels.jsonll');
  print STDERR "\r|$path|...";
  my $file = $path->openr;
  local $/ = "\x0A\x0A";
  while (<$file>) {
    my $c1 = json_bytes2perl $_;
    my $c1v = json_bytes2perl scalar <$file>;

    for my $c2 (keys %{$ClusterIndex->{inset_pairs}->{$c1} or {}}) {
      $c1v->{$c2}->{'manakai:inset'} //= -1;
      $c1v->{$c2}->{_} //= -1;
      $c1v->{$c2}->{_u} //= $u;
      if ($c1v->{$c2}->{_u} > $u) {
        $c1v->{$c2}->{_u} = $u;
      }
    }
    
    $Rels->{$c1} = $c1v;
  }
}

my $TableMeta = {tables => [], others => $Others};
{
  my $path = $DataPath->child ('tbl-clusters.dat');
  my $file = $path->openw;
  my $index = 0;
  for my $key (sort { $a cmp $b } keys %$Tables) {
    my $def = {offset => $index};
    if ($key =~ /^([A-Z]+):unicode-suffix-([0-9]+):([0-9]+)$/) {
      $def->{level_key} = $1;
      $def->{type} = 'unicode-suffix';
      $def->{suffix} = 0+$2;
      $def->{code_offset} = 0+$3;
    } elsif ($key =~ /^([A-Z]+):([A-Za-z0-9_-]+):([0-9]+)$/) {
      $def->{level_key} = $1;
      $def->{type} = $2;
      $def->{code_offset} = 0+$3;
    } elsif ($key =~ /^([A-Z]+):unicode-hangul2$/) {
      $def->{level_key} = $1;
      $def->{type} = 'unicode-hangul2';
      $def->{code_offset} = 0;
    } elsif ($key =~ /^([A-Z]+):unicode-hangul3$/) {
      $def->{level_key} = $1;
      $def->{type} = 'unicode-hangul3';
      $def->{code_offset} = 0;
    } elsif ($key =~ /^([A-Z]+):(MJ|jis|jis-[a-z]+-|cns|cns-[a-z]+-|gb|ks|kps|aj|ac|ag|ak|aj2-|ak1-|UK-|u-[a-z]+-|b5-|b5-[a-z]+-|cccii|swc)$/) {
      $def->{level_key} = $1;
      $def->{type} = $2;
      $def->{code_offset} = 0;
    } else {
      die $key;
    }
    my $skip = 0;
    while (@{$Tables->{$key}}) {
      if (not defined $Tables->{$key}->[0]) {
        $skip++;
        shift @{$Tables->{$key}};
      } else {
        last;
      }
    }
    $def->{code_offset} += $skip;
    for (@{$Tables->{$key}}) {
      print $file substr ((pack 'L>', $_ // 0), 1);
      $index += 3;
    }
    $def->{offset_next} = $index;
    $def->{code_offset_next} = $def->{code_offset} + @{$Tables->{$key}};
    push @{$TableMeta->{tables} ||= []}, $def;
  }
}

{
  my $path = $DataPath->child ('tbl-rels.dat');
  my $file = $path->openw;

  print $file "\x00";
  my $rel_keys = {};
  for my $c1 (sort { $a cmp $b } keys %$Rels) {
    print $file encode_web_utf8 $c1;
    print $file "\x01";
    for my $c2 (sort { $a cmp $b } keys %{$Rels->{$c1}}) {
      my $v = $Rels->{$c1}->{$c2};
      print $file encode_web_utf8 $c2;
      print $file "\x01";
      for my $key (sort { $a cmp $b } grep { not /^_/ } keys %$v) {
        unless (defined $rel_keys->{$key}) {
          $rel_keys->{$key} = 0+keys %$rel_keys;
          $TableMeta->{rels}->[$rel_keys->{$key}] = {
            key => $key,
            weight => ($Merged->{rel_types}->{$key}->{weight} // die $key),
            mergeable_weight => ($Merged->{rel_types}->{$key}->{mergeable_weight} // die $key),
          };
        }
        my $x = $rel_keys->{$key};
        print $file pack 'CC',
            0b10000000 | ($x >> 7),
            0b10000000 | ($x & 0b01111111);
      }
      print $file "\x01";
    }
    print $file "\x00";
  }
}

{
  my $path = $DataPath->child ('tbl-index.json');
  $path->spew (perl2json_bytes_for_record $TableMeta);
}

printf STDERR "\rDone (%s s) \n", time - $StartTime;
