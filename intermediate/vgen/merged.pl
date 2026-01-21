use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.'); # local/generated/charrels/.../
our $RootPath = $DataPath->parent->parent->parent->parent;
my $StartTime = time;

my $Input;
{
  my $path = $DataPath->child ('input.json');
  $Input = json_bytes2perl $path->slurp;
}

our $Data = {};
our $TypeWeight = {};
our $TypeMergeableWeight = {};
our $ImpliedTypes = {};
our $PairedTypes = [];
our $NTypes = [];
our $DefaultTypeMergeableWeight;
our $SetsToRelTypes = [];
our $SetsFromRelTypes = [];

$Data->{key} = $Input->{key};

do $DataPath->child ('weights.pl')->absolute or die $!;


my $Sets = {};
my $Rels = {};
my $HasRels = {};
my $HasRelTos = {};
my $RevRels = [];
for (
  map {
    [$_->{path}, $_->{rels_key} || '(none)',
     $_->{set_map} || {}, $_->{mv_map} || {}],
  } @{$Input->{inputs}},
) {
  my ($x, $rels_key, $setmap, $mvmap) = @$_;
  my $path = $DataPath->child ($x);
  print STDERR "\rLoading |$path|... ";
  my $json = {};
  if ($path =~ /\.json$/) {
    $json = json_bytes2perl $path->slurp;
  } else {
    parse_rel_data_file $path->openr => $json;
  }
  my $NewRels = [];
  for my $c1 (keys %{$json->{$rels_key}}) {
    for my $c2 (keys %{$json->{$rels_key}->{$c1}}) {
      next if $c1 eq $c2;
      my $has = 0;
      for my $rel (keys %{$json->{$rels_key}->{$c1}->{$c2}}) {
        my $w = $TypeWeight->{$rel} || 0;
        $Rels->{$c1}->{$c2}->{$rel} = $w;
        push @$RevRels, [$c1, $c2, $rel, $w];
        $HasRels->{$rel}->{$c1} = 1;
        $HasRelTos->{$rel}->{$c2} = 1;
        for my $rel2 (keys %{$ImpliedTypes->{$rel} or {}}) {
          push @$NewRels, [$c1, $c2, $rel2];
          $HasRels->{$rel2}->{$c1} = 1;
          $HasRelTos->{$rel2}->{$c2} = 1;
        }
        next if $w < 0;
        my $set_key = $mvmap->{$rel};
        if (defined $set_key) {
          $Rels->{$c1}->{$c2}->{'manakai:inset:'.$set_key.':variant'} = 1;
          $Rels->{$c2}->{$c1}->{'manakai:inset:'.$set_key.':variant'} = 1;
        }
        $has = 1;
      } # $rel
    }
  }
  for my $set_key (keys %$setmap) {
    for my $c (keys %{$json->{sets}->{$set_key}}) {
      $Sets->{$setmap->{$set_key}}->{$c} = 1;
    }
  }
  for (@$NewRels) {
    $Rels->{$_->[0]}->{$_->[1]}->{$_->[2]} = 1;
  }
}
for my $r (@$RevRels) {
  if (exists $Rels->{$r->[1]}->{$r->[0]}->{$r->[2]}) {
    #
  } else {
    $Rels->{$r->[1]}->{$r->[0]}->{'rev:'.$r->[2]} = $r->[3];
    $HasRels->{'rev:'.$r->[2]}->{$r->[1]} = 1;
  }
} # $RevRels
for my $vtype (@$NTypes, (map { @$_ } @$PairedTypes)) {
  for my $vtype ($vtype, 'rev:'.$vtype) {
    my $vt2 = $vtype;
    #$vt2 =~ s/\d+$//;
    C1: for my $c1 (sort { $a cmp $b } keys %{$HasRels->{$vtype}}) {
      my $n = 0;
      my $c;
      for my $c2 (sort { $a cmp $b } grep { $Rels->{$c1}->{$_}->{$vtype} } keys %{$Rels->{$c1}}) {
        next C1 if ++$n > 1;
        $c = $c2;
      }
      $Rels->{$c1}->{$c}->{'to1:'.$vt2} = 1;
    }
  } # C1
}
for my $vtype (@$NTypes) {
  my $vt2 = $vtype;
  #$vt2 =~ s/\d+$//;
  for my $c1 (sort { $a cmp $b } keys %{$HasRels->{$vtype}}) {
    for my $c2 (sort { $a cmp $b } keys %{$Rels->{$c1}}) {
      if ($Rels->{$c1}->{$c2}->{'to1:'.$vt2} and
          $Rels->{$c2}->{$c1}->{'to1:rev:'.$vt2}) {
        $Rels->{$c1}->{$c2}->{'1to1:'.$vt2} = 1;
        $Rels->{$c2}->{$c1}->{'1to1:'.$vt2} = 1;
      }
    }
  }
}
for (@$PairedTypes) {
  my ($vtype1, $vtype2) = @$_;
  for my $c1 (sort { $a cmp $b } keys %{$HasRels->{$vtype1}}) {
    for my $c2 (sort { $a cmp $b } keys %{$Rels->{$c1}}) {
      if ($Rels->{$c1}->{$c2}->{'to1:'.$vtype1} and
          $Rels->{$c2}->{$c1}->{'to1:'.$vtype2}) {
        $Rels->{$c1}->{$c2}->{'1to1:'.$vtype1} = 1;
        $Rels->{$c2}->{$c1}->{'1to1:'.$vtype1} = 1;
      } elsif ($Rels->{$c1}->{$c2}->{'to1:'.$vtype1}) {
        $Rels->{$c1}->{$c2}->{'nto1:'.$vtype1} = 1;
      }
    }
  }
}

