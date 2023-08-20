use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;

my $Merged;
my $MergedSets;
{
  my $path = $DataPath->child ('merged-index.json');
  $Merged = json_bytes2perl $path->slurp;
}
{
  my $path = $DataPath->child ('merged-sets.json');
  $MergedSets = json_bytes2perl $path->slurp;
}
my $LevelIndex = $Merged->{cluster_levels}->{EQUIV}->{index} // die;
my $LeaderTypes = [sort { $a->{index} <=> $b->{index} } values %{$Merged->{leader_types}}];

my $GetLeader = {};
$GetLeader->{_default} = sub ($) {
  my $sorted = [map { $_->[0] } sort {
    $a->[1] <=> $b->[1] || # single char is preferred
    $a->[0] cmp $b->[0]; # string order
  } map {
    my $x = [$_, length $_];
    $x;
  } @{$_[0]}];
  return $sorted->[0]; # or undef
}; # _default
$GetLeader->{kanas} = sub ($) {
  my $sorted = [map { $_->[0] } sort {
    $a->[3] <=> $b->[3] ||
    $a->[1] <=> $b->[1] || # single char is preferred
    $a->[0] cmp $b->[0]; # string order
  } map {
    my $x = [$_, length $_, ord $_];
    $x->[3] = $x->[1] == 1 ?
                ($x->[2] <  0x3000 ? 6 :
                 $x->[2] <  0x3040 ? 3 : # cjk
                 $x->[2] <  0x3400 ? 1 : # kana
                 $x->[2] <  0xFFFF ? 4 : # han
                 $x->[2] < 0x1FFFF ? 2 : # kana
                                     5): # han
              ($x->[0] =~ /^:u-jitaichou/ ? 7 :
               $x->[0] =~ /^:u-rcv/ ? 7 :
                                     9);
    $x;
  } @{$_[0]}];
  return $sorted->[0]; # or undef
}; # _default
$GetLeader->{hans} = sub ($) {
  my $sorted = [map { $_->[0] } sort {
    $a->[1] <=> $b->[1] || # VS-less char is preferred
    $a->[3] <=> $b->[3] || # URO is preferred to Ext.A
    $a->[2] <=> $b->[2] || # code point order of first char
    $a->[0] cmp $b->[0]; # string order
  } map {
    my $x = [$_, length $_, ord $_];
    $x->[3] = $x->[2] < 0x3400 ? 4 :
              $x->[2] < 0x4E00 ? 2 :
              $x->[2] < 0xFFFF ? 1 :
                                 3 ;
    $x;
  } @{$_[0]}];
  return $sorted->[0]; # or undef
}; # hans

sub get_leader ($);
*get_leader = $GetLeader->{$Merged->{key}} || $GetLeader->{_default};

sub get_cluster_leaders ($) {
  my $chars = shift;
  my $props = {};

  if ($Merged->{key} eq 'hans') {

  for my $set_key (@{$Merged->{inset_keys}}) {
    for my $c (@$chars) {
      if ($MergedSets->{$set_key}->{$c}) {
        $props->{stems}->{$set_key}->{$c} = 1;
        $props->{stems}->{all}->{$c} = 1;
      }
    }
  }

  $props->{leaders}->{all} =
      get_leader [grep { $props->{stems}->{all}->{$_} } @$chars]
   // get_leader $chars;

  for (qw(cn hk tw vi)) {
    $props->{leaders}->{$_} = get_leader [keys %{$props->{stems}->{$_}}]; # or undef
  }

  $props->{leaders}->{cn_complex} =
      get_leader [grep { $MergedSets->{gb12345}->{$_} } keys %{$props->{stems}->{cn}}]
   // get_leader [grep { $MergedSets->{gb12345}->{$_} } @$chars];
  $props->{leaders}->{kr} =
      get_leader [grep { $MergedSets->{kr}->{$_} } @$chars]
   // get_leader [grep { $MergedSets->{krname}->{$_} and $Merged->{sets}->{k0}->{$_} } @$chars]
   // get_leader [grep { $MergedSets->{krname}->{$_} } @$chars]
   // get_leader [grep { $MergedSets->{k0}->{$_} } @$chars];
  
  $props->{leaders}->{jp_h22} =
      get_leader [keys %{$props->{stems}->{jp}}]
   // get_leader [grep {
        if ($MergedSets->{jp_jinmei}->{$_}) {
          $_ =~ /^(.)/ and $props->{stems}->{jp2}->{$1};
        } else {
          0;
        }
      } @$chars]
   // get_leader [grep { $MergedSets->{jp_jinmei}->{$_} } @$chars]
   // get_leader [keys %{$props->{stems}->{jp2}}];
  if (defined $props->{leaders}->{jp_h22}) {
    $props->{leaders}->{jp} = $props->{leaders}->{jp_h22};
    $props->{leaders}->{jp} =~ s/\p{Variation_Selector}//;
    if (not grep { $_ eq $props->{leaders}->{jp} } @$chars) {
      $props->{leaders}->{jp} = $props->{leaders}->{jp_h22};
    }
  }

  $props->{leaders}->{jp_old} =
      get_leader [grep { $MergedSets->{'to:cjkvi:jp-old-style:compatibility'}->{$_} } @$chars]
   // get_leader [grep { $MergedSets->{'to:cjkvi:jp-old-style'}->{$_} } @$chars]
   // $props->{leaders}->{jp};
  
  $props->{leaders}->{jp_new} =
      get_leader [grep { $MergedSets->{'to:manakai:variant:jpnewstyle'}->{$_} } @$chars]
   // get_leader [grep { $MergedSets->{'from:cjkvi:jp-old-style'}->{$_} } @$chars]
   // $props->{leaders}->{jp};

  $props->{leaders}->{inherited} =
      get_leader [grep { $MergedSets->{inherited1}->{$_} } @$chars]
   // get_leader [grep { $MergedSets->{inherited2}->{$_} } @$chars]
   // get_leader [grep { $MergedSets->{inherited3}->{$_} } @$chars];
  
  for (keys %{$props->{leaders}}) {
    delete $props->{leaders}->{$_} if not defined $props->{leaders}->{$_};
  }
  for (keys %{$props->{stems}}) {
    delete $props->{stems}->{$_} if not keys %{$props->{stems}->{$_}};
  }

  } else {
    $props->{leaders}->{all} = get_leader $chars;
  }
  
  return $props->{leaders};
} # get_cluster_leaders

my $Data = {};
{
  my $path = $DataPath->child ("cluster-temp.jsonl");
  print STDERR "\rLoading |$path|... ";
  my $file = $path->openr;
  local $/ = "\x0A";
  while (<$file>) {
    my $v = json_bytes2perl $_; # level index, [char]
    next unless $v->[0] == $LevelIndex;

    my $leaders = get_cluster_leaders $v->[1];
    my $vv = [$leaders->{all}];
    for my $lt (@$LeaderTypes) {
      push @$vv, $leaders->{$lt->{key}}; # or undef
    }

    for my $c (@{$v->[1]}) {
      next if ($c eq $vv->[0] and 1 == grep { defined $_ } @$vv);

      print perl2json_bytes [$c, $vv];
      print "\x0A";
    }
  }
}

printf STDERR "\rDone (%s s) \n", time - $StartTime;

## License: Public Domain.
