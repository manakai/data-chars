use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/ivn');
my $DataPath = $RootPath->child ('local/maps');
my $Data = {};

sub u_rcv ($) {
  my $s = shift;
  if (2 == length $s) {
    my $c1 = sprintf ':u-rcv-%x-%x',
        (ord substr $s, 0, 1),
        (ord substr $s, 1, 1);
    my $c2 = chr ord substr $s, 0, 1;
    $Data->{codes}->{$c2}->{$c1}->{'hannom-rcv:ivs'} = 1;
    return $c1;
  } else {
    return $s;
  }
} # u_rcv

{
  my $path = $ThisPath->child ('rcv.json');
  my $json = json_bytes2perl $path->slurp;
  for (map { @$_ } $json->{1}, $json->{2}, $json->{html}) {
    for my $prefix (qw(minhnguyen gothicnguyen hannomkhai)) {
      for (@$_) {
        my $c1 = u_rcv $_;
        my $c2 = sprintf ':u-%s-%s', $prefix, join '-', map { sprintf '%x', ord $_ } split //, $_;
        $Data->{glyphs}->{$c2}->{$c1}->{'manakai:implements'} = 1;
      }
    }
  }
  for (map { keys %{$_} } $json->{_in_ivd}, $json->{_not_in_ivd}) {
    my @s = map { chr hex $_ } split / /, $_;
    my $c1 = u_rcv join '', @s;
    my $c2 = join '', @s;
    $Data->{codes}->{$c2}->{$c1}->{'manakai:private'} = 1;
  }
}

write_rel_data_sets
    $Data => $DataPath, 'vietglyphs',
    [];

## License: Public Domain.
