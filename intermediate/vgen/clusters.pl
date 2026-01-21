use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use DBI;
use List::Util qw(min max);

local $| = 1;
binmode STDERR, ":utf8";

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;
my $LogFile;

sub get_elapsed {
  return sprintf("[%ds]", time - $StartTime);
}

sub log_msg {
  my ($msg) = @_;
  print STDERR get_elapsed() . " " . $msg;
}

my $Data = { inset_pairs => {} };
my $Merged;
my $MergedSets;
my $dbh;
my $sth_variant_check;

{
  my $db_path = $DataPath->child ('rels.sqlite.37');
  my $jsonll_path = $DataPath->child ('merged-rels.jsonll');
  
  $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
    sqlite_unicode => 1,
  });
  
  $dbh->do("PRAGMA synchronous = OFF");
  $dbh->do("PRAGMA journal_mode = WAL");
  $dbh->do("PRAGMA cache_size = -500000");

  {
    log_msg("Building relations database from $jsonll_path ...\n");

    eval { $dbh->do (q{DROP TABLE char_rels}) };
    $dbh->do(q{
      CREATE TABLE char_rels (
        c1 TEXT NOT NULL,
        c2 TEXT NOT NULL,
        weight REAL NOT NULL,
        unmergeable_weight REAL,
        extra BLOB, 
        PRIMARY KEY (c1, c2)
      )
    });
    $dbh->do("CREATE INDEX idx_c1_weight ON char_rels(c1, weight DESC)");
    
    $dbh->do("BEGIN TRANSACTION");
    
    my $sth_sel = $dbh->prepare("SELECT weight, unmergeable_weight, extra FROM char_rels WHERE c1 = ? AND c2 = ?");
    my $sth_ins = $dbh->prepare("INSERT INTO char_rels (c1, c2, weight, unmergeable_weight, extra) VALUES (?, ?, ?, ?, ?)");
    my $sth_upd = $dbh->prepare("UPDATE char_rels SET weight = ?, unmergeable_weight = ?, extra = ? WHERE c1 = ? AND c2 = ?");
    
    my $file = $jsonll_path->openr;
    local $/ = "\x0A\x0A";
    my $count = 0;
    
    while (defined(my $line1 = <$file>)) {
      my $c1 = json_bytes2perl $line1;
      my $line2 = <$file>;
      last unless defined $line2;
      my $c1v = json_bytes2perl $line2;
      
      for my $c2 (keys %$c1v) {
        if ($count % 100000 == 0) {
          if ($count > 0) {
            $dbh->do("COMMIT");
            $dbh->do("BEGIN TRANSACTION");
          }
          print STDERR "\r" . get_elapsed() . "    $count relations processed...";
        }

        my $rel = $c1v->{$c2};
        my $new_w = $rel->{_};
        my $new_u = $rel->{_u}; 
        
        my $extra_hash = {%$rel};
        delete $extra_hash->{_};
        delete $extra_hash->{_u};
        my $has_extra = scalar(keys %$extra_hash) > 0;
        
        my ($k1, $k2) = ($c1 lt $c2) ? ($c1, $c2) : ($c2, $c1);
        
        $sth_sel->execute($k1, $k2);
        if (my $row = $sth_sel->fetchrow_arrayref) {
          my ($old_w, $old_u, $old_extra_blob) = @$row;
          
          # Weight: MAX
          my $merged_w = ($new_w > $old_w) ? $new_w : $old_w;
          
          # Unmergeable: MIN
          my $merged_u = $old_u;
          if (defined $new_u) {
            if (!defined $old_u || $new_u < $old_u) {
              $merged_u = $new_u;
            }
          }
          
          my $merged_extra_blob = $old_extra_blob;
          if ($has_extra) {
            my $old_extra = defined $old_extra_blob ? json_bytes2perl($old_extra_blob) : {};
            my $merged_hash = { %$old_extra, %$extra_hash };
            
            $merged_extra_blob = perl2json_bytes($merged_hash);
          }
          
          $sth_upd->execute($merged_w, $merged_u, $merged_extra_blob, $k1, $k2);
          
        } else {
          my $extra_blob = undef;
          if ($has_extra) {
              $extra_blob = perl2json_bytes($extra_hash);
          }
          
          $sth_ins->execute(
            $k1, $k2, 
            $new_w, 
            $new_u, 
            $extra_blob
          );
        }
        $count++;
      }
    }
    $sth_sel->finish;
    $sth_ins->finish;
    $sth_upd->finish;
    
    $dbh->do("COMMIT");
    print STDERR "\r" . get_elapsed() . "    $count relations processed.      \n";
  }
}

{
  my $path = $DataPath->child ('merged-index.json');
  $Merged = json_bytes2perl $path->slurp;
}
{
  my $path = $DataPath->child ('merged-sets.json');
  $MergedSets = json_bytes2perl $path->slurp;
}

