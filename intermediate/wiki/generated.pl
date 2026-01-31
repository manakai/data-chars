use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;
my $TempPath = $RootPath->child ('local/iwm');
my $TempUCPath = $RootPath->child ('local/iuc');

my $Data = {};
my $Type = {};

{

my $JA2Char = {};
{
  my $path = $TempUCPath->child ('unihan3.txt');
  my $file = $path->openr;
  while (<$file>) {
    if (/^U\+([0-9A-F]+)\s+(kIRG_JSource)\s+([A])-([0-9A-F]{2})([0-9A-F]{2})$/) {
      my $c1 = u_chr hex $1;
      my $jis = sprintf '%d-%d-%d', hex $3, (hex $4) - 0x20, (hex $5) - 0x20;
      $JA2Char->{$jis} = $c1;
    }
  }
  $JA2Char->{"10-6-43"} = "\x{FA1F}";
}

my $Jouyou = {};
my $JouyouOld = {};
{
  my $path = $ThisPath->parent->child ('jp/jouyouh22-table.json');
  my $json = json_bytes2perl $path->slurp;
  for my $char (keys %{$json->{jouyou}}) {
    my $in = $json->{jouyou}->{$char};
    $Jouyou->{$char} = $in->{index};
    for (@{$in->{old} or []}) {
      $JouyouOld->{$_} = $in->{index};
    }
    if ($in->{old_image}) {
      use utf8;
      $JouyouOld->{"龜"} = $in->{index};
    }
  }
}

for (
  ['gmap.json', 'hans'],
  ['kana-gmap.json', 'kanas'],
) {
  my $path = $ThisPath->parent->child ('misc/' . $_->[0]);
  my $key = 'rels'; #$_->[1];
  
  my $UnicodeRelTypes = {
    DIS12 => 'iso10646:1992:X:glyph',
    1993 => 'iso10646:1993:X:glyph',
    2000 => 'iso10646:2000:X:glyph',
    2003 => 'iso10646:2003:X:glyph',
    2008 => 'iso10646:2008:X:glyph',
    2010 => 'iso10646:2010:X:glyph',
    2020 => 'iso10646:2020:X:glyph',
    2023 => 'iso10646:2023:X:glyph',
    U2 => 'unicode2:X:glyph',
    U31 => 'unicode3.1:X:glyph',
    U32 => 'unicode3.2:X:glyph',
    U51 => 'unicode5.1:X:glyph',
    U52 => 'unicode5.2:X:glyph',
    U6 => 'unicode6:X:glyph',
    U61 => 'unicode6.1:X:glyph',
    U62 => 'unicode6.2:X:glyph',
    U9 => 'unicode9:X:glyph',
    U10 => 'unicode10:X:glyph',
    U13 => 'unicode13:X:glyph',
    U14 => 'unicode14:X:glyph',
    U15 => 'unicode15:X:glyph',
    U151 => 'unicode15.1:X:glyph',
    "18030-2022" => 'gb18030:2022:glyph',
  };
  
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
    } elsif ($x->[0] eq 'ucsT' and $x->[2] eq '') {
      return 'cns' . $x->[1];
    } else {
      die perl2json_bytes $x;
    }
  };
  for my $group_list (@{$json->{groups}}) {
    my $prev_group_c;
    for my $group (@$group_list) {
    for (
      ['jistype', 'simplified', ':jistype-simplified-%s', ''],
      ['koseki', '', ':koseki%s', ''],
      ['touki', '', ':touki%s', ''],
      ['juuki', '', ':u-juki-%x', 'x'],
      ['UTC', '', ':UTC-%s', ''],
      ['UCI', '', ':UCI-%s', ''],
    ) {
      my ($k1, $k2, $f, $cnv) = @$_;
      for (keys %{$group->{$k1}->{$k2} or {}}) {
        my $v = $_;
        $v = hex $v if $cnv eq 'x';
        my $c1 = sprintf $f, $v;
        if (defined $group->{selected}) {
          my $glyph = $sel->($group->{selected});
          my $c2 = glyph_to_char $glyph;
          $Data->{$key}->{$c1}->{$c2}->{'manakai:equivglyph'} = 1;
        } elsif (defined $group->{selected_similar}) {
          my $glyph = $sel->($group->{selected_similar});
          my $c2 = glyph_to_char $glyph;
          $Data->{$key}->{$c1}->{$c2}->{'manakai:similarglyph'} = 1;
        } else {
          #warn "No glyph for |$c1|";
        }
      }
    }
    for my $c (keys %{$group->{jouyou}->{kyoyou} or {}}) {
      my $jouyou = $Jouyou->{$c} or die $_;
      my $c1 = sprintf ':jouyou-h22kyoyou-%d', $jouyou;
      if (defined $group->{selected}) {
        my $glyph = $sel->($group->{selected});
        die "Bad glyph for |$c1| ($glyph)" unless $glyph =~ /^MJ/;
        my $c2 = glyph_to_char $glyph;
        $Data->{$key}->{$c1}->{$c2}->{'manakai:hasglyph'} = 1;
      } else {
        #warn "No glyph for |$c1|";
      }
    }
    for my $k2 (keys %{$group->{jis} or {}}) {
      for my $jis (keys %{$group->{jis}->{$k2} or {}}) {
        next unless $jis =~ /^10-/;
        next if {
          2011 => 1,
          2016 => 1,
        }->{$k2};
        my $rel_type = $UnicodeRelTypes->{$k2} // die "Bad key2 |$k2|";
        $rel_type =~ s/:X:/:j:/;
        my $c1 = $JA2Char->{$jis};
        #$c1 = ':jis' . $jis if not defined $c1;
        die "Bad JA |$jis|" unless defined $c1;
        if (defined $group->{selected}) {
          my $glyph = $sel->($group->{selected});
          my $c2 = glyph_to_char $glyph;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type.':equiv'} = 1;
        } elsif (defined $group->{selected_similar}) {
          my $glyph = $sel->($group->{selected_similar});
          my $c2 = glyph_to_char $glyph;
          $Data->{$key}->{$c1}->{$c2}->{$rel_type.':similar'} = 1;
        } else {
          #warn "No glyph for |$c1|";
        }
      }
    }
    for (
      ['ucsG', ':g:'],
      ['ucsH', ':h:'],
      ['ucsM', ':m:'],
      ['ucsT', ':t:'],
      ['ucs', ':j:'],
      ['ucsK', ':k:'],
      ['ucsKP', ':kp:'],
      ['ucsV', ':v:'],
      ['ucsU', ':u:'],
      ['ucsS', ':s:'],
      ['ucsUK', ':uk:'],
      ['ucsUCS2003', ':ucs2003:'],
    ) {
      my ($k1, $type) = @$_;
      for my $k2 (keys %{$group->{$k1}}) {
        next if {
          2011 => 1,
          2016 => 1,
          ipa1 => 1,
          ipa3 => 1,
          ipa1v => 1,
          ipa3v => 1,
          ex => 1,
          exv => 1,
          mj => 1,
          mjv => 1,
          SWC => 1,
        }->{$k2};
        my $rel_type = $UnicodeRelTypes->{$k2} // die $k2;
        $rel_type =~ s/:X:/$type/;
        for (keys %{$group->{$k1}->{$k2} or {}}) {
          my $c1 = chr hex $_;
          if (defined $group->{selected}) {
            my $glyph = $sel->($group->{selected});
            my $c2 = glyph_to_char $glyph;
            $Data->{$key}->{$c1}->{$c2}->{$rel_type.':equiv'} = 1;
          } elsif (defined $group->{selected_similar}) {
            my $glyph = $sel->($group->{selected_similar});
            my $c2 = glyph_to_char $glyph;
            $Data->{$key}->{$c1}->{$c2}->{$rel_type.':similar'} = 1;
          } else {
            #warn "No glyph for |$c1|";
          }
        }
      }
    }
    {
      my $k1 = 'uni';
      for my $k2 (keys %{$group->{$k1}}) {
        my $rel_type = $UnicodeRelTypes->{$k2};
        next unless defined $rel_type;
        $rel_type =~ s/:X:/:u:/;
        
        for (keys %{$group->{$k1}->{$k2} or {}}) {
          my $c1 = chr hex $_;
          if (defined $group->{selected}) {
            my $glyph = $sel->($group->{selected});
            my $c2 = glyph_to_char $glyph;
            $Data->{$key}->{$c1}->{$c2}->{$rel_type.':equiv'} = 1;
          } elsif (defined $group->{selected_similar}) {
            my $glyph = $sel->($group->{selected_similar});
            my $c2 = glyph_to_char $glyph;
            $Data->{$key}->{$c1}->{$c2}->{$rel_type.':similar'} = 1;
          } else {
            #warn "No glyph for |$c1|";
          }
        }
      }
    }

    my @c1;
    for (sort { $a cmp $b } keys %{$group->{mj}->{''} or {}}) {
      push @c1, ':' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{heisei}->{''} or {}}) {
      push @c1, ':' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{aj}->{''} or {}}) {
      push @c1, ':' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{aj}->{shs} or {}}) {
      my $x = $_;
      $x =~ s/^aj/aj-shs-/;
      push @c1, ':' . $x;
    }
    for (sort { $a cmp $b } keys %{$group->{gw}->{''} or {}}) {
      push @c1, ':gw-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{g}->{''} or {}}) {
      push @c1, ':sw' . $_; # :swg{d}
    }
    for (sort { $a cmp $b } keys %{$group->{jis}->{16} or {}}) {
      push @c1, ':jis-dot16-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{jis}->{24} or {}}) {
      push @c1, ':jis-dot16-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{jisrev}->{''} or {}}) {
      push @c1, ':jis-pubrev-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{cns}->{kai} or {}}) {
      push @c1, ':cns-kai-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{cns}->{sung} or {}}) {
      push @c1, ':cns-sung-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{gb}->{''} or {}}) {
      if (/^20-/ or /^1-93-/) { # GK
        push @c1, ':gb' . $_;
      }
    }
    for (sort { $a cmp $b } keys %{$group->{ks}->{''} or {}}) {
      push @c1, ':ks' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{inherited}->{''} or {}}) {
      push @c1, ':inherited-' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{m}->{''} or {}}) {
      push @c1, ':m' . $_;
    }
    for (sort { $a cmp $b } keys %{$group->{irg2021}->{''} or {}}) {
      push @c1, ':irg2021-' . $_;
    }
    next unless @c1;
    my $c1 = shift @c1;
    for my $c2 (@c1) {
      $Data->{$key}->{$c1}->{$c2}->{'manakai:equivglyph'} = 1;
    }
    if (defined $prev_group_c) {
      $Data->{$key}->{$prev_group_c}->{$c1}->{'manakai:similarglyph'} = 1;
    }
      $prev_group_c = $c1;
    } # $group
  } # $group_list
}

}

write_rel_data_sets
    $Data => $TempPath, 'generated',
    [];

## License: Public Domain.
