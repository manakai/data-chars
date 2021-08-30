use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $StartTime = time;

sub merge ($$$) {
  my ($map, $c_from, $c_to) = @_;
  my $sc_from = $map->{$c_from};
  my $sc_to = $map->{$c_to};
  if ((keys %$sc_from) > (keys %$sc_to)) {
    ($sc_from, $sc_to) = ($sc_to, $sc_from);
  }
  for (keys %{$sc_from->{chars}}) {
    $sc_to->{chars}->{$_} = 1;
    $map->{$_} = $sc_to;
  }
  if (defined $sc_from->{clusters}) {
    push @{$sc_to->{clusters}}, @{$sc_from->{clusters}};
  }
  if (defined $sc_from->{rels}) {
    push @{$sc_to->{rels}}, @{$sc_from->{rels}};
  }
} # merge

my $Data = {};
my $DataChars = [];
my $DataRels = [];

my $Merged;
{
  my $path = $ThisPath->child ('merged-misc.json');
  $Merged = json_bytes2perl $path->slurp;
}
my $Rels = {};
{
  my $i = 1;
  {
    my $path = $ThisPath->child ("merged-rels-$i.jsonl");
    last unless $path->is_file;
    print STDERR "\r$path...";
    my $file = $path->openr;
    local $/ = "\x0A\x0A";
    while (<$file>) {
      my $c1 = json_bytes2perl $_;
      my $c1v = json_bytes2perl scalar <$file>;
      $Rels->{$c1} = $c1v;
    }
    $i++;
    redo;
  }
}

$Data->{cluster_levels} = $Merged->{cluster_levels};
my $Levels = json_chars2perl perl2json_chars $Merged->{cluster_levels};
$Levels->[0]->{leaf} = 1;
for (@$Levels) {
  $_->{unmergeable} = $_->{min_weight} <= $Merged->{min_unmergeable_weight} ? sub { 0 } : \&unmergeable;
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
      my $set = $Merged->{sets}->{$set_key};
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
            return 1;
          }
        }
      }
    }
    return 0;
  } # unmergeable
}

sub construct_clusters ($$$) {
  my ($clusters, $min_weight, $unmergeable) = @_;

  my $map = {};
  my $chars = {};
  for my $cluster (@$clusters) {
    my $x = {clusters => [$cluster], rels => []};
    for my $c (keys %{$cluster->{chars}}) {
      $map->{$c} = $x;
      $x->{chars}->{$c} = 1;
      $chars->{$c} = 1;
    }
  }

  my $rels = [];
  for my $c1 (sort { $a cmp $b } keys %$chars) {
    for my $c2 (sort { $a cmp $b } grep { $chars->{$_} } keys %{$Rels->{$c1}}) {
      #if (not defined $Rels->{$c1}->{$c2}->{_}) {
      #  die perl2json_bytes [$c1, $c2, $Rels->{$c1}->{$c2}];
      #}
      if ($Rels->{$c1}->{$c2}->{_} >= $min_weight) {
        if ($map->{$c1} eq $map->{$c2}) { # internal
          #
        } else {
          push @$rels, [$c1, $c2,
                        $Rels->{$c1}->{$c2}->{_},
                        $Rels->{$c1}->{$c2}->{_u},
                        [sort { $a cmp $b } grep { $_ !~ /^_/ } keys %{$Rels->{$c1}->{$c2}}]];
        }
      }
    }
  }
  $Data->{stats}->{construct}->{$min_weight}->{rels} = 0+@$rels;

  for my $rel (sort { $b->[2] <=> $a->[2] } @$rels) {
    if ($map->{$rel->[0]} eq $map->{$rel->[1]}) { # already merged
      $Data->{stats}->{construct}->{$min_weight}->{already}++;
      push @{$map->{$rel->[1]}->{rels}}, $rel;
    } elsif ($unmergeable->($map->{$rel->[0]}, $map->{$rel->[1]}, $min_weight)) {
      #
    } else {
      $Data->{stats}->{construct}->{$min_weight}->{merge}++;
      merge $map, $rel->[0] => $rel->[1];
      push @{$map->{$rel->[1]}->{rels}}, $rel;
    }
  } # $rel
  $Data->{stats}->{construct}->{$min_weight}->{check_unmergeable}
      = $Data->{stats}->{construct}->{$min_weight}->{rels}
      - $Data->{stats}->{construct}->{$min_weight}->{already};
  
  my $found = {};
  my $result = [map { $map->{$_} }
                grep { not $found->{$map->{$_}}++ }
                sort { $a cmp $b }
                keys %$map];

  $Data->{stats}->{construct}->{$min_weight}->{input} = 0+@$clusters;
  $Data->{stats}->{construct}->{$min_weight}->{output} = 0+@$result;

  return $result;
} # construct_clusters

