use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

{
  my $path = $RootPath->child ('data/maps.json');
  my $json = json_bytes2perl $path->slurp;
  {
    my $map = $json->{maps}->{'kana:normalize'};
    for my $key (qw(char_to_char char_to_seq seq_to_char seq_to_seq)) {
      for (keys %{$map->{$key}}) {
        my $input = join '', map { chr hex } split / /, $map->{$key}->{$_};
        my $output = join '', map { chr hex } split / /, $map->{$key}->{$_};
        $Data->{normalize}->{$input} = $input;
      }
    }
  }
}

{
  ## Unchanged
  for (
    0x0000..0x00FF,
    0x4E00,
    0xE000,
    0xF800..0xF8FF,
    0x10000,
    0x1F200,
    0x1F201,
    0x1F202,
    0x1F213,
    0x1F214,
    0x20000,
    0x100000,
    0x10FFFF,
    0x3000..0x33FF,
    0xFF00..0xFFFF,
    0x1B000..0x1B1FF,
  ) {
    my $input = my $output = chr $_;
    $Data->{normalize}->{$input} //= $output;
  }

  my @first = map { substr $_, 0, 1 } keys %{$Data->{normalize}};
  for my $input (@first) {
    $Data->{normalize}->{$input} //= $input;
    $Data->{normalize}->{$input."\x{3099}"} //= $input."\x{3099}";
    $Data->{normalize}->{$input."\x{309A}"} //= $input."\x{309A}";
  }

  $Data->{normalize}->{''} = '';
}

for (
  [q{　！”＃＄％＆’（）＊＋，−．／：；＜＝＞？＠［］＾＿｀｛｜｝,},
   q{  !"#$%&'()*+,-./:;<=>?@[]^_`{|},}],
  [q{｡､･｢｣}, q{。、・「」}],
) {
  my ($input, $output) = @$_;
  $Data->{normalize}->{$input} = $output;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
