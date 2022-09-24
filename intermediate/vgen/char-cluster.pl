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

my $List = [];
my $run; $run = sub ($$) {
  my ($indexes, $prefix) = @_;

  for my $cluster (map { $DataChars->[$_] } @$indexes) {
    my $cis = [@$prefix, $cluster->{index}];
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
