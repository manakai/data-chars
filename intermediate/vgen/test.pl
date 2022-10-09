use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.')->absolute;

my $Levels = [];
{
  my $path = $DataPath->child ('cluster-root.json');
  my $json = json_bytes2perl $path->slurp;
  for (@{$json->{cluster_levels}}) {
    $Levels->[$_->{index}] = $_;
  }
}
my $Chars = {};
{
  my $path = $DataPath->child ('clusters-1.jsonl');
  print STDERR "Loading |$path|...\n";
  my $file = $path->openr;
  local $/ = "\x0A";
  while (<$file>) {
    my $json = json_bytes2perl $_;
    $Chars->{$json->[0]} = $json->[1];
  }
}

my $TestData;
{
  my $path = $DataPath->child ('testdata.json');
  $TestData = json_bytes2perl $path->slurp;
}

binmode STDOUT, qw(:encoding(utf-8));
my $Index = 0;
sub ok ($$$$) {
  if ($ENV{VERBOSE}) {
    printf "ok %d # %s: %s |%s| |%s|\n",
      ++$Index, $_[3], $Levels->[$_[2]]->{key}, $_[0], $_[1];
  } else {
    printf "ok %d\n",
        ++$Index;
  }
} # ok
my $HasNG = 0;
sub ng ($$$$) {
  printf "not ok %d # %s: %s |%s| |%s|\n",
      ++$Index, $_[3], $Levels->[$_[2]]->{key}, $_[0], $_[1];
  $HasNG = 1;
} # ng
sub end () {
  printf "1..%d\n", $Index;
  exit $HasNG;
}

for my $c1 (sort { $a cmp $b } keys %$TestData) {
  my $cl1 = $Chars->{$c1};
  if (not defined $cl1) {
    ng $c1, '', 0, '< not defined';
    next;
  }
  for my $c2 (sort { $a cmp $b } keys %{$TestData->{$c1}}) {
    my $cl2 = $Chars->{$c2};
    if (not defined $cl2) {
      ng $c1, $c2, 0, '> not defined';
      next;
    }
    for my $index (sort { $a <=> $b } keys %{$TestData->{$c1}->{$c2}}) {
      my $expected = $TestData->{$c1}->{$c2}->{$index};
      my $cli1 = $cl1->[@$cl1 - $index];
      my $cli2 = $cl2->[@$cl2 - $index];
      my $actual = $cli1 == $cli2 ? +1 : -1;
      if ($expected == $actual) {
        ok $c1, $c2, $index, "$cli1, $cli2";
      } else {
        ng $c1, $c2, $index, "$cli1, $cli2";
      }
    }
  }
}

end;

## License: Public Domain.
