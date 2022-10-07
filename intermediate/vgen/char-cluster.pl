use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');

my $Data;
{
  my $path = $DataPath->child ('cluster-root.json');
  $Data = json_bytes2perl $path->slurp;
}
my $DataChars = [];
{
  my $i = 0;
  {
    $i++;
    my $path = $DataPath->child ("cluster-chars-$i.txt");
    last unless $path->is_file;
    my $file = $path->openr;
    local $/ = "\x0A\x0A";
    while (<$file>) {
      push @$DataChars, json_bytes2perl $_;
    }
    redo;
  }
}

my $CharClusterIndex;
{
  last unless $ENV{CCI};
  $CharClusterIndex = {};
  my $path = $DataPath->child ('char-cluster-index.jsonl');
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
  my $cluster = $_[0];

  my $ci = 0+"Inf";
  for my $c (keys %{$cluster->{chars}}) {
    my $v = $CharClusterIndex->{$c};
    $ci = $v if $v < $ci;
  }

  return $ci;
} # cci

my $List = [];
my $run; $run = sub ($$) {
  my ($indexes, $prefix) = @_;

  for my $cluster (map { $DataChars->[$_] } @$indexes) {
    my $ci = $cluster->{index};
    $ci = cci $cluster if defined $CharClusterIndex;
    my $cis = [@$prefix, $ci];
    if (defined $cluster->{cluster_indexes}) {
      $run->($cluster->{cluster_indexes}, $cis);
    } else {
      for my $c (keys %{$cluster->{chars}}) {
        push @$List, [$c, $cis];
      }
    }
  }
}; # $run
$run->($Data->{cluster_indexes}, []);

$List = [sort { $a->[0] cmp $b->[0] } @$List];
{
  for (@$List) {
    print perl2json_bytes $_;
    print "\x0A";
  }
}

## License: Public Domain.
