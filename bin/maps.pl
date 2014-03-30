use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use JSON::Functions::XS qw(perl2json_bytes_for_record file2perl);
use Unicode::Normalize qw(NFD);

my $Data = {};

sub uhex ($) {
  return sprintf '%04X', hex $_[0];
} # uhex

sub u ($) {
  return sprintf '%04X', $_[0];
} # u

my $Maps = {};

## <http://www.unicode.org/reports/tr44/#Character_Decomposition_Mappings>
{
  my $f = file (__FILE__)->dir->parent->file ('local', 'unicode', 'latest', 'UnicodeData.txt');
  for (($f->slurp)) {
    my @d = split /;/, $_;
    next if $d[5] eq '';
    if ($d[5] =~ s/^<[^<>]+>\s*//) {
      $Maps->{'unicode:compat_decomposition'}->{hex $d[0]} = [map { hex $_ } split / /, $d[5]];
    } else {
      $Maps->{'unicode:canon_decomposition'}->{hex $d[0]} =
      $Maps->{'unicode:compat_decomposition'}->{hex $d[0]} = [map { hex $_ } split / /, $d[5]];
    }
  }
}

for (0xAC00..0xD7A3) {
  $Maps->{'unicode:canon_decomposition'}->{$_} =
  $Maps->{'unicode:compat_decomposition'}->{$_} = [map { ord $_ } split //, NFD chr $_];
}

use Unicode::Stringprep::Mapping;
for (
  ['rfc3454:B.1' => \@Unicode::Stringprep::Mapping::B1],
  ['rfc3454:B.2' => \@Unicode::Stringprep::Mapping::B2],
  ['rfc3454:B.3' => \@Unicode::Stringprep::Mapping::B3],
) {
  my @m = @{$_->[1]};
  while (@m) {
    my $s = shift @m;
    my $t = [map { ord $_ } split //, shift @m];
    $Maps->{$_->[0]}->{$s} = $t;
  }
}

{
  my $f = file (__FILE__)->dir->parent->file ('src', 'tn1150table.txt');
  my %map = map { join ' ', map { uhex $_ } grep { length } split /\s+/, $_ } split /\s*,\s*/, scalar $f->slurp;
  for (keys %map) {
    $Maps->{'tn1150:decomposition'}->{hex $_} = [map { hex $_ } split / /, $map{$_}];
  }
}

## <http://www.whatwg.org/specs/web-apps/current-work/#case-sensitivity-and-string-comparison>
## <http://dom.spec.whatwg.org/#strings>
for my $from ('A'..'Z') {
  my $to = $from;
  $to =~ tr/A-Z/a-z/;
  $Maps->{'html:to-ASCII-lowercase'}->{ord $from} = [ord $to];
  $Maps->{'html:to-ASCII-uppercase'}->{ord $to} = [ord $from];
  $Maps->{'dom:to-ASCII-lowercase'}->{ord $from} = [ord $to];
  $Maps->{'dom:to-ASCII-uppercase'}->{ord $to} = [ord $from];
}

{
  use utf8;
  my @hira = split //, 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんゔがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉゃゅょっゕゖ';
  my @kata = split //, 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンヴガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポァィゥェォャュョッヵヶ';
  for (0..$#hira) {
    $Maps->{'kana:h2k'}->{ord $hira[$_]} = [ord $kata[$_]];
    $Maps->{'kana:k2h'}->{ord $kata[$_]} = [ord $hira[$_]];
  }
}

for my $map (keys %$Maps) {
  for my $char (keys %{$Maps->{$map}}) {
    my @m = @{$Maps->{$map}->{$char}};
    {
      my $changed;
      @m = map {
        if (defined $Maps->{$map}->{$_}) {
          $changed = 1;
          @{$Maps->{$map}->{$_}};
        } else {
          ($_);
        }
      } @m;
      redo if $changed;
    }
    $Data->{maps}->{$map}->{chars}->{u $char} = join ' ', map { u $_ } @m;
  }
}

my $full_exclusion;
{
  my $json = file2perl file (__FILE__)->dir->parent->file ('data', 'sets.json');
  my $chars = $json->{sets}->{'$unicode:Full_Composition_Exclusion'}->{chars};
  $chars =~ s/\\u([0-9A-F]{4})/\\x{$1}/g;
  $chars =~ s/\\u\{([0-9A-F]+)\}/\\x{$1}/g;
  $full_exclusion = qr/$chars/;
}

for my $from_char (keys %{$Data->{maps}->{'unicode:canon_decomposition'}->{chars}}) {
  my $to_chars = $Data->{maps}->{'unicode:canon_decomposition'}->{chars}->{$from_char};
  next if (chr hex $from_char) =~ /$full_exclusion/o;
  warn "Duplicate: $to_chars" if $Data->{maps}->{'unicode:canon_composition'}->{chars}->{$to_chars};
  $Data->{maps}->{'unicode:canon_composition'}->{chars}->{$to_chars} = $from_char;
}

for my $key (keys %{$Data->{maps}}) {
  my $entries = delete $Data->{maps}->{$key}->{chars};
  for my $from (keys %$entries) {
    my $to = $entries->{$from};
    my $type = join '_to_',
        $from =~ / / ? 'seq' : 'char',
        $to eq '' ? 'empty' : $to =~ / / ? 'seq' : 'char';
    $Data->{maps}->{$key}->{$type}->{$from} = $to;
  }
}

print perl2json_bytes_for_record $Data;
