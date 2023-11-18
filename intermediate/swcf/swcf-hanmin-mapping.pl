use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempUCPath = $RootPath->child ('local/iuc');
my $TempCNSPath = $RootPath->child ('local/icns');
my $TempVNPath = $RootPath->child ('local/ivn');
my $TempWMPath = $RootPath->child ('local/iwm');
my $TempMJPath = $RootPath->child ('local/imj');
my $TempADPath = $RootPath->child ('local/iad');

my $IVDVersion = $ENV{IVD_VERSION} || die "No |IVD_VERSION|";

sub glyph_to_category ($) {
  my $g = shift;
  if ($g =~ /^MJ[0-9]+$/) {
    return "p";
  } elsif ($g =~ /^uk[12]:[0-9]+$/) {
    return "q";
  } elsif ($g =~ /^bsh:[0-9]+$/) {
    return "q";
  } elsif ($g =~ /^shs[0-9]+$/) {
    return "r";
  } elsif ($g =~ /^akr:[0-9]+$/) {
    return "r";
  } elsif ($g =~ /^cns:[F][0-9A-F]{4}$/) {
    return "s";
  } elsif ($g =~ /^cns:2[0-9][0-9A-F]{3}$/) {
    return "s";
  } elsif ($g =~ /^cns:[0-9A-F]+$/) {
    return "r";
  } elsif ($g =~ /^nnt:[0-9]+$/) {
    return "z";
  } elsif ($g =~ /^g[0-9]+$/) {
    return "z";
  } elsif ($g =~ /^[a-z][a-z0-9_-]+$/) {
    return "z";
  } else {
    die "Bad glyph |$g|";
  }
} # glyph_to_category

sub ur ($) {
  my $ucses = shift;
  my $values = [sort { $a <=> $b } map { hex $_ } @$ucses];
  my $r = [[-100, -100]];
  for (@$values) {
    if ($_ == $r->[-1]->[1] + 1) {
      $r->[-1]->[1] = $_;
    } else {
      push @$r, [$_, $_];
    }
  }
  my $s = [];
  push @$s, shift @$r;
  while (@$r) {
    my $next = shift @$r;
    if ($next->[0] - $s->[-1]->[1] < 0xFF) {
      $s->[-1]->[1] = $next->[1];
    } else {
      push @$s, $next;
    }
  }
  shift @$s;
  return join ',', map {
    if ($_->[0] == $_->[1]) {
      sprintf '%04X', $_->[0];
    } else {
      sprintf '%04X-%04X', $_->[0], $_->[1];
    }
  } @$s;
} # ur

my $Data = {};

my $AJ = {};
my $IVS = {};
{
  my $path = $RootPath->child ('intermediate/adobe/ivd-fallback.txt');
  for (split /\n/, $path->slurp) {
    my @line = split /\t/, $_, -1;
    if (@line == 3) {
      $AJ->{$line[0]} = $line[1];
    } elsif (@line == 4) {
      $IVS->{$line[0]}->{$line[1]} = $line[2];
    }
  }
}

my $Heisei = {};
{
  my $path = $RootPath->child ('intermediate/jp/heisei-fallback.txt');
  for (split /\n/, $path->slurp) {
    my @line = split /\t/, $_, -1;
    $Heisei->{$line[0]} = $line[1];
  }
}

{
  my $path = $TempMJPath->child ('mjucssvs.txt');
  for (split /\n/, $path->slurp) {
    my @line = split /\t/, $_, -1;
    if ($line[0] =~ / /) {
      my @c = split / /, $line[0];
      $Data->{chars}->{$c[0]}->{vs}->{$c[1]} = $line[1];
    } else {
      $Data->{chars}->{$line[0]}->{default} = $line[1];
    }
  }
}

