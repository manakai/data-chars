use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' }

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iuc');

my $Data = {};

{
  my $path = $TempPath->child ('unihan-irg-h.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_HSource)\s+H-([0-9A-F]{4})$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2";
      my $c2 = sprintf ':b5-hkscs-%x', hex $3;
      my $c2_0 = $c2;
      $c2_0 =~ s/^:b5-hkscs-/:b5-/g;
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
      $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-m.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_MSource)\s+(M[AB][12]?)-([0-9A-F]{4})$/) {
      my $c1 = u_chr hex $1;
      my $rel_type = "unihan:$2:$3";
      my $c2 = sprintf ':b5-hkscs-%x', hex $4;
      my $c2_0 = $c2;
      $c2_0 =~ s/^:b5-hkscs-/:b5-/g;
      $Data->{hans}->{$c1}->{$c2}->{$rel_type} = 1;
      $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    }
  }
}
{
  my $path = $TempPath->child ('unihan-irg-uk.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^\s*#/) {
      #
    } elsif (/^U\+([0-9A-F]+)\s+(kIRG_UKSource)\s+(UK-[0-9]+)$/) {
      my $c2 = ':' . $3;
      $Data->{hans}->{u_chr hex $1}->{$c2}->{"unihan:$2"} = 1;
    }
  }
}

for (
  [q(irgn2107r2-uk.tsv), 'uka'],
  [q(irgn2232r-uk.tsv), 'ukb'],
) {
  my $path = $ThisPath->child ($_->[0]);
  my $up = $_->[1];
  my $file = $path->openr;
  while (<$file>) {
    if (/^(UK-[0-9]+)\t(?:U\+|)([0-9A-F]{4})\t?$/) {
      my $c2 = sprintf ':u-%s-%x', $up, hex $2;
      my $c2_0 = chr hex $2;
      $Data->{hans}->{":$1"}->{$c2}->{"uk:font-code-point"} = 1;
      die "Duplicate $c2" if $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'};
      $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
    } elsif (/^(UK-[0-9]+)\t(?:U\+|)([0-9A-F]{4})\t([0-9]{2})-([0-9]{2})$/) {
      my $c2 = sprintf ':u-%s-%x', $up, hex $2;
      my $c2_0 = chr hex $2;
      my $c3 = sprintf ':gb8-%d-%d', $3, $4;
      $Data->{hans}->{":$1"}->{$c2}->{"uk:font-code-point"} = 1;
      die "Duplicate $c2" if $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'};
      $Data->{hans}->{$c2_0}->{$c2}->{'manakai:private'} = 1;
      $Data->{hans}->{":$1"}->{$c3}->{"uk:gb8"} = 1;
      # SJ/T 11239-2001
    } elsif (/\S/) {
      die $_;
    }
  }
}

