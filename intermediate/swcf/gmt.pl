use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $Data;
{
  local $/ = undef;
  my $text = <>;
  $Data = json_bytes2perl $text;
}

for my $cat (sort { $a cmp $b } keys %{$Data->{_categories}}) {
  printf "%s\n", $cat;

  for my $ucs (sort { $a cmp $b } keys %{$Data->{chars}}) {
    my $data = $Data->{chars}->{$ucs};
    next unless $data->{category} eq $cat;
    printf "%s\t%s",
        $ucs,
        $data->{default};
    if (keys %{$data->{vs} or {}}) {
      my $glyphs = join ' ', map { $data->{vs}->{$_} // '@' } map { sprintf '%04X', $_ } 0xE0100..0xE01EF;
      $glyphs =~ s/(?: \@)+$//;
      $glyphs =~ s/^\@$//;
      printf "\t%s", $glyphs;
      
      my $glyphs2 = join ' ', map { $data->{vs}->{$_} // '@' } map { sprintf '%04X', $_ } 0xFE00..0xFEFF;
      $glyphs2 =~ s/(?: \@)+$//;
      $glyphs2 =~ s/^\@$//;
      if ($glyphs2) {
        printf "\t%s", $glyphs2;
      } elsif (keys %{$data->{ligature} or {}} or keys %{$data->{zwjligature} or {}}) {
        print "\t";
      }
    } elsif (keys %{$data->{ligature} or {}} or keys %{$data->{zwjligature} or {}}) {
      print "\t\t";
    }
    
    if (keys %{$data->{ligature} or {}}) {
      my $glyphs = join ' ', map { $data->{ligature}->{$_} // '@' } map { sprintf '%04X', $_ } 0x16FF0..0x16FF1;
      $glyphs =~ s/(?: \@)+$//;
      $glyphs =~ s/^\@$//;
      printf "\t%s", $glyphs;
    } elsif (keys %{$data->{zwjligature} or {}}) {
      print "\t";
    }
    
    if (keys %{$data->{zwjligature} or {}}) {
      my $glyphs = join ' ', map { $_ . "=" . $data->{zwjligature}->{$_} } sort { $a cmp $b } keys %{$data->{zwjligature}};
      printf "\t%s", $glyphs;
    }

    print "\n";
  }
}

## License: Public Domain.