sub sort_clusters ($) {
  return [map { $_->[0] } sort { $a->[1] cmp $b->[1] } map {
    [$_, [sort { $a cmp $b } keys %{$_->{chars}}]->[0]],
  } @{$_[0]}];
} # sort_clusters

sub set_cluster_props ($) {
  my $cluster = shift;

  if (defined $cluster->{clusters}) {
    $cluster->{clusters} = sort_clusters $cluster->{clusters};
    $cluster->{cluster_indexes} = [map { $_->{index} } @{$cluster->{clusters}}];
  }

  $cluster->{index} = @$DataChars;
  $cluster->{rel_count} = 0+@{$cluster->{rels}};
  push @$DataChars, $cluster;
  push @$DataRels, delete $cluster->{rels};
} # set_cluster_props

my $clusters = [map {
  {chars => {$_ => 1}};
} keys %{$Merged->{chars}}];
for my $level (@$Levels) {
  print STDERR "\r$level->{label}...";
  $clusters = construct_clusters $clusters, $level->{min_weight}, $level->{unmergeable};
  if ($level->{leaf}) {
    delete $_->{clusters} for @$clusters;
  }
  set_cluster_props $_ for @$clusters;
}
$clusters = [grep { 1 < keys %{$_->{chars}} } @$clusters];
$clusters = sort_clusters $clusters;

$Data->{clusters} = $clusters;
$Data->{cluster_indexes} = [map { $_->{index} } @{$Data->{clusters}}];

my $count; $count = sub ($) {
  my $list = shift;
  my $n = 0;
  my $new_list = [];
  for (@$list) {
    $n += @{$_->{clusters} or []};
    push @$new_list, @{$_->{clusters} or []};
    delete $_->{clusters};
  }
  if ($n) {
    unshift @{$Data->{stats}->{clusters}}, $n;
    $count->($new_list);
  } else {
    my $n = 0;
    for (@$list) {
      $n += keys %{$_->{chars}};
    }
    unshift @{$Data->{stats}->{clusters}}, $n;
  }
}; # $count
$count->([$Data]);

{
  my $path = $ThisPath->child ('cluster-root.json');
  print STDERR "\rWrite |$path|...";
  $path->spew (perl2json_bytes_for_record $Data);
}
{
  my $i = 0;
  my $n = 0;
  my $file;
  while (@$DataChars) {
    unless (defined $file) {
      $i++;
      my $path = $ThisPath->child ("cluster-chars-$i.txt");
      print STDERR "\rWrite |$path|...";
      $file = $path->openw;
    }

    while (@$DataChars) {
      my $v = shift @$DataChars;
      print $file perl2json_bytes_for_record $v; # has trailing \x0A
      print $file "\x0A";
      $n++;
      if ($n > 10_0000) {
        undef $file;
        $n = 0;
        last;
      }
    }
  }
}
{
  my $i = 0;
  my $n = 0;
  my $file;
  while (@$DataRels) {
    unless (defined $file) {
      $i++;
      my $path = $ThisPath->child ("cluster-rels-$i.jsonl");
      print STDERR "\rWrite |$path|...";
      $file = $path->openw;
    }

    while (@$DataRels) {
      my $v = shift @$DataRels;
      print $file perl2json_bytes $v;
      print $file "\x0A";
      $n++;
      if ($n > 10_0000) {
        undef $file;
        $n = 0;
        last;
      }
    }
  }
}
print STDERR "\n";

printf STDERR "Done (%d s)\n",
    time - $StartTime;

## License: Public Domain.
