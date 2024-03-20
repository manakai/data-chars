use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;

my $FileKey = shift;
my $FileDef = {
  'cluster' => {
    in_name => 'cluster-temp',
  },
}->{$FileKey} or die "Bad file-key |$FileKey|";

{
  $DataPath->child ($FileKey)->mkpath;
  for my $path (($DataPath->child ($FileKey)->children (qr{^part-[0-9-]+\.jsonl$}))) {
    $path->remove;
  }

  my $level = -1;
  my $limit = 1000; # see also: |site.js|'s |cPartSize|
  my $file_index = 0;
  my $i = 0;
  my $out_file;
  my $open_next = sub {
    $out_file = undef;
    print STDERR "\rWriting[$level,$file_index]... " if ($file_index % 100) == 0;
    my $out_name = 'part-' . $level . '-' . $file_index . '.jsonl';
    open $out_file, '>', $DataPath->child ($FileKey)->child ($out_name)
        or die $!;
    $file_index++;
    $i = 0;
  };

  open my $in_file, '<', $DataPath->child ("$FileDef->{in_name}.jsonl") or die $!;
  while (<$in_file>) {
    if (m{^\[([0-9]+),}) {
      if ($level != $1) {
        $level = $1;
        $file_index = 0;
        $i = 0;
      }
    }
    $open_next->() if ($i % $limit) == 0;
    print $out_file $_;
    $i++;
  }
}

printf STDERR "\rDone (%d s) \n", time - $StartTime;

## License: Public Domain.
