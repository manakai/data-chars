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
  my $path = $DataPath->child ('char-cluster-index.jsonl');
  print STDERR "\r|$path|... ";
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

my $Data = {};
{
  my $path = $DataPath->child ("clusters-0.jsonl");
  print STDERR "\r|$path|... ";
  my $file = $path->openr;
  local $/ = "\x0A";
  while (<$file>) {
    my $v = json_bytes2perl $_; # level index, [char]
    my $cluster_index = cci $v->[1];
    for my $c (@{$v->[1]}) {
      $Data->{$c}->[$v->[0]] = $cluster_index;
    }
  }
}

for my $c (sort { $a cmp $b } keys %$Data) {
  print perl2json_bytes [$c, $Data->{$c}];
  print "\x0A";
}

printf STDERR "Done (%s). \n", time - $StartTime;

## License: Public Domain.
