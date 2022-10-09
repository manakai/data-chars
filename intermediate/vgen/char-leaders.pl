use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;

my $Merged;
{
  my $path = $DataPath->child ('merged-misc.json');
  $Merged = json_bytes2perl $path->slurp;
}

my $ClusterRoot;
{
  my $path = $DataPath->child ('cluster-root.json');
  $ClusterRoot = json_bytes2perl $path->slurp;
}
my $Levels = $Merged->{cluster_levels};
my $LevelIndex = @$Levels - [grep { $_->{key} eq 'EQUIV' } @{$ClusterRoot->{cluster_levels}}]->[0]->{index};
my $LeaderTypes = [sort { $a->{index} <=> $b->{index} } values %{$ClusterRoot->{leader_types}}];

sub get_leader ($) {
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
} # get_leader

sub get_cluster_leaders ($) {
  my $chars = shift;
  my $props = {};

  for my $set_key (@{$Merged->{inset_keys}}) {
    for my $c (@$chars) {
      if ($Merged->{sets}->{$set_key}->{$c}) {
        $props->{stems}->{$set_key}->{$c} = 1;
        $props->{stems}->{all}->{$c} = 1;
      }
    }
  }

  $props->{leaders}->{all} =
      get_leader [grep { $props->{stems}->{all}->{$_} } @$chars]
   // get_leader $chars;

  for (qw(cn hk tw)) {
    $props->{leaders}->{$_} = get_leader [keys %{$props->{stems}->{$_}}]; # or undef
  }

  $props->{leaders}->{cn_complex} =
      get_leader [grep { $Merged->{sets}->{gb12345}->{$_} } keys %{$props->{stems}->{cn}}]
   // get_leader [grep { $Merged->{sets}->{gb12345}->{$_} } @$chars];
  $props->{leaders}->{kr} =
      get_leader [grep { $Merged->{sets}->{kr}->{$_} } @$chars]
   // get_leader [grep { $Merged->{sets}->{krname}->{$_} and $Merged->{sets}->{k0}->{$_} } @$chars]
   // get_leader [grep { $Merged->{sets}->{krname}->{$_} } @$chars]
   // get_leader [grep { $Merged->{sets}->{k0}->{$_} } @$chars];
  
  $props->{leaders}->{jp_h22} =
      get_leader [keys %{$props->{stems}->{jp}}]
   // get_leader [grep {
        if ($Merged->{sets}->{jp_jinmei}->{$_}) {
          $_ =~ /^(.)/ and $props->{stems}->{jp2}->{$1};
        } else {
          0;
        }
      } @$chars]
   // get_leader [grep { $Merged->{sets}->{jp_jinmei}->{$_} } @$chars]
   // get_leader [keys %{$props->{stems}->{jp2}}];
  if (defined $props->{leaders}->{jp_h22}) {
    $props->{leaders}->{jp} = $props->{leaders}->{jp_h22};
    $props->{leaders}->{jp} =~ s/\p{Variation_Selector}//;
    if (not grep { $_ eq $props->{leaders}->{jp} } @$chars) {
      $props->{leaders}->{jp} = $props->{leaders}->{jp_h22};
    }
  }

  $props->{leaders}->{jp_old} =
      get_leader [grep { $Merged->{sets}->{'to:cjkvi:jp-old-style:compatibility'}->{$_} } @$chars]
   // get_leader [grep { $Merged->{sets}->{'to:cjkvi:jp-old-style'}->{$_} } @$chars]
   // $props->{leaders}->{jp};
  
  $props->{leaders}->{jp_new} =
      get_leader [grep { $Merged->{sets}->{'to:manakai:variant:jpnewstyle'}->{$_} } @$chars]
   // get_leader [grep { $Merged->{sets}->{'from:cjkvi:jp-old-style'}->{$_} } @$chars]
   // $props->{leaders}->{jp};
  
  for (keys %{$props->{leaders}}) {
    delete $props->{leaders}->{$_} if not defined $props->{leaders}->{$_};
  }
  for (keys %{$props->{stems}}) {
    delete $props->{stems}->{$_} if not keys %{$props->{stems}->{$_}};
  }
  
  return $props->{leaders};
} # get_cluster_leaders

my $Data = {};
{
  my $path = $DataPath->child ("clusters-0.jsonl");
  print STDERR "\r|$path|... ";
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

printf STDERR "Done (%s) \n", time - $StartTime;

## License: Public Domain.