{
  printf STDERR "\rRels (%d)...", 0+keys %$Rels;
  my $UnweightedTypes = {};
  for my $c1 (keys %$Rels) {
    for my $c2 (keys %{$Rels->{$c1}}) {
      my $types = $Rels->{$c1}->{$c2};
      die perl2json_bytes [$c1, $c2, $types] if $c1 eq $c2;
      my @remove = grep { ($TypeWeight->{$_} // die "Unweighted rel |$_|") == -2 } keys %$types;
      delete $types->{$_} for @remove;
      $types->{_} = [sort { $b <=> $a } map {
        $TypeWeight->{$_} || do {
          $UnweightedTypes->{$_} = 1;
          0;
        };
      } keys %$types]->[0];
      $types->{_u} = [sort { $a <=> $b } map {
        $TypeMergeableWeight->{$_} || $DefaultTypeMergeableWeight;
      } keys %$types]->[0];
    }
  }

  die "Unweighted: \n", join ("\n", sort { $a cmp $b } keys %$UnweightedTypes), "\n"
      if keys %$UnweightedTypes;
}

{
  for my $vtype (@$SetsToRelTypes) {
    for my $c1 (keys %{$HasRelTos->{$vtype}}) {
      $Sets->{"to:$vtype"}->{$c1} = 1;
    }
  }
  for my $vtype (@$SetsFromRelTypes) {
    for my $c1 (keys %{$HasRels->{$vtype}}) {
      $Sets->{"from:$vtype"}->{$c1} = 1;
    }
  }
}

for (keys %$TypeWeight) {
  $Data->{rel_types}->{$_}->{weight} = $TypeWeight->{$_};
  $Data->{rel_types}->{$_}->{mergeable_weight} = $TypeMergeableWeight->{$_} || $DefaultTypeMergeableWeight;
}

{
  my $i = 1;
  #0: all
  $Data->{leader_types} = {};
  for my $in (@{$Input->{leader_types} || []}) {
    my $key = $in->{key} // die;
    my $lt = $Data->{leader_types}->{$key} ||= {};
    $lt->{key} = $key;
    $lt->{index} = $i++;
    $lt->{short_label} = $in->{short_label} // $in->{label} // die;
    $lt->{label} = $in->{label} // die;
    $lt->{lang_tag} = $in->{lang_tag} // die;
  }
}

{
  my $path = $DataPath->child ('merged-index.json');
  print STDERR "\rWriting[1/4] |$path|... ";
  $path->spew (perl2json_bytes_for_record $Data);
}
{
  my $path = $DataPath->child ('merged-chars.jsonl');
  print STDERR "\rWriting[2/4] |$path|... ";
  my $file = $path->openw;
  for (keys %$Rels) {
    print $file perl2json_bytes $_;
    print $file "\x0A";
  }
}
{
  my $path = $DataPath->child ('merged-sets.json');
  print STDERR "\rWriting[3/4] |$path|... ";
  $path->spew (perl2json_bytes_for_record $Sets);
}
{
  my $path = $DataPath->child ("merged-rels.jsonll");
  print STDERR "\rWriting[4/4] |$path|... ";
  my $file = $path->openw;
  my $c1s = [sort { $a cmp $b } keys %$Rels];
  for my $c1 (@$c1s) {
    print $file perl2json_bytes_for_record $c1; # trailing \x0A
    print $file "\x0A";
    print $file perl2json_bytes_for_record $Rels->{$c1}; # trailing \x0A
    print $file "\x0A";
  }
}

printf STDERR "\rDone (%d s) \n", time - $StartTime;

## License: Public Domain.
