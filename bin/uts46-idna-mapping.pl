use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib')->stringify;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;

my $Sets = {};
my $Map = {};

my $path = $root_path->child ('local/unicode/latest/IdnaMappingTable.txt');
for (split /\n/, $path->slurp) {
  s/\s*#.*$//;
  if (/\S/) {
    my ($cp, $status, $mapped, $ietf) = split /\s*;\s*/, $_, 4;
    my $from_code;
    my $to_code;
    if ($cp =~ /^([0-9A-Fa-f]+)\.\.([0-9A-Fa-f]+)$/) {
      $from_code = hex $1;
      $to_code = hex $2;
    } elsif ($cp =~ /^([0-9A-Fa-f]+)$/) {
      $from_code = $to_code = hex $1;
    } else {
      die "Bad line |$_|";
    }
    die "Bad line |$_|" unless defined $status and $status =~ /\A[0-9A-Za-z_-]+\z/;

    push @{$Sets->{$status} ||= []}, [$from_code, $to_code];

    if (defined $mapped and length $mapped) {
      die "Bad line |$_| ($mapped)" unless $mapped =~ /\A[0-9A-Fa-f]+(?:\s+[0-9A-Fa-f]+)*\z/;
      for ($from_code..$to_code) {
        $Map->{sprintf '%04X', $_} = join ' ', map { sprintf '%04X', hex $_ } split /\s+/, $mapped;
      }
    }

    if (defined $ietf and length $ietf) {
      die "Bad line |$_|" unless $ietf =~ /\A[0-9A-Za-z_-]+\z/;
      push @{$Sets->{$ietf} ||= []}, [$from_code, $to_code];
    }
  }
}

for my $name (keys %$Sets) {
  my $path = $root_path->child ("src/set/uts46/$name.expr");
  $path->spew_utf8 (qq{
#label:IDNA Mapping Table $name
#sw:IDNA Mapping Table
#url:http://www.unicode.org/reports/tr46/#IDNA_Mapping_Table
  [} . (join "\x0A", map {
    $_->[0] == $_->[1]
        ? sprintf q{\\u{%04X}}, $_->[0]
        : sprintf q{\\u{%04X}-\\u{%04X}}, $_->[0], $_->[1];
  } @{$Sets->{$name}}) . q{]});
}

{
  my $path = $root_path->child ('local/map-data/uts46--mapping.json');
  $path->parent->mkpath;
  $path->spew (perl2json_bytes {
    label => 'IDNA Mapping Table mapping',
    url => 'http://www.unicode.org/reports/tr46/#IDNA_Mapping_Table',
    suikawiki => 'IDNA Mapping Table',
    chars => $Map,
  });
}

## License: Public Domain.