my $MergedChars = [];
my %CharToIdx; 
my @IdxToChar;
{
  my $path = $DataPath->child ('merged-chars.jsonl');
  log_msg("Loading characters from $path...\n");
  unless (-e $path) {
      die "Error: $path not found.\n";
  }

  my $file = $path->openr;
  while (defined(my $line = <$file>)) {
    push @$MergedChars, json_bytes2perl($line);
  }

  my $idx = 0;
  for my $c (@$MergedChars) {
    $CharToIdx{$c} = $idx;
    $IdxToChar[$idx] = $c;
    $idx++;
  }
  log_msg("  " . scalar(@$MergedChars) . " characters loaded.\n");
}

sub make_uf_stateful {
  my ($n) = @_;
  return {
    parent => [0 .. $n-1],
    rank   => [(0) x $n],
    size   => [(1) x $n],
    forbidden => {},
    insets    => {},
  };
}

sub uf_find {
  my ($uf, $x) = @_;
  if ($uf->{parent}[$x] != $x) {
    $uf->{parent}[$x] = uf_find($uf, $uf->{parent}[$x]);
  }
  return $uf->{parent}[$x];
}

sub uf_union_stateful {
  my ($uf, $x, $y) = @_;
  my $px = uf_find($uf, $x);
  my $py = uf_find($uf, $y);
  return if $px == $py;
  
  if ($uf->{rank}[$px] < $uf->{rank}[$py]) {
    ($px, $py) = ($py, $px);
  }
  
  $uf->{size}->[$px] += $uf->{size}->[$py];
  
  if (my $py_forbidden = delete $uf->{forbidden}->{$py}) {
    for my $fb_root (keys %$py_forbidden) {
      my $fb_curr = uf_find($uf, $fb_root);
      next if $fb_curr == $px;
      $uf->{forbidden}->{$px}->{$fb_curr} = 1;
      delete $uf->{forbidden}->{$fb_curr}->{$py};
      $uf->{forbidden}->{$fb_curr}->{$px} = 1;
    }
  }
  
  if (my $py_insets = delete $uf->{insets}->{$py}) {
    while (my ($set_key, $chars) = each %$py_insets) {
      push @{$uf->{insets}->{$px}->{$set_key}}, @$chars;
    }
  }

  $uf->{parent}[$py] = $px;
  $uf->{rank}[$px]++ if $uf->{rank}[$px] == $uf->{rank}[$py];
}

sub uf_init_constraints {
  my ($uf, $explicit_pairs) = @_;
  
  if (@{$Merged->{inset_keys}}) {
    for my $set_key (@{$Merged->{inset_keys}}) {
      my $set = $MergedSets->{$set_key};
      for my $c (keys %$set) {
        if (defined(my $idx = $CharToIdx{$c})) {
          push @{$uf->{insets}->{$idx}->{$set_key}}, $idx;
        }
      }
    }
  }
  
  for my $pair (@$explicit_pairs) {
    my ($id1, $id2) = @$pair;
    $uf->{forbidden}->{$id1}->{$id2} = 1;
    $uf->{forbidden}->{$id2}->{$id1} = 1;
  }
}

sub get_cluster_repr {
  my ($uf, $root) = @_;
  my $c = $IdxToChar[$root];
  my $size = $uf->{size}->[$root];
  my $inset_info = "";
  if ($uf->{insets}->{$root}) {
      my @keys = keys %{$uf->{insets}->{$root}};
      $inset_info = " (Insets: " . join(",", @keys) . ")";
  }
  return "'$c' + " . ($size - 1) . " chars$inset_info";
}

sub check_unmergeable {
  my ($uf, $r1, $r2, $min_weight, $enable_inset_check) = @_;

  # 1. Explicit Unmergeable
  if ($uf->{forbidden}->{$r1} && $uf->{forbidden}->{$r1}->{$r2}) {
    return (1, "Explicit forbidden rule (weight < $min_weight)");
  }

  # 2. Inset Check
  if ($enable_inset_check) {
    my $insets1 = $uf->{insets}->{$r1};
    my $insets2 = $uf->{insets}->{$r2};
    
    if ($insets1 && $insets2) {
      for my $set_key (keys %$insets1) {
        if (exists $insets2->{$set_key}) {
          my $chars1 = $insets1->{$set_key};
          my $chars2 = $insets2->{$set_key};
          
          for my $id1 (@$chars1) {
            my $c1 = $IdxToChar[$id1];
            for my $id2 (@$chars2) {
              my $c2 = $IdxToChar[$id2];
              
              my ($k1, $k2) = ($c1 lt $c2) ? ($c1, $c2) : ($c2, $c1);
              
              unless ($sth_variant_check) {
                $sth_variant_check = $dbh->prepare_cached(q{
                  SELECT extra FROM char_rels WHERE c1 = ? AND c2 = ?
                });
              }
              
              $sth_variant_check->execute($k1, $k2);
              my $row = $sth_variant_check->fetchrow_arrayref;
              
              my $is_variant = 0;
              if ($row && defined $row->[0]) {
                my $extra = json_bytes2perl($row->[0]);
                if ($extra->{"manakai:inset:$set_key:variant"}) {
                  $is_variant = 1;
                }
              }
              
              unless ($is_variant) {
                $Data->{inset_pairs}->{$c1}->{$c2} = 1;
                return (1, "Inset '$set_key' conflict: '$c1' vs '$c2' (not a variant)");
              }
            }
          }
        }
      }
    }
  }
  return (0, undef);
}

