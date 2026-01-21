use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $VGenPath = path (__FILE__)->parent;
my $RootPath = $VGenPath->parent->parent;
my $DestPath = $RootPath->child ('local/generated/charrels');

my $Input;
my $InputPath = path (shift);
my $InBasePath = $InputPath->parent->realpath;
my $DestDirPath;
my @dep_path;
{
  push @dep_path, $InputPath;
  $Input = json_bytes2perl $InputPath->slurp;
  my $key = $Input->{key};
  die "Bad key |$key|" unless $key =~ /\A[a-z]+\z/;
  $DestDirPath = $DestPath->child ($key);
  $DestDirPath->mkpath;
}

{
  my $out_path = $DestDirPath->child ('weights.pl')->realpath;
  my $in_path = $InBasePath->child ($Input->{key} . '-weights.pl');
  if ($in_path->is_file) {
    $out_path->spew ($in_path->slurp);
  } else {
    my $in_path = $InBasePath->child ('weights.pl');
    $out_path->spew ($in_path->slurp);
  }
}

{
  my $in_path = $VGenPath->child ('.gitignore.template');
  my $out_path = $DestDirPath->child ('.gitignore');
  $out_path->spew ($in_path->slurp);
}

{
  my $out_path = $DestDirPath->child ('input.json')->realpath;
  my $out_base_path = $out_path->parent;
  for (@{$Input->{inputs}}) {
    my $path = path ($_->{path})->absolute ($InBasePath)->realpath;
    push @dep_path, $path;
    $_->{path} = $path->relative ($out_base_path);
  }
  $out_path->spew (perl2json_bytes_for_record $Input);
}

my @test_dep_path;
{
  my $out_path = $DestDirPath->child ('tests.txt')->realpath;
  my $out_base_path = $out_path->parent;
  my @test;
  for (@{$Input->{tests}}) {
    my $path = path ($_)->absolute ($InBasePath)->realpath;
    push @test_dep_path, $path;
    push @test, $path->slurp;
  }
  $out_path->spew (join "\n", @test);
}

{
  my $in_path = $VGenPath->child ('Makefile.template');
  push @dep_path, $in_path;
  my $out_path = $DestDirPath->child ('Makefile');
  my $out_base_path = $out_path->parent;
  my $make = $in_path->slurp;
  $make =~ s{\@\@INPUTS\@\@}{
    join " \\\n  ", sort { $a cmp $b } map { $_->relative ($out_base_path) } @dep_path
  }ge;
  $make =~ s{\@\@TESTINPUTS\@\@}{
    join " \\\n  ", sort { $a cmp $b } map { $_->relative ($out_base_path) } @test_dep_path
  }ge;
  $out_path->spew ($make);
}

## License: Public Domain.
