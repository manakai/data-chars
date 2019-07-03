use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Table = json_bytes2perl $RootPath->child ('src/mj-hentai.json')->slurp;

{
  use utf8;
  my @ucs;
  my @han;
  my $ToStandardKana = {};
  for my $data (@{$Table->{data}}) {
    my $ucs;
    if ($data->{UCS} =~ /^U\+([0-9A-Fa-f]+)$/) {
      push @ucs, $ucs = chr hex $1;
    } elsif ($data->{UCS} eq '') {
      #
    } else {
      die "Bad |UCS| |$data->{UCS}|";
    }

    my $han;
    if ($data->{字母のUCS} =~ /^U\+([0-9A-Fa-f]+)$/) {
      push @han, $han = chr hex $1;
    } elsif ($data->{字母のUCS} eq '') {
      #
    } else {
      die "Bad |字母のUCS| |$data->{字母のUCS}|";
    }

    if (defined $ucs and
        length $data->{"音価１"} and
        not length $data->{"音価２"}) {
      $ToStandardKana->{$ucs} = $data->{"音価１"};
    }
  }

  {
    my $path = $RootPath->child ('src/set/mj/hentaigana.expr');
    $path->spew_utf8 (sprintf "#sw:変体仮名\n[%s]",
                          join '', sort { $a cmp $b } @ucs);
  }
  {
    my $path = $RootPath->child ('src/set/mj/hentaigana-han.expr');
    $path->spew_utf8 (sprintf "#sw:変体仮名\n[%s]",
                          join '', sort { $a cmp $b } @han);
  }

  {
    my $path = $RootPath->child ('local/hentai_to_standard.json');
    $path->spew (perl2json_bytes_for_record $ToStandardKana);
  }
}

## License: Public Domain.
