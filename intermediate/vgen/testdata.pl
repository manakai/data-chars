use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $Data = {};

sub ue ($) {
  my $s = shift;
  $s =~ s{\\u([0-9A-Fa-f]{4})}{chr hex $1}ge;
  $s =~ s{\\u\{([0-9A-Fa-f]+)\}}{chr hex $1}ge;
  return $s;
} # ue

my $Levels = {};
{
  my $path = $DataPath->child ('merged-index.json');
  my $json = json_bytes2perl $path->slurp;
  for (values %{$json->{cluster_levels}}) {
    $Levels->{$_->{key}} = $_;
  }
}

{
  my $path = $DataPath->child ('tests.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)\s+(\S+)\s+(\S.+)$/) {
      my $c1 = ue $1;
      my $c2 = ue $2;
      my $s = $3;
      ($c1, $c2) = ($c2, $c1) unless $c1 le $c2;
      for (split /\s+/, $s) {
        if (/^!(.+)$/) {
          my $level = $Levels->{$1}
              // die "Bad level |$1|";
          if (defined $Data->{$c1}->{$c2}->{$level->{index}} and
              $Data->{$c1}->{$c2}->{$level->{index}} != -1) {
            die "Conflict test result: |$c1|, |$c2|, $1";
          }
          $Data->{$c1}->{$c2}->{$level->{index}} = -1;
        } else {
          my $level = $Levels->{$_}
              // die "Bad level |$_|";
          if (defined $Data->{$c1}->{$c2}->{$level->{index}} and
              $Data->{$c1}->{$c2}->{$level->{index}} != +1) {
            die "Conflict test result: |$c1|, |$c2|, $_";
          }
          $Data->{$c1}->{$c2}->{$level->{index}} = +1;
        }
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
