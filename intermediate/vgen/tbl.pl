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
        if ($cc >= 0x20000) {
          $Tables->{$level->{key} . ':unicode-' . 0x20000}->[$cc - 0x20000] = $cid;
          next;
        } elsif ($cc >= 0xA000) {
          #
        } elsif ($cc >= 0x3400) {
          $Tables->{$level->{key} . ':unicode-' . 0x3400}->[$cc - 0x3400] = $cid;
          next;
        } else {
          #
        }
      } elsif ($c =~ /\A(.)(\p{Variation_Selector})\z/s) {
        my $cc1 = ord $1;
        my $cc2 = ord $2;
        $Tables->{$level->{key} . ':unicode-suffix-' . $cc2}->[$cc1] = $cid;
        next;
      } elsif ($c =~ /\A:(MJ|aj|ac|ag|ak|aj2-|ak1-|UK-|swc)([0-9]+)\z/) {
        my $prefix = $1;
        my $cc1 = 0+$2;
        $Tables->{$level->{key} . ':' . $prefix}->[$cc1] = $cid;
        next;
      } elsif ($c =~ /\A:(u-[a-z]+-)([0-9a-f]+)\z/) {
        my $prefix = $1;
        my $cc1 = hex $2;
        $Tables->{$level->{key} . ':' . $prefix}->[$cc1] = $cid;
        next;
      } elsif ($c =~ /\A:(b5-)([0-9a-f]+)\z/) {
        my $prefix = $1;
        my $cc1 = hex $2;
        $Tables->{$level->{key} . ':' . $prefix}->[$cc1] = $cid;
        next;
      } elsif ($c =~ /\A:(b5-[a-z]+-)([0-9a-f]+)\z/) {
        my $prefix = $1;
        my $cc1 = hex $2;
        $Tables->{$level->{key} . ':' . $prefix}->[$cc1] = $cid;
        next;
      } elsif ($c =~ /\A:(jis|jis-[a-z]+-)([0-9]+)-([0-9]+)-([0-9]+)\z/) {
        my $prefix = $1;
        my $cc1 = $2*(94+(0xFC-0xEF)*2)*94 + ($3-1)*94 + ($4-1);
        $Tables->{$level->{key} . ':' . $prefix}->[$cc1] = $cid;
        next;
      } elsif ($c =~ /\A:(cns|cns-[a-z]+-|gb|ks|kps|cccii)([0-9]+)-([1-9][0-9]*)-([1-9][0-9]*)\z/) {
        my $prefix = $1;
        my $cc1 = $2*(94)*94 + ($3-1)*94 + ($4-1);
        $Tables->{$level->{key} . ':' . $prefix}->[$cc1] = $cid;
        next;
      }

      $Others->{$level->{key}}->{$c} = $cid;
    } # $level
  }
}

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

my $TableMeta = {others => $Others};
{
  my $path = $DataPath->child ('tbl-clusters.dat');
  my $file = $path->openw;
  my $index = 0;
  for my $key (sort { $a cmp $b } keys %$Tables) {
    my $def = {offset => $index};
    if ($key =~ /^([A-Z]+):unicode-([0-9]+)$/) {
      $def->{level_key} = $1;
      $def->{type} = 'unicode';
      $def->{code_offset} = 0+$2;
    } elsif ($key =~ /^([A-Z]+):unicode-suffix-([0-9]+)$/) {
      $def->{level_key} = $1;
      $def->{type} = 'unicode-suffix';
      $def->{suffix} = 0+$2;
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
