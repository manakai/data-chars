use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $DataPath = path (".");
my $TablePath = $DataPath;

my $Data;
{
  my $path = $DataPath->child ('cluster-root.json');
  $Data = json_bytes2perl $path->slurp;
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
    for my $level (0..$#{$json->[1]}) {
      my $level_def = $Data->{cluster_levels}->[$#{$Data->{cluster_levels}} - $level];
      next unless {
        EQUIV => 1,
        #OVERLAP => 1,
        #LINKED => 1,
      }->{$level_def->{key}};
      my $index = $json->[1]->[$level] + 1;
      if (1 == length $c) {
        my $cc = ord $c;
        if ($cc >= 0x20000) {
          $Tables->{$level_def->{key} . ':unicode-' . 0x20000}->[$cc - 0x20000] = $index;
          next;
        } elsif ($cc >= 0xA000) {
          #
        } elsif ($cc >= 0x3400) {
          $Tables->{$level_def->{key} . ':unicode-' . 0x3400}->[$cc - 0x3400] = $index;
          next;
        } else {
          #
        }
      } elsif ($c =~ /\A(.)(\p{Variation_Selector})\z/s) {
        my $cc1 = ord $1;
        my $cc2 = ord $2;
        $Tables->{$level_def->{key} . ':unicode-suffix-' . $cc2}->[$cc1] = $index;
        next;
      }

      $Others->{$level_def->{key}}->{$c} = $index;
    } # $level
  }
}

my $Rels = {};
while (glob $DataPath->child ('merged-rels-*.jsonl')) {
  my $path = path ($_);
  print STDERR "\r$path...";
  my $file = $path->openr;
  local $/ = "\x0A\x0A";
  while (<$file>) {
    my $c1 = json_bytes2perl $_;
    my $c1v = json_bytes2perl scalar <$file>;
    $Rels->{$c1} = $c1v;
  }
}

my $TableMeta = {others => $Others};
$TablePath->mkpath;
{
  my $path = $TablePath->child ('tbl-clusters.dat');
  my $file = $path->openw;
  my $index = 0;
  for my $key (sort { $a cmp $b } keys %$Tables) {
    my $def = {offset => $index};
    if ($key =~ /^([A-Z]+):unicode-([0-9]+)$/) {
      $def->{level_key} = $1;
      $def->{type} = 'unicode';
      $def->{unicode_offset} = 0+$2;
    } elsif ($key =~ /^([A-Z]+):unicode-suffix-([0-9]+)$/) {
      $def->{level_key} = $1;
      $def->{type} = 'unicode-suffix';
      $def->{suffix} = 0+$2;
      $def->{unicode_offset} = 0;
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
    $def->{unicode_offset} += $skip;
    for (@{$Tables->{$key}}) {
      print $file substr ((pack 'L>', $_ // 0), 1);
      $index += 3;
    }
    $def->{offset_next} = $index;
    $def->{unicode_offset_next} = $def->{unicode_offset} + @{$Tables->{$key}};
    push @{$TableMeta->{tables} ||= []}, $def;
  }
}

{
  my $path = $TablePath->child ('tbl-rels.dat');
  my $file = $path->openw;

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
  my $path = $TablePath->child ('tbl-root.json');
  $path->spew (perl2json_bytes_for_record $TableMeta);
}

printf STDERR "\rdone \n";