{
  my $path = $TempPath->child ('USourceData.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } else {
      my @line = split /;/, $_;

      my $c1;
      if ($line[0] =~ m{^(UTC-[0-9]+)$}) {
        $c1 = ':' . $1;
      } elsif ($line[0] =~ m{^(UCI-[0-9]+)$}) {
        $c1 = ':' . $1;
      } elsif ($line[0] =~ m{^(UK-[0-9]+)$}) {
        $c1 = ':' . $1;
      } elsif (/\S/) {
        die "Bad line |$_|";
      } else {
        next;
      }

      my @c2;
      if ($line[2] =~ m{^U\+([0-9A-F]+)$}) {
        push @c2, chr hex $1;
      } elsif ($line[2] =~ m{^U\+([0-9A-F]+) U\+([0-9A-F]+)$}) {
        push @c2, chr hex $1;
        push @c2, chr hex $2;
      } elsif ($line[2] =~ m{^(UTC-[0-9]+)$}) {
        push @c2, ':' . $1;
      } elsif (length $line[2]) {
        die $line[2];
      }
      my $key = 'hans';
      if (@c2) {
        $key = get_vkey $c2[0] unless $line[0] =~ /^UTC-/;
        for my $c2 (@c2) {
          if ($line[1] =~ m{^(URO|Comp|Ext[A-Z]+)$}) {
            $Data->{$key}->{$c1}->{$c2}->{'ucd:Unicode'} = 1;
          } else {
            $Data->{$key}->{$c1}->{$c2}->{'ucd:Unicode:related'} = 1;
          }
        }
      }

      if (length $line[5]) {
        my $c5 = wrap_ids $line[5], ':utc:';
        if (not defined $c5 and $line[5] =~ /^\p{Han}{2}$/) {
          $c5 = ':utc:' . $line[5];
        }
        die $line[5] unless defined $c5;
        $Data->{idses}->{$c1}->{$c5}->{'ucd:IDS'} = 1;
      }

      for my $line (split /[:*]/, $line[6]) {
        if ($line =~ m{^WL (E[0-9A-F]{3})$}) {
          my $c6 = sprintf ':u-wl-%x', hex $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        } elsif ($line =~ m{^Adobe-Japan1 C\+([0-9]+)$}) {
          my $c6 = sprintf ':aj%d', $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        } elsif ($line =~ m{^Adobe-CNS1 C\+([0-9]+)$}) {
          my $c6 = sprintf ':ac%d', $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        } elsif ($line =~ m{^TUS U\+([0-9]+)$}) {
          my $c6 = chr hex $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        } elsif ($line =~ m{^(UTC-[0-9]+)$}) {
          my $c6 = ':' . $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        } elsif ($line =~ m{, KP1-([0-9A-F]{4}), }) {
          my $c6 = sprintf ':kps1-%x', hex $1;
          $Data->{$key}->{$c1}->{$c6}->{'ucd:source'} = 1;
        }
      }

      for my $line (split /[:]/, $line[7] // '') {
        if ($line =~ m{^(kSpoofingVariant|kSimplifiedVariant|kTraditionalVariant) U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $2;
          $Data->{$key}->{$c1}->{$c7}->{'unihan:' . $1} = 1;
        } elsif ($line =~ m{^(kSpoofingVariant|kSimplifiedVariant|kTraditionalVariant) (UTC-[0-9]+)$}) {
          my $c7 = ':' . $2;
          $Data->{$key}->{$c1}->{$c7}->{'unihan:' . $1} = 1;
        } elsif ($line =~ m{^Unifiable with U\+([0-9A-F]+)\x{2014}both are y-variants of U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $1;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:unifiable'} = 1;
          my $c8 = chr hex $2;
          $Data->{$key}->{$c1}->{$c8}->{'ucd:y-variant'} = 1;
        } elsif ($line =~ m{^U\+([0-9A-F]+) is a y-variant and U\+([0-9A-F]+) is a z-variant$}) {
          my $c7 = chr hex $1;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:unifiable'} = 1;
          my $c8 = chr hex $2;
          $Data->{$key}->{$c1}->{$c8}->{'unihan:kZVariant'} = 1;
        } elsif ($line =~ m{^Traditional form of U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $1;
          $Data->{$key}->{$c1}->{$c7}->{'unihan:kSimplifiedVariant'} = 1;
        } elsif ($line =~ m{^(Misidentification) of U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $2;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:'.$1.' of'} = 1;
        } elsif ($line =~ m{misinterpreted and (incorrect) form of (UTC-[0-9]+)}) {
          my $c7 = ':' . $2;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:'.$1.' of'} = 1;
        } elsif ($line =~ m{^(variant) of (\p{Han})$}) {
          my $c7 = $2;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:'.$1.' of'} = 1;
        } elsif ($line =~ m{^Variant of U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $1;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:variant of'} = 1;
        } elsif ($line =~ m{^(ligature) form of (\p{Han}\p{Han})$}) {
          my $c7 = $2;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:'.$1.' of'} = 1;
        } elsif ($line =~ m{^Similar to U\+([0-9A-F]+) U\+([0-9A-F]+)$}) {
          my $c7 = chr hex $1;
          my $c8 = chr hex $2;
          $Data->{$key}->{$c1}->{$c7}->{'ucd:similar'} = 1;
          $Data->{$key}->{$c1}->{$c8}->{'ucd:similar'} = 1;
        }
      } # $line[7]
    }
  }
}

print_rel_data $Data;

## License: Public Domain.