{
  my $path = $RootPath->child ('intermediate/unicode/ucsj-heisei.txt');
  for (split /\n/, $path->slurp) {
    my @line = split /\t/, $_, -1;
    if ($line[1] eq 'a' or $line[1] eq 'b') {
      if (not defined $Data->{chars}->{$line[0]}->{default}) {
        if (defined $Heisei->{$line[2]}) {
          $Data->{chars}->{$line[0]}->{default} = $Heisei->{$line[2]};
        } else {
          $Data->{_errors}->{not_found}->{$line[0]}->{default} = $line[2];
        }
      }
    }
  }
}

my $CNS = {};
my $UCNS = {};
for my $path (
  $TempCNSPath->child ('cns-0-swcf.txt'),
  $TempCNSPath->child ('cns-2-swcf.txt'),
) {
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9]+)-([0-9A-F]+)\t([0-9A-F]+)$/) {
      my $p = $1;
      my $c = hex $2;
      my $cns = sprintf '%d-%04X', $p, $c;
      my $ucs = sprintf '%04X', hex $3;
      $CNS->{$cns} = $UCNS->{$ucs} = 'cns:' . $ucs;
    } elsif (/\S/) {
      die $_;
    }
  }
}
for my $path (
  $TempCNSPath->child ('cns-15-swcf.txt'),
) {
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9]+)-([0-9A-F]+)\t([0-9A-F]+)$/) {
      my $p = $1;
      my $c = hex $2;
      my $cns = sprintf '%d-%04X', $p, $c;
      my $ucs = sprintf '%04X', hex $3;
      $CNS->{$cns} = 'cns:' . $ucs;
    } elsif (/\S/) {
      die $_;
    }
  }
}
my $HasT = {};
{
  my $path = $TempUCPath->child ('unihan-irg-t.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\tkIRG_TSource\tT([0-9A-F]+)-([0-9A-F]+)\s*$/) {
      my $ucs = sprintf '%04X', hex $1;
      $HasT->{$ucs} = 1;
      my $p = hex $2;
      my $c = hex $3;
      my $cns = sprintf '%d-%04X', $p, $c;
      if ($UCNS->{$ucs}) {
        #
      } elsif ($CNS->{$cns}) {
        $UCNS->{$ucs} = $CNS->{$cns};
      } else {
        #printf STDERR "- [CODE[U+%04X]] %d-%d-%d ([CODE[T%X-%04X]])\n",
        #    $code, $p, int ($c / 0x100) - 0x20, ($c % 0x100) - 0x20, $p, $c;
      }
    } elsif (/^U\+([0-9A-F]+)\tkIRG_TSource\tTU-/) {
      my $ucs = sprintf '%04X', hex $1;
      $HasT->{$ucs} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}
my $HasG = {};
{
  my $path = $TempUCPath->child ('unihan-irg-g.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\tkIRG_GSource\t/) {
      my $ucs = sprintf '%04X', hex $1;
      $HasG->{$ucs} = 1;
    }
  }
}
my $HasH = {};
{
  my $path = $TempUCPath->child ('unihan-irg-h.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\tkIRG_HSource\t/) {
      my $ucs = sprintf '%04X', hex $1;
      $HasH->{$ucs} = 1;
    }
  }
}
my $HasK = {};
{
  my $path = $TempUCPath->child ('unihan-irg-k.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\tkIRG_KSource\t/) {
      my $ucs = sprintf '%04X', hex $1;
      $HasK->{$ucs} = 1;
    }
  }
}
my $HasM = {};
{
  my $path = $TempUCPath->child ('unihan-irg-m.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\tkIRG_MSource\t/) {
      my $ucs = sprintf '%04X', hex $1;
      $HasM->{$ucs} = 1;
    }
  }
}
my $HasV = {};
{
  my $path = $TempUCPath->child ('unihan-irg-v.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\tkIRG_VSource\t/) {
      my $ucs = sprintf '%04X', hex $1;
      $HasV->{$ucs} = 1;
    }
  }
}

