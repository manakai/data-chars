use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;

sub merge ($$$$) {
  my ($child_cluster_to_this_cluster,
      $this_cluster_to_child_cluster_keys,
      $child_cluster_from, $child_cluster_to) = @_;
  my $this_cluster_from = $child_cluster_to_this_cluster->{$child_cluster_from};
  my $this_cluster_to = $child_cluster_to_this_cluster->{$child_cluster_to};
  if ((keys %{$this_cluster_from->{chars}}) > (keys %{$this_cluster_to->{chars}})) {
    ($this_cluster_from, $this_cluster_to) = ($this_cluster_to, $this_cluster_from);
    ($child_cluster_from, $child_cluster_to) = ($child_cluster_to, $child_cluster_from);
  }
  for (keys %{$this_cluster_from->{chars}}) {
    $this_cluster_to->{chars}->{$_} = 1;
  }
  if ($this_cluster_from->{sort_key} le $this_cluster_to->{sort_key}) {
    $this_cluster_to->{sort_key} = $this_cluster_from->{sort_key};
  }

  for (@{$this_cluster_to_child_cluster_keys->{$this_cluster_from}}) {
    $child_cluster_to_this_cluster->{$_} = $this_cluster_to;
  }
  push @{$this_cluster_to_child_cluster_keys->{$this_cluster_to}},
      @{delete $this_cluster_to_child_cluster_keys->{$this_cluster_from}};

  push @{$this_cluster_to->{child_rel_lists}},
      @{delete $this_cluster_from->{child_rel_lists}};
} # merge

my $Data = {};

my $Merged;
my $MergedChars;
my $MergedSets;
my $Rels = {};
{
  my $path = $DataPath->child ('merged-index.json');
  $Merged = json_bytes2perl $path->slurp;
}
{
  my $path = $DataPath->child ('merged-chars.json');
  $MergedChars = json_bytes2perl $path->slurp;
}
{
  my $path = $DataPath->child ('merged-sets.json');
  $MergedSets = json_bytes2perl $path->slurp;
}
{
  my $path = $DataPath->child ('merged-rels.jsonll');
  print STDERR "\rLoading |$path|... ";
  my $file = $path->openr;
  local $/ = "\x0A\x0A";
  while (<$file>) {
    my $c1 = json_bytes2perl $_;
    my $c1v = json_bytes2perl scalar <$file>;
    $Rels->{$c1} = $c1v;
  }
}

my $Levels = [];
{
  for my $level (values %{$Merged->{cluster_levels}}) {
    $Levels->[$level->{index}] = $level;
    $Levels->[$level->{index}]->{unmergeable} =
        $level->{min_weight} <= $Merged->{min_unmergeable_weight}
        ? sub { 0 } : \&unmergeable;
  } # $level
}

{
  my $unmergeable = {};
  
  sub unmergeable ($$$) {
    my ($cluster1, $cluster2, $weight) = @_;
    for my $cc1 (keys %{$cluster1->{chars}}) {
      for my $cc2 (keys %{$cluster2->{chars}}) {
        return 1 if $unmergeable->{$weight}->{$cc1, $cc2};

        if (defined $Rels->{$cc1}->{$cc2} and
            $Rels->{$cc1}->{$cc2}->{_u} < $weight) {
          $unmergeable->{$weight}->{$cc1, $cc2} = 1;
          $unmergeable->{$weight}->{$cc2, $cc1} = 1;
          return 1;
        }
        if (defined $Rels->{$cc2}->{$cc1} and
            $Rels->{$cc2}->{$cc1}->{_u} < $weight) {
          $unmergeable->{$weight}->{$cc1, $cc2} = 1;
          $unmergeable->{$weight}->{$cc2, $cc1} = 1;
          return 1;
        }
      }
    }
    return 0 if $weight <= $Merged->{inset_mergeable_weight};
    for my $set_key (@{$Merged->{inset_keys}}) {
      my $set = $MergedSets->{$set_key};
      for my $c1 (sort { $a cmp $b } keys %{$cluster1->{chars}}) {
        next unless $set->{$c1};
        for my $c2 (sort { $a cmp $b } keys %{$cluster2->{chars}}) {
          next unless $set->{$c2};
          if (defined $Rels->{$c1}->{$c2} and
              $Rels->{$c1}->{$c2}->{'manakai:inset:'.$set_key.':variant'}) {
            # mergeable variant
          } else { # unmergeable
            if (defined $Rels->{$c1}->{$c2}) {
              $Rels->{$c1}->{$c2}->{_u} = $Merged->{inset_mergeable_weight}
                  if $Rels->{$c1}->{$c2}->{_u} > $Merged->{inset_mergeable_weight};
            } else {
              $Rels->{$c1}->{$c2}->{_u} = $Merged->{inset_mergeable_weight};
              $Rels->{$c1}->{$c2}->{_} = $weight;
            }
            $Rels->{$c1}->{$c2}->{'manakai:inset'} //= -1;
            if (defined $Rels->{$c2}->{$c1}) {
              $Rels->{$c2}->{$c1}->{_u} = $Merged->{inset_mergeable_weight}
                  if $Rels->{$c2}->{$c1}->{_u} > $Merged->{inset_mergeable_weight};
            } else {
              $Rels->{$c2}->{$c1}->{_u} = $Merged->{inset_mergeable_weight};
              $Rels->{$c2}->{$c1}->{_} = $weight;
            }
            $Rels->{$c2}->{$c1}->{'manakai:inset'} //= -1;
            $Data->{inset_pairs}->{$c1}->{$c2} = 1;
            return 1;
          }
        }
      }
    }
    return 0;
  } # unmergeable
}