sub log_reject {
  my ($level_name, $reason, $c1_info, $c2_info) = @_;
  print $LogFile "[$level_name] REJECTED: $reason\n";
  print $LogFile "  L: $c1_info\n";
  print $LogFile "  R: $c2_info\n";
  print $LogFile "--------------------------------------------------\n";
}

$LogFile = $DataPath->child('rejected-merges.log')->openw;
binmode($LogFile, ":utf8");
print $LogFile "Rejected Merges Log\n";

my $output_file = $DataPath->child('cluster-temp.jsonl')->openw;

{
  log_msg("Level 0 (Initial): Writing all chars as single clusters...\n");
  for my $c (@$MergedChars) {
    print $output_file perl2json_bytes([0, [$c]]);
    print $output_file "\x0A";
  }
}

my @SortedLevels = sort { $a->{index} <=> $b->{index} } values %{$Merged->{cluster_levels}};
my $InsetMergeableWeight = $Merged->{inset_mergeable_weight} // 0;
my $N = scalar @$MergedChars;

for my $level_config (@SortedLevels) {
  my $level_key = $level_config->{key};
  my $level_idx = $level_config->{index} + 1;
  my $out_level_id = $level_config->{index}; 
  
  my $min_weight = $level_config->{min_weight};
  my $enable_inset = ($min_weight > $InsetMergeableWeight) ? 1 : 0;
  
  log_msg("Processing Level: $level_key (ID: $out_level_id, MinWeight: $min_weight)\n");
  print $LogFile "\n=== Level $level_key (MinWeight: $min_weight) ===\n";

  my $uf = make_uf_stateful($N);
  
  # 5.1 Explicit Constraints
  my @explicit_pairs;
  my $sth_unm = $dbh->prepare(q{
    SELECT c1, c2 FROM char_rels 
    WHERE unmergeable_weight IS NOT NULL 
      AND unmergeable_weight < ?
  });
  $sth_unm->execute($min_weight);
  while (my $row = $sth_unm->fetchrow_arrayref) {
    if (exists $CharToIdx{$row->[0]} && exists $CharToIdx{$row->[1]}) {
       push @explicit_pairs, [$CharToIdx{$row->[0]}, $CharToIdx{$row->[1]}];
    }
  }
  uf_init_constraints($uf, \@explicit_pairs);
  
  # 5.2 Merge Candidates
  my @rels;
  my $sth_rels = $dbh->prepare(q{
    SELECT c1, c2, weight FROM char_rels 
    WHERE weight >= ?
  });
  $sth_rels->execute($min_weight);
  while (my $row = $sth_rels->fetchrow_arrayref) {
    next unless exists $CharToIdx{$row->[0]} && exists $CharToIdx{$row->[1]};
    push @rels, [$CharToIdx{$row->[0]}, $CharToIdx{$row->[1]}, $row->[2]];
  }
  @rels = sort { $b->[2] <=> $a->[2] } @rels;
  
  # 5.3 Clustering
  my ($processed, $merged, $rejected) = (0, 0, 0);
  for my $rel (@rels) {
    if (++$processed % 100000 == 0) {
      print STDERR "\r" . get_elapsed() . "    Processed $processed edges...";
    }
    
    my ($id1, $id2) = ($rel->[0], $rel->[1]);
    my $r1 = uf_find($uf, $id1);
    my $r2 = uf_find($uf, $id2);
    
    next if $r1 == $r2;
    
    my ($is_ng, $reason) = check_unmergeable($uf, $r1, $r2, $min_weight, $enable_inset);
    
    if ($is_ng) {
      $rejected++;
      if ($enable_inset) {
        log_reject($level_key, $reason, get_cluster_repr($uf, $r1), get_cluster_repr($uf, $r2));
      }
      next;
    }
    
    uf_union_stateful($uf, $id1, $id2);
    $merged++;
  }
  print STDERR "\r" . get_elapsed() . "    Done. Merged: $merged, Rejected: $rejected.           \n";
  
  # 5.4 Write Output
  log_msg("  Writing clusters to file...\n");
  my %root_to_chars;
  for (my $i = 0; $i < $N; $i++) {
    my $root = uf_find($uf, $i);
    push @{$root_to_chars{$root}}, $IdxToChar[$i];
  }
  
  for my $root (keys %root_to_chars) {
    my $chars = $root_to_chars{$root};
    my @sorted_chars = sort { $a cmp $b } @$chars;
    print $output_file perl2json_bytes([$out_level_id, \@sorted_chars]);
    print $output_file "\x0A";
  }
}

close $output_file;

{
  my $path = $DataPath->child ('cluster-index.json');
  log_msg("Writing cluster index to $path...\n");
  $path->spew (perl2json_bytes_for_record $Data);
}

close $LogFile;
if ($sth_variant_check) { $sth_variant_check->finish; }
$dbh->disconnect;

log_msg("All done.\n");

exit 0;

## License: Public Domain.
