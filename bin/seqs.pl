use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;
my $Data = {};

{
  my $json = json_bytes2perl $root_path->child ('data/names.json')->slurp;
  for (keys %{$json->{code_seq_to_name}}) {
    $Data->{$_}->{has_name} = 1;
  }
}

{
  my $json = json_bytes2perl $root_path->child ('local/langtags.json')->slurp;
  for (keys %{$json->{region}}) {
    next unless /\A([a-z])([a-z])\z/;
    my $seq = sprintf '%04X %04X',
        0x1F1E6 - 0x61 + ord $1,
        0x1F1E6 - 0x61 + ord $2;
    $Data->{$seq}->{flag_region} = $1.$2;
  }
}

{
  my $json = json_bytes2perl $root_path->child ('local/html-charrefs.json')->slurp;
  for my $ref (keys %{$json}) {
    my $cp = $json->{$ref}->{codepoints};
    if (@$cp > 1) {
      my $seq = join ' ', map { sprintf '%04X', $_ } @$cp;
      $Data->{$seq}->{html_charref} = $ref;
    }
  }
}

{
  for (split /[\x0D\x0A]+/, $root_path->child ('src/seqs.txt')->slurp_utf8) {
    if (/^\s*#/) {
      next;
    } elsif (/^U\+[0-9A-Fa-f]+(?:\s+U\+[0-9A-Fa-f]+)+$/) {
      my $seq = join ' ', map {
        s/^U\+//;
        sprintf '%04X', hex $_;
      } split /\s+/, $_;
      $Data->{$seq} ||= {};
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