sub construct_clusters ($$$$) {
  my ($child_clusters, $child_cluster_to_rel, $min_weight, $unmergeable) = @_;

  my $child_cluster_to_this_cluster = {};
  my $this_cluster_to_child_cluster_keys = {};
  for my $child_cluster (@$child_clusters) {
    my $this_cluster = {#clusters => [$child_cluster],
                        child_rel_lists => []};
    $this_cluster->{chars} = {%{$child_cluster->{chars}}};
    $this_cluster->{sort_key} = $child_cluster->{sort_key};
    $child_cluster_to_this_cluster->{$child_cluster} = $this_cluster;
    $this_cluster_to_child_cluster_keys->{$this_cluster} = [''.$child_cluster];
  }

  my $rel_items = [];
  for my $child_cluster (@$child_clusters) {
    my $this_cluster = $child_cluster_to_this_cluster->{$child_cluster};
    my $other_rels = [];
    my $child_rels = $child_cluster_to_rel->{$child_cluster};
    for my $rel_item (@$child_rels) {
      if ($rel_item->[1] >= $min_weight) {
        push @$rel_items, [$child_cluster, $rel_item];
      } else {
        push @$other_rels, $rel_item;
      }
    }
    push @{$this_cluster->{child_rel_lists}}, $other_rels;
  } # $child_cluster

  for my $rel_item (sort { $b->[1]->[1] <=> $a->[1]->[1] } @$rel_items) {
    my $child_cluster_1 = $rel_item->[0];
    my $child_cluster_2 = $rel_item->[1]->[0];
    my $this_cluster_1 = $child_cluster_to_this_cluster->{$child_cluster_1};
    my $this_cluster_2 = $child_cluster_to_this_cluster->{$child_cluster_2};
    if ($this_cluster_1 eq $this_cluster_2) { # already merged
      #
    } elsif ($unmergeable->($this_cluster_1, $this_cluster_2, $min_weight)) {
      push @{$this_cluster_1->{child_rel_lists}}, [$rel_item->[1]];
    } else {
      merge
          $child_cluster_to_this_cluster, $this_cluster_to_child_cluster_keys,
          $child_cluster_1 => $child_cluster_2;
    }
  } # $rel
  
  # not sorted
  my $found = {};
  my $this_clusters = [grep { not $found->{$_}++ } values %$child_cluster_to_this_cluster];

  my $this_cluster_to_rel = {};
  for my $this_cluster (@$this_clusters) {
    my $child_rel_lists = delete $this_cluster->{child_rel_lists};
    my $new_rels = {};
    my $i = 0;
    for (@{$child_rel_lists}) {
      for (@$_) {
        my $this_cluster_2 = $child_cluster_to_this_cluster->{$_->[0]} // die;
        unless ($this_cluster eq $this_cluster_2) {
          if ($new_rels->{$this_cluster_2}) {
            $new_rels->{$this_cluster_2}->[1] = $_->[1]
                if $new_rels->{$this_cluster_2}->[1] < $_->[1];
          } else {
            $new_rels->{$this_cluster_2} = [$this_cluster_2, $_->[1], $i++];
          }
        }
      }
    }
    my $rels = $this_cluster_to_rel->{$this_cluster} = [];
    for (sort { $a->[2] <=> $b->[2] } values %$new_rels) {
      push @$rels, [$_->[0], $_->[1]];
    }
  }

  return {clusters => $this_clusters, cluster_to_rel => $this_cluster_to_rel};
} # construct_clusters

sub sort_clusters ($) {
  return [sort { $a->{sort_key} cmp $b->{sort_key} } @{$_[0]}];
} # sort_clusters

{
  my $path = $DataPath->child ('cluster-temp.jsonl');
  my $file = $path->openw;

  sub write_cluster ($$) {
    my ($level_index, $cluster) = @_;
    print $file perl2json_bytes [$level_index, [
      #sort { $a cmp $b }
      keys %{$cluster->{chars}}
    ]];
    print $file "\x0A";
  } # write_cluster
}

my $clusters = [];
my $cluster_to_rel = {};
{
  my $char_to_cluster = {};
  for my $c (sort { $a cmp $b } keys %$MergedChars) {
    my $cluster = {
      chars => {$c => 1},
      sort_key => $c,
    };
    $char_to_cluster->{$c} = $cluster;
    push @$clusters, $cluster;
  }
  undef $MergedChars;
  for my $c (keys %$char_to_cluster) {
    my $cluster = $char_to_cluster->{$c};
    my $rels = $cluster_to_rel->{$cluster} = [];
    for my $c2 (sort { $a cmp $b } keys %{$Rels->{$c}}) {
      push @$rels, [$char_to_cluster->{$c2} // die, $Rels->{$c}->{$c2}->{_}];
    }
  }
}
for my $level (@$Levels) {
  print STDERR qq{\rProcessing |$level->{key}|... };
  my $r = construct_clusters $clusters, $cluster_to_rel,
      $level->{min_weight}, $level->{unmergeable};
  $clusters = $r->{clusters};
  $cluster_to_rel = $r->{cluster_to_rel};
  $clusters = sort_clusters $clusters;
  my $level_index = $level->{index};
  for my $cluster (@$clusters) {
    write_cluster $level_index, $cluster;
  }
}

{
  my $path = $DataPath->child ('cluster-index.json');
  print STDERR "\rWriting[1/1] |$path|... ";
  $path->spew (perl2json_bytes_for_record $Data);
}

printf STDERR "\rDone (%d s) \n", time - $StartTime;

## License: Public Domain.
