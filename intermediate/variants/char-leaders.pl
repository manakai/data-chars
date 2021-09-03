use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;

my $Data;
{
  my $path = $ThisPath->child ('cluster-root.json');
  $Data = json_bytes2perl $path->slurp;
}
my $DataProps = [];
{
  my $i = 0;
  {
    $i++;
    my $path = $ThisPath->child ("cluster-props-$i.txt");
    last unless $path->is_file;
    my $file = $path->openr;
    local $/ = "\x0A\x0A";
    while (<$file>) {
      push @$DataProps, json_bytes2perl $_;
    }
    redo;
  }
}

my $level_index = @{$Data->{cluster_levels}} - [grep { $_->{key} eq 'EQUIV' } @{$Data->{cluster_levels}}]->[0]->{index};
my $LeaderTypes = [sort { $a->{index} <=> $b->{index} } values %{$Data->{leader_types}}];

{
  my $path = $ThisPath->child ("char-cluster.jsonl");
  my $file = $path->openr;
  local $/ = "\x0A";
  while (<$file>) {
    my $json = json_bytes2perl $_;
    my $c = $json->[0];
    my $cluster_index = $json->[1]->[$level_index];
    my $leaders = $DataProps->[$cluster_index]->{leaders};
    my $vv = [$leaders->{all}];
    for my $lt (@$LeaderTypes) {
      push @$vv, $leaders->{$lt->{key}}; # or undef
    }
    next if ($c eq $vv->[0] and 1 == grep { defined $_ } @$vv);
    print perl2json_bytes [$c, $vv];
    print "\x0A";
  }
}

## License: Public Domain.
