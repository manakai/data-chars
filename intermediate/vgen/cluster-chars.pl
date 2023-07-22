use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;

my $CharClusterIndex;
{
  $CharClusterIndex = {};
  my $path = $DataPath->child ('merged-char-index.jsonl');
  print STDERR "\rLoading |$path|... ";
  my $file = $path->openr;
  local $/ = "\x0A";
  my $i = 0;
  while (<$file>) {
    my $index = $i++;
    my $char = json_bytes2perl $_;
    next unless defined $char;
    $CharClusterIndex->{$char} = $index;
  }
}

sub cci ($) {
  my $chars = $_[0];

  my $ci = 0+"Inf";
  for my $c (@$chars) {
    my $v = $CharClusterIndex->{$c};
    $ci = $v if $v < $ci;
  }

  return $ci;
} # cci

my $Data = [];
{
  my $PartSize = 5000;
  my $path = $DataPath->child ("cluster-temp.jsonl");
  print STDERR "\rLoading |$path|... ";
  my $file = $path->openr;
  local $/ = "\x0A";
  while (<$file>) {
    my $v = json_bytes2perl $_; # level index, [char]
    my $cluster_index = cci $v->[1];
    $Data->[$v->[0]]->{int ($cluster_index / $PartSize)}->{$cluster_index} = $v->[1];
  }
}

{
  my $dir_path = $DataPath->child ('cluster-chars');
  $dir_path->mkpath;
  for my $path (($dir_path->children (qr/^part-[0-9-]+\.jsonl$/))) {
    $path->remove;
  }
  for my $cluster_level_index (0..$#$Data) {
    my $part_count = keys %{$Data->[$cluster_level_index] or []};
    for my $part (sort { $a <=> $b } keys %{$Data->[$cluster_level_index] or {}}) {
      print STDERR "\rWriting [$cluster_level_index][$part/$part_count]... " if ($part % 10) == 0;
      my $path = $dir_path->child ('part-' . $cluster_level_index . '-' . $part . '.jsonl');
      my $file = $path->openw;
      for my $cluster_index (sort { $a <=> $b } keys %{$Data->[$cluster_level_index]->{$part}}) {
        print $file perl2json_bytes [$cluster_index, $Data->[$cluster_level_index]->{$part}->{$cluster_index}];
        print $file "\x0A";
      }
    }
  }
}

printf STDERR "\rDone (%s s) \n", time - $StartTime;

## License: Public Domain.
