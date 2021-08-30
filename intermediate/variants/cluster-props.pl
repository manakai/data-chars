use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;

my $Merged;
{
  my $path = $ThisPath->child ('merged-misc.json');
  $Merged = json_bytes2perl $path->slurp;
}

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
  } keys %{$_[0]}];
  return $sorted->[0]; # or undef
} # get_leader

sub get_cluster_props ($) {
  my $cluster = shift;
  my $props = {};

  for my $set_key (@{$Merged->{inset_keys}}) {
    for my $c (keys %{$cluster->{chars}}) {
      if ($Merged->{sets}->{$set_key}->{$c}) {
        $props->{stems}->{$set_key}->{$c} = 1;
        $props->{stems}->{all}->{$c} = 1;
      }
    }
  }

  $props->{leaders}->{all} = get_leader {map { $_ => 1 } grep { $props->{stems}->{all}->{$_} } keys %{$cluster->{chars}}} // get_leader $cluster->{chars};

  for (qw(cn hk tw)) {
    $props->{leaders}->{$_} = get_leader $props->{stems}->{$_}; # or undef
  }

  $props->{leaders}->{cn_complex} = get_leader {map { $_ => 1 } grep { $Merged->{sets}->{gb12345}->{$_} } keys %{$props->{stems}->{cn}}}
      // get_leader {map { $_ => 1 } grep { $Merged->{sets}->{gb12345}->{$_} } keys %{$cluster->{chars}}};
  $props->{leaders}->{kr} = get_leader {map { $_ => 1 } grep { $Merged->{sets}->{kr}->{$_} } keys %{$cluster->{chars}}}
      // get_leader {map { $_ => 1 } grep { $Merged->{sets}->{krname}->{$_} and $Merged->{sets}->{k0}->{$_} } keys %{$cluster->{chars}}}
      // get_leader {map { $_ => 1 } grep { $Merged->{sets}->{krname}->{$_} } keys %{$cluster->{chars}}}
      // get_leader {map { $_ => 1 } grep { $Merged->{sets}->{k0}->{$_} } keys %{$cluster->{chars}}};
  
  $props->{leaders}->{jp_h22} = get_leader $props->{stems}->{jp}
      // get_leader {map { $_ => 1 } grep {
        if ($Merged->{sets}->{jp_jinmei}->{$_}) {
          $_ =~ /^(.)/ and $props->{stems}->{jp2}->{$1};
        } else {
          0;
        }
      } keys %{$cluster->{chars}}}
      // get_leader {map { $_ => 1 } grep { $Merged->{sets}->{jp_jinmei}->{$_} } keys %{$cluster->{chars}}}
      // get_leader $props->{stems}->{jp2};
  if (defined $props->{leaders}->{jp_h22}) {
    $props->{leaders}->{jp} = $props->{leaders}->{jp_h22};
    $props->{leaders}->{jp} =~ s/\p{Variation_Selector}//;
    if (not $cluster->{chars}->{$props->{leaders}->{jp}}) {
      $props->{leaders}->{jp} = $props->{leaders}->{jp_h22};
    }
  }

  $props->{leaders}->{jp_old} = get_leader {map { $_ => 1 } grep { $Merged->{sets}->{'to:cjkvi:jp-old-style:compatibility'}->{$_} } keys %{$cluster->{chars}}}
      // get_leader {map { $_ => 1 } grep { $Merged->{sets}->{'to:cjkvi:jp-old-style'}->{$_} } keys %{$cluster->{chars}}}
      // $props->{leaders}->{jp};
  
  $props->{leaders}->{jp_new} = get_leader {map { $_ => 1 } grep { $Merged->{sets}->{'to:manakai:variant:jpnewstyle'}->{$_} } keys %{$cluster->{chars}}}
      // get_leader {map { $_ => 1 } grep { $Merged->{sets}->{'from:cjkvi:jp-old-style'}->{$_} } keys %{$cluster->{chars}}}
      // $props->{leaders}->{jp};
  
  for (keys %{$props->{leaders}}) {
    delete $props->{leaders}->{$_} if not defined $props->{leaders}->{$_};
  }
  for (keys %{$props->{stems}}) {
    delete $props->{stems}->{$_} if not keys %{$props->{stems}->{$_}};
  }
  
  return $props;
} # get_cluster_props

for (sort { $a cmp $b } glob $ThisPath->child ("cluster-chars-*.txt")) {
  my $path = path ($_);
  my $dest = $_;
  $dest =~ s{cluster-chars-(\d+)\.txt}{cluster-props-$1.txt} or die $dest;
  my $new_path = path ($dest);
  print STDERR "\r$path...";
  my $file = $path->openr;
  my $new_file = $new_path->openw;
  local $/ = "\x0A\x0A";
  while (<$file>) {
    my $cluster = json_bytes2perl $_;
    my $props = get_cluster_props $cluster;
    print $new_file perl2json_bytes_for_record $props; # trailing \x0A
    print $new_file "\x0A";
  }
}
print STDERR "\n";

## License: Public Domain.
