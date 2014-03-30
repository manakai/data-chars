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
  if ($to_chars =~ / /) {
    warn "Duplicate: $to_chars" if $Data->{maps}->{'unicode:canon_composition'}->{char_seqs}->{$to_chars};
    $Data->{maps}->{'unicode:canon_composition'}->{char_seqs}->{$to_chars} = $from_char;
  } else {
    warn "Duplicate: $to_chars" if $Data->{maps}->{'unicode:canon_composition'}->{chars}->{$to_chars};
    $Data->{maps}->{'unicode:canon_composition'}->{chars}->{$to_chars} = $from_char;
  }
}

print perl2json_bytes_for_record $Data;