my $UK = {};
my $UUK = {};
{
  my $path = $RootPath->child ('intermediate/unicode/irgn2107r2-uk.tsv');
  for (split /\x0A/, $path->slurp) {
    if (/^(UK-[0-9]+)\t([0-9A-F]+)$/) {
      $UK->{$1} = 'uk1:' . hex $2;
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $RootPath->child ('intermediate/unicode/irgn2232r-uk.tsv');
  for (split /\x0A/, $path->slurp) {
    if (/^(UK-[0-9]+)\tU\+([0-9A-F]+)\s+/) {
      $UK->{$1} = 'uk2:' . hex $2;
    } elsif (/\S/) {
      die $_;
    }
  }
}
{
  my $path = $TempUCPath->child ('unihan-irg-uk.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\tkIRG_UKSource\t(UK-[0-9]+)$/) {
      my $ucs = sprintf '%04X', hex $1;
      $UUK->{$ucs} = $UK->{$2} or die $_;
    } elsif (/\S/) {
      die $_;
    }
  }
}

my $NNT = {};
my $UNNT = {};
{
  my $path = $TempUCPath->child ('nnt-dump.json');
  my $json = json_bytes2perl $path->slurp;
  for my $code1 (keys %{$json->{cmap}->[0]->{glyphIndexMap}}) {
    my $ucs = sprintf '%04X', $code1;
    my $gid = $json->{cmap}->[0]->{glyphIndexMap}->{$code1};
    $UNNT->{$ucs} = 'nnt:' . $gid;
    $NNT->{'gid', $gid} = $code1;
  }
  for my $lookup (@{$json->{gsubLookups}->[0]}) {
    die unless $lookup->{substFormat} == 1;
    die unless $lookup->{coverage}->{format} == 1;
    for my $i (0..$#{$lookup->{coverage}->{glyphs}}) {
      my $gid = $lookup->{coverage}->{glyphs}->[$i];
      my $lses = $lookup->{ligatureSets}->[$i];
      for my $ls (@$lses) {
        my $chars = [map { $NNT->{'gid', $_} // die } $gid, @{$ls->{components}}];
        die if @$chars != 2;
        my $new_gid = $ls->{ligGlyph};
        my $ucs1 = sprintf '%04X', $chars->[0];
        my $ucs2 = sprintf '%04X', $chars->[1];
        $Data->{chars}->{$ucs1}->{ligature}->{$ucs2} = 'nnt:' . $new_gid;
      }
    }
  }
}
{
  my $path = $RootPath->child ('intermediate/viet/ca.txt');
  for (split /\x0A/, $path->slurp_utf8) {
    if (m{^(\S)\t(\S)$}) {
      my $ucs1 = sprintf '%04X', ord $1;
      my $ucs2 = sprintf '%04X', ord $2;
      $Data->{chars}->{$ucs2}->{ligature}->{"16FF0"} = $UNNT->{$ucs1} // die "Bad nnt $ucs1";
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

my $VS2AKR = {};
{
  my $path = $TempADPath->child ('ak-vs.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^([0-9A-F]+) ([0-9A-F]+); KRName; CID\+([0-9]+)\s*$/) {
      my $ucs1 = sprintf '%04X', hex $1;
      my $ucs2 = sprintf '%04X', hex $2;
      my $cid = 0+$3;
      $Data->{chars}->{$ucs1}->{vs}->{$ucs2} = "akr:$cid";
    } elsif (/^([0-9A-F]+) ([0-9A-F]+); Standardized_Variants; CID\+([0-9]+)\s*$/) {
      my $ucs1 = sprintf '%04X', hex $1;
      my $ucs2 = sprintf '%04X', hex $2;
      my $cid = 0+$3;
      $VS2AKR->{"$ucs1 $ucs2"} = "akr:$cid";
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

my $UBSH = {};
{
  my $path = $TempADPath->child ('BabelStoneHan-dump.json');
  my $json = json_bytes2perl $path->slurp;
  my $gid_to_codes = {};
  for my $code (keys %{$json->{cmap}->[0]->{glyphIndexMap}}) {
    $gid_to_codes->{$json->{cmap}->[0]->{glyphIndexMap}->{$code}}->{$code} = 1;
  }
  $UBSH = $json->{cmap}->[0]->{glyphIndexMap};
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
          push @d, map { [@$_, sprintf '%04X', $code] } @c;
        }
        @c = @d;
      } else {
        @c = map { [@$_, 'bsh:' . $gid] } @c;
      }
    }
    return @c;
  }; # $to_char
  for my $gsub (@gsub) {
    my @cc1 = $to_char->($gsub->[0]);
    my @cc2 = $to_char->($gsub->[1]);
    for my $cc1 (@cc1) {
      my $u = join ' ', @$cc1;
      my $ucs1;
      if ($u =~ /^(2F[0-9A-F]{2}|3[4-9A-F][0-9A-F]{2}|[4-9][0-9A-F]{3}|F[9A][0-9A-F]{2}|[23][0-9A-F]{4}) (309[9A])$/) {
        $ucs1 = [$1, $2];
      } elsif ($u =~ /^(2F[0-9A-F]{2}|3[4-9A-F][0-9A-F]{2}|[4-9][0-9A-F]{3}|F[9A][0-9A-F]{2}|[23][0-9A-F]{4}) (200D) (2F[0-9A-F]{2}|3[4-9A-F][0-9A-F]{2}|[4-9][0-9A-F]{3}|F[9A][0-9A-F]{2}|[23][0-9A-F]{4})$/) {
        $ucs1 = [$1, $2, $3];
      } else {
        next;
      }
      for my $cc2 (@cc2) {
        my $glyph = join ' ', @$cc2;
        if (@$ucs1 == 2) {
          $Data->{chars}->{$ucs1->[0]}->{ligature}->{$ucs1->[1]} = $glyph;
        } elsif (@$ucs1 == 3) {
          $Data->{chars}->{$ucs1->[0]}->{zwjligature}->{$ucs1->[2]} = $glyph;
        }
      }
    }
  }
}

print STDERR "\rGW... ";
my $GW = {};
for my $path (
  $TempWMPath->child ('gwrelated.txt'),
  $TempWMPath->child ('gwalias.txt'),
  $TempWMPath->child ('gwothers.txt'),
) {
  for (split /\x0A/, $path->slurp) {
    if (/^(u([0-9a-f]+)-(g|k|u|h|m|t|kp))(?:\s|$)/) {
      my $ucs = sprintf '%04X', hex $2;
      my $code = hex $2;
      $GW->{$ucs}->{$3} = $1;
    } elsif (/^(u([0-9a-f]+))(?:\s|$)/) {
      my $ucs = sprintf '%04X', hex $2;
      $GW->{$ucs}->{''} = $1;
    } elsif (/^(z-sat([0-9]+))(?:\s|$)/) {
      $GW->{'sat', $2} = $1;
    } elsif (/^(sat_g9([0-9]+))(?:\s|$)/) {
      $GW->{'sat', $2} = $1;
    } elsif (/^(unstable-u(2e(?:bf[0-9a-f]|[cd][0-9a-f][0-9a-f]|e[0-4][0-9a-f]|e5[0-9a-d])))(?:\s|$)/) {
      my $ucs = sprintf '%04X', hex $2;
      $GW->{$ucs}->{'gidc'} = $1;
    }
  }
}

my $USAT = {};
{
  my $path = $TempUCPath->child ('unihan-irg-s.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^U\+([0-9A-F]+)\tkIRG_SSource\tSAT-([0-9]+)$/) {
      my $ucs = sprintf '%04X', hex $1;
      $USAT->{$ucs} = $GW->{'sat', $2} or die $_;
    } elsif (/\S/) {
      die $_;
    }
  }
}

print STDERR "\rIVD... ";
my $Compat2SVS = {};
my $SVS2Compat = {};
{
  my $path = $TempUCPath->child ($IVDVersion . '/IVD_Sequences.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^#/) {
      #
    } elsif (s/^([0-9A-F]+) ([0-9A-F]+);\s*//) {
      my $code1 = hex $1;
      my $code2 = hex $2;
      my $ucs1 = sprintf '%04X', $code1;
      my $ucs2 = sprintf '%04X', $code2;

      if (defined $Data->{chars}->{$ucs1}->{vs}->{$ucs2} and /^KRName; /) {
        #
      } elsif ($IVS->{$ucs1}->{$ucs2}) {
        $Data->{chars}->{$ucs1}->{vs}->{$ucs2} = $IVS->{$ucs1}->{$ucs2};
      } elsif (/^Adobe-Japan1; CID\+([0-9]+)$/) {
        if ($AJ->{$1}) {
          $Data->{chars}->{$ucs1}->{vs}->{$ucs2} = $AJ->{$1};
        } else {
          $Data->{_errors}->{not_found}->{$ucs1}->{$ucs2} = "aj$1";
        }
      } elsif (/^Hanyo-Denshi; ([A-Z0-9]+)$/) {
        if ($Heisei->{$1}) {
          $Data->{chars}->{$ucs1}->{vs}->{$ucs2} = $Heisei->{$1};
        } else {
          #$Data->{_errors}->{not_found}->{$ucs1}->{$ucs2} = $1;
          $Data->{chars}->{$ucs1}->{vs}->{$ucs2} = lc "u$ucs1-u$ucs2";
        }
      } elsif (/^Moji_Joho; (MJ[0-9]+)$/) {
        $Data->{chars}->{$ucs1}->{vs}->{$ucs2} = $1;
      } elsif (/^KRName; /) {
        $Data->{_errors}->{not_found}->{$ucs1}->{$ucs2} = 1;
      } elsif (/^MSARG; /) {
        $Data->{_errors}->{not_found}->{$ucs1}->{$ucs2} = 1;
      } else {
        die "Bad line |$_|";
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }

  {
    my $path = $RootPath->child ('local/unicode/latest/StandardizedVariants.txt');
    for (split /\x0D?\x0A/, $path->slurp) {
      if (/^#/) {
        #
      } elsif (/^([0-9A-F]+) ([0-9A-F]+);\s*([^;]+?-)([0-9A-F]+)\s*;/) {
        my $ucs1 = sprintf '%04X', hex $1;
        my $ucs2 = sprintf '%04X', hex $2;
        my $type = $3;
        my $ucs3 = sprintf '%04X', hex $4;

        $Compat2SVS->{$ucs3} = [$ucs1, $ucs2];
        $SVS2Compat->{"$ucs1 $ucs2"} = $ucs3;
      } elsif (/^([0-9A-F]+) ([0-9A-F]+);\s*CJK/) {
        die "Bad line |$_|";
      }
    }
  }
}

my @UnicodeRange = (
  0x2F00..0x2FD5, 0x3021..0x3029, 0x3038..0x303A,
  0x2E80..0x2E99, 0x2E9B..0x2EF3, 0x31C0..0x31E3,
  0x1D372..0x1D376,

  0x3400..0x4DBF, # A
  0x4E00..0x9FFF, # URO
  0xF900..0xFA6D, # compat
  0xFA70..0xFAD9, # compat
  0x20000..0x2A6DF, # B
  0x2A700..0x2B739, # C
  0x2B740..0x2B81D, # D
  0x2B820..0x2CEA1, # E
  0x2CEB0..0x2EBE0, # F
  0x2EBF0..0x2EE5D, # I
  0x2F800..0x2FA1D, # compat sup
  0x30000..0x3134A, # G
  0x31350..0x323AF, # H
);

for (@UnicodeRange) {
  my $ucs = sprintf '%04X', $_;
  if (defined $Data->{chars}->{$ucs}->{default}) {
    #
  } elsif (defined $USAT->{$ucs}) {
    $Data->{chars}->{$ucs}->{default} = $USAT->{$ucs};
  } elsif (defined $UUK->{$ucs} and not $HasT->{$ucs}) {
    $Data->{chars}->{$ucs}->{default} = $UUK->{$ucs};
  } elsif (defined $UNNT->{$ucs} and not $HasT->{$ucs} and $HasV->{$ucs}) {
    $Data->{chars}->{$ucs}->{default} = $UNNT->{$ucs};
  } elsif (defined $UCNS->{$ucs}) {
    $Data->{chars}->{$ucs}->{default} = $UCNS->{$ucs};
  } elsif (defined $UUK->{$ucs}) {
    $Data->{chars}->{$ucs}->{default} = $UUK->{$ucs};
  } elsif (defined $UNNT->{$ucs}) {
    $Data->{chars}->{$ucs}->{default} = $UNNT->{$ucs};
  }
}

{
  my $path = $RootPath->child ('intermediate/jp/jisjp90.txt');
  for (split /\n/, $path->slurp) {
    my @line = split /\t/, $_, -1;
    $Data->{chars}->{$line[0]}->{default} = $line[1];
  }
}

my $UV2SO = {};
{
  my $i = 0;
  $UV2SO->{$_} = $i++ for qw(
    1993 2000 2003 U51 U52 U61 U62 U10 U13 U15 U151 2023
  );
  
  my $path = $RootPath->child ('intermediate/misc/gmap.json');
  my $json = json_bytes2perl $path->slurp;
  my $sel = sub {
    my $x = shift;
    return undef unless defined $x;
    if ($x->[0] eq 'mj' or $x->[0] eq 'gw' or $x->[0] eq 'g') {
      return $x->[1];
    } elsif ($x->[0] eq 'aj' and $x->[2] eq 'shs') {
      my $v = $x->[1];
      $v =~ s/^aj/shs/;
      return $v;
    } else {
      return undef;
    }
  };
  for my $group (map { @$_ } @{$json->{groups}}) {
    for my $ucs (keys %{($group->{ucs} or {})->{SWC} or {}}) {
      my $glyph = $sel->($group->{selected} || $group->{selected_similar});
      if (defined $glyph) {
        $Data->{chars}->{$ucs}->{default} = $glyph;
      } elsif (keys %{$group->{ucsT}->{2023} or {}}) {
        my $glyph = $UCNS->{[sort { $a cmp $b } keys %{$group->{ucsT}->{2023}}]->[0]};
        if (defined $glyph) {
          $Data->{chars}->{$ucs}->{default} = $glyph;
        } else {
          $Data->{_errors}->{not_found}->{$ucs}->{SWC} = 1;
        }
      }
    }
  }
  for my $key (qw(ucs ucsS ucsK ucsKP ucsV ucsU ucsG ucsUK
                  ucsT ucsH ucsM ucsUCS2003)) {
    for my $group (map { @$_ } @{$json->{groups}}) {
      for my $key2 (sort {
        $UV2SO->{$b} <=> ($UV2SO->{$a} // warn "Unknown UV value |$a|");
      } grep { not {
        ipa1 => 1, ipa3 => 1, ex => 1, jinmei => 1, SWC => 1,
        2008 => 1, 2009 => 1, 2010 => 1, 2011 => 1, 2016 => 1, 2020 => 1,
      }->{$_} } keys %{($group->{$key} or {})}) {
        for my $ucs (keys %{($group->{$key} or {})->{$key2} or {}}) {
          if (not defined $Data->{chars}->{$ucs}->{default}) {
            my $glyph = $sel->($group->{selected} || $group->{selected_similar});
            $Data->{chars}->{$ucs}->{default} = $glyph if defined $glyph;
          }
        }
      }
    }
  }
}


print STDERR "\rFilling... ";
for (0x302A..0x302D, 0x16FF0, 0x16FF1) {
  my $ucs = sprintf '%04X', $_;
  $Data->{chars}->{$ucs}->{default} = $UNNT->{$ucs};
}
for my $code (@UnicodeRange) {
  my $ucs = sprintf '%04X', $code;
  if (defined $Data->{chars}->{$ucs}->{default}) {
    #
  } elsif (defined $Data->{chars}->{$ucs}->{vs} and
           defined $Data->{chars}->{$ucs}->{vs}->{"E0100"}) {
    $Data->{chars}->{$ucs}->{default} = $Data->{chars}->{$ucs}->{vs}->{E0100};
  } elsif (((0xF900 <= $code and $code <= 0xFA0B) or
            $code == 0xFA2E or $code == 0xFA2F) and
           $VS2AKR->{join ' ', @{$Compat2SVS->{$ucs} // []}}) {
    $Data->{chars}->{$ucs}->{default} = $VS2AKR->{join ' ', @{$Compat2SVS->{$ucs} // []}};
  } elsif (((0xF900 <= $code and $code <= 0xFA0B) or
            $code == 0xFA2E or $code == 0xFA2F) and
           $GW->{$ucs} and $GW->{$ucs}->{k}) {
    $Data->{chars}->{$ucs}->{default} = $GW->{$ucs}->{k};
    $Data->{_counts}->{gw_byname}++;
  } elsif (0xF90C <= $code and $code <= 0xFA2D and
           $GW->{$ucs} and $GW->{$ucs}->{u}) {
    $Data->{chars}->{$ucs}->{default} = $GW->{$ucs}->{u};
    $Data->{_counts}->{gw_byname}++;
  } elsif (0xFA70 <= $code and $code <= 0xFAD9 and
           $GW->{$ucs} and $GW->{$ucs}->{kp}) {
    $Data->{chars}->{$ucs}->{default} = $GW->{$ucs}->{kp};
    $Data->{_counts}->{gw_byname}++;
  } elsif (0x2F800 <= $code and $code <= 0x2FA1D and
           $GW->{$ucs} and $GW->{$ucs}->{t}) {
    $Data->{chars}->{$ucs}->{default} = $GW->{$ucs}->{t};
    $Data->{_counts}->{gw_byname}++;
  } elsif (0x2F800 <= $code and $code <= 0x2FA1D and
           $GW->{$ucs} and $GW->{$ucs}->{h}) {
    $Data->{chars}->{$ucs}->{default} = $GW->{$ucs}->{h};
    $Data->{_counts}->{gw_byname}++;
  } elsif ($HasG->{$ucs} and $UBSH->{$code}) {
    $Data->{chars}->{$ucs}->{default} = "bsh:" . $UBSH->{$code};
  } elsif ($HasH->{$ucs} and $GW->{$ucs} and $GW->{$ucs}->{h}) {
    $Data->{chars}->{$ucs}->{default} = $GW->{$ucs}->{h};
    $Data->{_counts}->{gw_byname}++;
  } elsif ($GW->{$ucs} and $GW->{$ucs}->{gidc}) {
    $Data->{chars}->{$ucs}->{default} = $GW->{$ucs}->{gidc};
    $Data->{_counts}->{gw_byname}++;
  } elsif ($GW->{$ucs} and $GW->{$ucs}->{k} and $HasK->{$ucs}) {
    $Data->{chars}->{$ucs}->{default} = $GW->{$ucs}->{k};
    $Data->{_counts}->{gw_byname}++;
  } elsif ($GW->{$ucs} and $GW->{$ucs}->{m} and $HasM->{$ucs}) {
    $Data->{chars}->{$ucs}->{default} = $GW->{$ucs}->{m};
    $Data->{_counts}->{gw_byname}++;
  } elsif ($GW->{$ucs} and $GW->{$ucs}->{''}) {
    $Data->{chars}->{$ucs}->{default} = $GW->{$ucs}->{''};
    $Data->{_counts}->{gw_fallback}++;
  } else {
    $Data->{_counts}->{no_glyph}++;
    $Data->{_errors}->{not_glyph}->{$ucs} = 1;
  }

  my $svs = $Compat2SVS->{$ucs};
  if (defined $svs and
      defined $Data->{chars}->{$ucs}->{default} and
      not defined $Data->{chars}->{$svs->[0]}->{vs}->{$svs->[1]}) {
    $Data->{chars}->{$svs->[0]}->{vs}->{$svs->[1]} = $Data->{chars}->{$ucs}->{default};
  }
}

{
  my $g2cs = {};
  my $cat_ucses = {};
  my $cat_combinings = {};
  my $combining_cats = {};
  L: {
    my $changed = 0;
    delete $Data->{_categories};
    $cat_ucses = {};
    $cat_combinings = {};
    for my $ucs (keys %{$Data->{chars}}) {
      my $data = $Data->{chars}->{$ucs};
      my $cats = {};
      my @glyph = (grep { defined } $data->{default},
                   values %{$data->{vs} or {}}, 
                   values %{$data->{ligature} or {}},
                   values %{$data->{zwjligature} or {}});
      for my $glyph (@glyph) {
        for my $cat (keys %{$g2cs->{$glyph} || {(glyph_to_category $glyph) => 1}}) {
          $cats->{$cat} = 1;
        }
      }
      delete $cats->{z};
      for my $cat (keys %$cats) {
        for my $glyph (@glyph) {
          $g2cs->{$glyph}->{$cat} = 1;
        }
      }
      for (keys %{$combining_cats->{$ucs} or {}}) {
        $cats->{$_} = 1;
      }
      my $old = $data->{category} || "z";
      $data->{category} = (join '', sort { $a cmp $b } keys %$cats) || "z";
      $changed = 1 if not $old eq $data->{category};
      $Data->{_categories}->{$data->{category}}++;
      
      push @{$cat_ucses->{$data->{category}} ||= []}, $ucs;
      for (keys %{$data->{ligature} or {}}) {
        $cat_combinings->{$data->{category}}->{$_} = 1;
      }
      for my $ucs (keys %{$data->{zwjligature} or {}}) {
        $cat_combinings->{$data->{category}}->{$ucs} = 1;
        $combining_cats->{$ucs}->{$_} = 1 for split //, $data->{category};
      }
      if (keys %{$data->{zwjligature} or {}}) {
        $cat_combinings->{$data->{category}}->{"200D"} = 1;
      }
    }
    redo L if $changed;
  } # L

  for my $cat (keys %$cat_combinings) {
    for my $ucs (keys %{$cat_combinings->{$cat}}) {
      $Data->{chars}->{$ucs}->{more_categories}->{$cat} = 1;
      if (not defined $Data->{chars}->{$ucs}->{default}) {
        $Data->{chars}->{$ucs}->{default} = 'u' . lc $ucs;
        $Data->{chars}->{$ucs}->{category} //= 'z';
      }
      push @{$cat_ucses->{$cat} ||= []}, $ucs;
    }
  }

  for my $code (
    0x200D,
    0x302A..0x302D,
    0x3099, 0x309A,
    0x16FF0, 0x16FF1,
  ) {
    my $ucs = sprintf '%04X', $code;
    if (defined $Data->{chars}->{$ucs}) {
      $Data->{chars}->{$ucs}->{mark} = 1;
      for my $cat (keys %{$Data->{_categories}}) {
        $Data->{chars}->{$ucs}->{more_categories}->{$cat} = 1;
        push @{$cat_ucses->{$cat} ||= []}, $ucs;
      }
    }
  }

  for my $cat (keys %$cat_ucses) {
    $Data->{ranges}->{$cat} = ur $cat_ucses->{$cat};
  }
}

print STDERR "\rWriting... ";
print perl2json_bytes_for_record $Data;
print STDERR "\rDone. \n";

## License: Public Domain.
