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
  ## Kana with voiced/semi-voiced sound mark from TRON code
  ## <http://glyphwiki.org/wiki/Group:TRON%E3%82%B3%E3%83%BC%E3%83%89%E6%BF%81%E7%82%B9%E4%BB%98%E3%81%8D%E3%81%B2%E3%82%89%E3%81%8C%E3%81%AA%E3%83%BB%E3%82%AB%E3%82%BF%E3%82%AB%E3%83%8A>
  use utf8;
  for (split //, q(
    あいえおなにぬねのまみむめもやゆよらりるれろんわゐゑを
    ぁぃぅぇぉゕゖっゃゅょゎ
    アイエオナニヌネノマミムメモヤユヨラリルレロン
    ァィゥェォヵヶッャュョヮ
    ㇰㇱㇲㇳㇴㇵㇶㇷㇸㇹㇺㇻㇼㇽㇾㇿ
  )) {
    next unless /\S/;
    my $seq = sprintf '%04X 3099', ord $_;
    $Data->{$seq} ||= {};
    $seq = sprintf '%04X 309A', ord $_;
    $Data->{$seq} ||= {} unless $_ eq 'ㇷ';
  }
  for (split //, q(
    うさしすせそたちつてと
    ウサシスセソタチツテトワヰヱヲ
    ゝヽ
  )) {
    next unless /\S/;
    my $seq = sprintf '%04X 309A', ord $_;
    $Data->{$seq} ||= {};
  }
}

{
  for (split /[\x0D\x0A]+/, $root_path->child ('src/seqs.txt')->slurp_utf8) {
    if (/^\s*#/) {
      next;
    } elsif (/^(?:U\+[0-9A-Fa-f]+|"[^"]+")(?:\s+(?:U\+[0-9A-Fa-f]+|"[^"]+"))+$/) {
      my $seq = join ' ', map {
        if (s/^"//) {
          s/"$//;
          map { sprintf '%04X', ord $_ } split //, $_;
        } else {
          s/^U\+//;
          sprintf '%04X', hex $_;
        }
      } split /\s+/, $_;
      $Data->{$seq} ||= {};
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
