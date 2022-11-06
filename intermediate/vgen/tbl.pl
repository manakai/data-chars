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
my $CharPrefixes = {};

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
        my $cc2 = int ($cc / 0x1000);
        $CharPrefixes->{$cc2}->{type} = 'urow';
        $CharPrefixes->{$cc2}->{n}++;
        next;
      } elsif ($c =~ /\A(.)(\p{Variation_Selector}|[\x{3099}-\x{309C}])\z/s) {
        my $cc1 = ord $1;
        my $cc2 = ord $2;
        $TableData->{$level->{key}}->{'unicode-suffix-' . $cc2}->{$cc1} = [$cid, $c];
        $CharPrefixes->{$cc2}->{type} = 'suffix';
        $CharPrefixes->{$cc2}->{n}++;
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
      } elsif ($c =~ /\A:(MJ|aj|ac|ag|ak|aj2-|ak1-|UK-|koseki|swc)([0-9]+)\z/) {
        my $prefix = $1;
        my $cc = 0+$2;
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        $CharPrefixes->{$prefix}->{type} = 'dec';
        $CharPrefixes->{$prefix}->{n}++;
        next;
      } elsif ($c =~ /\A:(u-[a-z]+-)([0-9a-f]+)\z/) {
        my $prefix = $1;
        my $cc = hex $2;
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        $CharPrefixes->{$prefix}->{type} = 'hex';
        $CharPrefixes->{$prefix}->{n}++;
        next;
      } elsif ($c =~ /\A:(b5-)([0-9a-f]+)\z/) {
        my $prefix = $1;
        my $cc = hex $2;
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        $CharPrefixes->{$prefix}->{type} = 'hex';
        $CharPrefixes->{$prefix}->{n}++;
        next;
      } elsif ($c =~ /\A:(b5-[a-z]+-)([0-9a-f]+)\z/) {
        my $prefix = $1;
        my $cc = hex $2;
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        $CharPrefixes->{$prefix}->{type} = 'hex';
        $CharPrefixes->{$prefix}->{n}++;
        next;
      } elsif ($c =~ /\A:(jis|jis-[a-z]+-)([0-9]+)-([0-9]+)-([0-9]+)\z/) {
        my $prefix = $1;
        my $cc = $2*(94+(0xFC-0xEF)*2)*94 + ($3-1)*94 + ($4-1);
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        $CharPrefixes->{$prefix.$2}->{type} = 'kt';
        $CharPrefixes->{$prefix.$2}->{n}++;
        next;
      } elsif ($c =~ /\A:(cns|cns-[a-z]+-|gb|ks|kps|cccii)([0-9]+)-([1-9][0-9]*)-([1-9][0-9]*)\z/) {
        my $prefix = $1;
        my $cc = $2*(94)*94 + ($3-1)*94 + ($4-1);
        $TableData->{$level->{key}}->{$prefix}->{$cc} = [$cid, $c];
        $CharPrefixes->{$prefix.$2}->{type} = 'kt';
        $CharPrefixes->{$prefix.$2}->{n}++;
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
    } elsif ($key =~ /^([A-Z]+):(MJ|jis|jis-[a-z]+-|cns|cns-[a-z]+-|gb|ks|kps|aj|ac|ag|ak|aj2-|ak1-|UK-|u-[a-z]+-|b5-|b5-[a-z]+-|cccii|koseki|swc)$/) {
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

my $RelTypeToIndex = {};
$TableMeta->{rels} = [];
{
  my $rel_types = {};
  my $rel_type_sets = {};
  for my $c1 (sort { $a cmp $b } keys %$Rels) {
    for my $c2 (sort { $a cmp $b } keys %{$Rels->{$c1}}) {
      my $v = $Rels->{$c1}->{$c2};
      my @v = sort { $a cmp $b } grep { not /^_/ } keys %$v;
      for my $key (@v) {
        $rel_types->{$key}++;
      }
      $rel_type_sets->{join $;, @v}++;
    }
  }
  for my $rel_type_set (sort {
    $rel_type_sets->{$b} <=> $rel_type_sets->{$a}
  } grep {
    $rel_type_sets->{$_} > 100;
  } keys %$rel_type_sets) {
    my $types = [split /\Q$;\E/, $rel_type_set];
    next unless @$types > 1;
    $RelTypeToIndex->{$rel_type_set} = @{$TableMeta->{rels}};
    push @{$TableMeta->{rels}}, {
      rel_types => $types,
      n => $rel_type_sets->{$rel_type_set},
    };
  }
  for my $rel_type (sort { $rel_types->{$b} <=> $rel_types->{$a} } keys %$rel_types) {
    $RelTypeToIndex->{$rel_type} = @{$TableMeta->{rels}};
    push @{$TableMeta->{rels}}, {
      key => $rel_type,
      weight => ($Merged->{rel_types}->{$rel_type}->{weight} // die $rel_type),
      mergeable_weight => ($Merged->{rel_types}->{$rel_type}->{mergeable_weight} // die $rel_type),
      n => $rel_types->{$rel_type},
    };
  }
  for (@{$TableMeta->{rels}}) {
    if (defined $_->{rel_types}) {
      $_->{rels} = [map {
        $RelTypeToIndex->{$_} // die $_;
      } @{delete $_->{rel_types}}];
    }
  }
  die if @{$TableMeta->{rels}} > 2**12;
}
{
  #die 0+keys %$CharPrefixes if 0x4F < keys %$CharPrefixes;
  $TableMeta->{echars} = [];
  my $PrefixToEChar = {};
  my $bytes = [
    0x02 .. 0x1F, 0x7F .. 0xC1, 0xF5 .. 0xFF,
  ];
  for my $prefix (sort {
    $CharPrefixes->{$b}->{n} <=> $CharPrefixes->{$a}->{n};
  } keys %$CharPrefixes) {
    my $byte = (shift @$bytes) or last;
    $PrefixToEChar->{$prefix} = [
      $byte,
      $CharPrefixes->{$prefix}->{type},
    ];
    push @{$TableMeta->{echars}}, {
      byte => $byte,
      prefix => $prefix,
      type => $CharPrefixes->{$prefix}->{type},
      n => $CharPrefixes->{$prefix}->{n},
    };
  }

  sub _eint ($) {
    my $v = shift;
    my $r = '';
    {
      my $x = $v & 0b00111111;
      $v = $v >> 6;
      if ($v) {
        $r .= pack 'C', 0b11000000 | $x;
        redo;
      } else {
        $r .= pack 'C', 0b10000000 | $x;
      }
    }
    return $r;
  } # _eint

  sub encode_char ($) {
    my $c = $_[0];
    if ($c =~ /\A:([0-9A-Za-z_-]+[A-Za-z_-])([0-9]+)\z/) {
      my $ec = $PrefixToEChar->{$1};
      my $v = $2;
      if ($ec) {
        if ($ec->[1] eq 'dec') {
          return pack ('C', $ec->[0]) . _eint $v;
        } else {
          #die "$c $ec->[1]";
        }
      }
    }
    if ($c =~ /\A:([0-9A-Za-z_-]+-)([0-9a-f]{1,8})\z/) {
      my $ec = $PrefixToEChar->{$1};
      my $v = hex $2;
      if ($ec) {
        if ($ec->[1] eq 'hex') {
          return pack ('C', $ec->[0]) . _eint $v;
        } else {
          #die "$c $ec->[1]";
        }
      }
    }
    if ($c =~ /\A:([A-Za-z0-9_-]+)-([1-9][0-9]*)-([1-9]|[1-8][0-9]|9[0-4])\z/) {
      my $ec = $PrefixToEChar->{$1};
      my $v = ($2-1)*94 + ($3-1);
      if ($ec) {
        if ($ec->[1] eq 'kt') {
          return pack ('C', $ec->[0]) . _eint $v;
        } else {
          #die "$c $ec->[1]";
        }
      }
    }
    if ($c =~ /\A(.)\z/) {
      my $ec = $PrefixToEChar->{int ((ord $1) / 0x1000)};
      if ($ec) {
        if ($ec->[1] eq 'urow') {
          return pack ('C', $ec->[0]) . _eint ((ord $1) % 0x1000);
        }
      }
    }
    if ($c =~ /\A(.)(.)\z/) {
      my $ec = $PrefixToEChar->{ord $2};
      if ($ec) {
        my $v = ord $1;
        if ($ec->[1] eq 'suffix') {
          return pack ('C', $ec->[0]) . _eint $v;
        }
      }
    }
    return encode_web_utf8 ($c) . "\x01";
  } # encode_char
}
{
  my $path = $DataPath->child ('tbl-rels.dat');
  my $file = $path->openw;

  ## file: \x00 {item} \x00 {item} \x00 ... \x00 {item} \x00
  ## item: {char} {triple}+
  ## triple: {char} {rel}+
  ## char: {textchar} | {bytechar}
  ## textchar: {utf8char}+ \x01
  ## bytechar: {\x80-\xBF} {^\x00}+
  ## rel: {^\x00}+
  print $file "\x00";
  my $rel_keys = {};
  for my $c1 (sort { $a cmp $b } keys %$Rels) {
    print $file encode_char $c1;
    my $has_prev;
    for my $c2 (sort { $a cmp $b } keys %{$Rels->{$c1}}) {
      print $file "\x01" if $has_prev;
      my $v = $Rels->{$c1}->{$c2};
      print $file encode_char $c2;
      my @v = sort { $a cmp $b } grep { not /^_/ } keys %$v;
      my $rel_type_set = join $;, @v;
      if (defined $RelTypeToIndex->{$rel_type_set}) {
        print $file _eint $RelTypeToIndex->{$rel_type_set};
      } else {
        for my $key (@v) {
          my $x = $RelTypeToIndex->{$key};
          print $file _eint $x;
        }
      }
      $has_prev = 1;
    }
    print $file "\x00";
  }
}

{
  my $i = 0;
  my $path = $DataPath->child ("char-leaders.jsonl");
  my $out_path = $DataPath->child ("tbl-leaders.dat");
  my $file = $path->openr;
  my $wfile = $out_path->openw;
  local $/ = "\x0A";
  my $prev_v = "\x00";
  while (<$file>) {
    $i++;
    printf STDERR "\rLeaders %d... ", $i if ($i % 10000) == 0;
    my $json = json_bytes2perl $_;
    my $c1 = $json->[0];
    my $n = "\x00" . encode_char $c1;

    pop @{$json->[1]} if @{$json->[1]} and not defined $json->[1]->[-1];
    my $v = '';
    for (@{$json->[1]}) {
      $v .= defined $_ ? encode_char ($_) : "\x01";
    }

    unless ($prev_v eq $v) {
      print $wfile $prev_v;
      $prev_v = $v;
    }
    print $wfile $n;
  }
  print $wfile "\x00\x00";
  print $wfile $prev_v;
  print $wfile "\x00";
}

$TableMeta->{leader_types} = [];
for (values %{$Merged->{leader_types}}) {
  $TableMeta->{leader_types}->[$_->{index}] = $_;
}

{
  my $path = $DataPath->child ('tbl-index.json');
  $path->spew (perl2json_bytes_for_record $TableMeta);
}

printf STDERR "\rDone (%s s) \n", time - $StartTime;
