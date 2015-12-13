use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $data_path = path (__FILE__)->parent->parent->child ('local/spec-numbers.json');
my $src_path = path (__FILE__)->parent->parent->child ('src/set/numbers');

my $Data = json_bytes2perl $data_path->slurp;

my $Categories = {};

for my $data (@{$Data->{'cjk-numeral'}}) {
  my $cat = $data->{category}->[0] // die "No |category|";
  my $char = $data->{codepoint}->[0] // die "No |codepoint|";
  $char =~ s/^U\+//;
  push @{$Categories->{$cat}->{chars} ||= []}, sprintf '\u{%04X}', hex $char;
}

for my $name (keys %$Categories) {
  my $file_name = $name;
  $file_name =~ s/[^A-Za-z0-9]/-/g;
  my $chars = join '', sort { $a cmp $b } @{$Categories->{$name}->{chars}};
  my $url = $Data->{categories}->{$name}->{url};
  $src_path->child ("$file_name.expr")->spew_utf8 (qq{
#label:$name
#url:$url
#sw:$name
[$chars]
  });
}

## License: Public Domain.
