use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;
BEGIN { require 'chars.pl' }
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwh');
my $TempADPath = $RootPath->child ('local/iad');

my $Data = {};

sub b5_chr ($) {
  my $b5 = shift;
  my $c1 = is_b5_variant $b5 ? sprintf ':b5-hkscs-%x', $b5,
                             : sprintf ':b5-%x', $b5;
  my $c1_0 = $c1;
  $c1_0 =~ s/^:b5-hkscs-/:b5-/g;
  $Data->{codes}->{$c1_0}->{$c1}->{'manakai:private'} = 1;
  return $c1;
} # b5_chr

{
  my $path = $ThisPath->child ('inherited-tables.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %$json) {
    for my $item (@{$json->{$key}}) {
      my $c1 = sprintf ':inherited-%s', chr $item->{u}->[0];
      my $key = get_vkey chr $item->{u}->[0];
      for (@{$item->{b} or []}) {
        my $c2 = b5_chr $_;
        $Data->{$key}->{$c1}->{$c2}->{'inherited:Big5'} = 1;
      }
      for (@{$item->{u} or []}) {
        my $c2 = u_chr $_;
        $Data->{$key}->{$c1}->{$c2}->{'inherited:Unicode'} = 1;
      }
    }
  }
}

if (0) {
  my $path = $TempADPath->child ('BabelStoneHan-dump.json');
  my $json = json_bytes2perl $path->slurp;
  my $gid_to_codes = {};
  for my $code (keys %{$json->{cmap}->[0]->{glyphIndexMap}}) {
    $gid_to_codes->{$json->{cmap}->[0]->{glyphIndexMap}->{$code}}->{$code} = 1;
  }
  my @gsub;
  for (map { @{$_->[1]} } grep { $_->[0] eq "liga" } @{$json->{gsubFeatures}}) {
    for my $st (@{$json->{gsubLookups}->[$_]}) {
      if ($st->{coverage} and $st->{ligatureSets}) {
        my @glyph;
        if ($st->{coverage}->{glyphs}) {
          @glyph = @{$st->{coverage}->{glyphs}};
        } elsif ($st->{coverage}->{ranges}) {
          for (@{$st->{coverage}->{ranges}}) {
            push @glyph, $_->{start} .. $_->{end};
          }
        } else {
          die;
        }
        for my $index (0..$#glyph) {
          my $cid = $glyph[$index];
          for my $lig (@{$st->{ligatureSets}->[$index]}) {
            push @gsub, [[$cid, @{$lig->{components}}] => [$lig->{ligGlyph}]];
          }
        }
      } elsif ($st->{coverage} and defined $st->{deltaGlyphId}) {
        my @glyph;
        if ($st->{coverage}->{glyphs}) {
          @glyph = @{$st->{coverage}->{glyphs}};
        } elsif ($st->{coverage}->{ranges}) {
          for (@{$st->{coverage}->{ranges}}) {
            push @glyph, $_->{start} .. $_->{end};
          }
        } else {
          die;
        }
        for my $index (0..$#glyph) {
          my $cid1 = $glyph[$index];
          push @gsub, [[$cid1] => [$cid1 + $st->{deltaGlyphId}]];
        }
      } elsif ($st->{coverage} and $st->{substitute}) {
        my @glyph;
        if ($st->{coverage}->{glyphs}) {
          @glyph = @{$st->{coverage}->{glyphs}};
        } elsif ($st->{coverage}->{ranges}) {
          for (@{$st->{coverage}->{ranges}}) {
            push @glyph, $_->{start} .. $_->{end};
          }
        } else {
          die;
        }
        for my $index (0..$#glyph) {
          push @gsub, [[$glyph[$index]] => [$st->{substitute}->[$index]]];
        }
      } elsif ($st->{coverage} and $st->{alternateSets}) {
        for my $index (0..$#{$st->{coverage}->{glyphs}}) {
          my $cid1 = $st->{coverage}->{glyphs}->[$index];
          for my $cid2 (@{$st->{alternateSets}->[$index]}) {
            push @gsub, [[$cid1] => [$cid2]];
          }
        }
      }
    }
  } # liga
  my $to_char = sub {
    my $in = shift;
    my @c = ([]);
    for my $gid (@$in) {
      if (keys %{$gid_to_codes->{$gid} or {}}) {
        my @d;
        for my $code (keys %{$gid_to_codes->{$gid} or {}}) {
          push @d, map { [@$_, sprintf 'U+%04X', $code] } @c;
        }
        @c = @d;
      } else {
        @c = map { [@$_, 'XX'.'X' . $gid] } @c;
      }
    }
    return @c;
  }; # $to_char
  for my $gsub (@gsub) {
    my @c1 = $to_char->($gsub->[0]);
    my @c2 = $to_char->($gsub->[1]);
    for my $c1 (@c1) {
      my $key = get_vkey $c1;
      for my $c2 (@c2) {
        #warn "@$c1 => @$c2";
        #warn "@$c1 \n";
        #$Data->{$key}->{$c1}->{$c2}->{...} = 1;
      }
    }
  }
}

write_rel_data_sets
    $Data => $ThisPath, 'maps',
    [
    ];

## License: Public Domain.

