use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $Data = {};

{
  my $path = $ThisPath->child ('gmap.txt');
  for (split /\n/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/\S/) {
      my @group;
      for (split /~/, $_) {
        my @item;
        for (grep { length } split /\s+/, $_) {
          if (m{^([1])-([0-9]+)-([0-9]+):(2000ir|2000t|2004ir|2000|2004|1990ir|1990|1983ir|1983r1|1983r5|1983|1978ir|1978cor24c|1978cor24w|1978|1997a7e1a1|1997a7e1t1|1997a7e1|1997|78/1|78/4-|-78/4|-78/4X|78/4X-|78|78w|78-83|83|ipa1|ipa3|ex|1978cor24xw|1978cor24xc|1997a7e1r1|78/2-|1997a7e1r2-4|1997a7e1r7-|1997a7e1r4corc|1997a7e1r5|78/4c|78/5|1997a7e1r4corw|1997a7e1r7-|1997a7e1draft|1997a7e1r1|1997a7e1r5|1978cor1w|1978cor1c|dict78w|fdis|fdiscorw|fdiscorc)$}) {
            my $jis = sprintf '%d-%d-%d', $1, $2, $3;
            push @item, ['jis', $jis, $4];
          } elsif (/^(2)-([0-9]+)-([0-9]+):(1990|1990ir|2000ir|2000t|2000|2000corw|2000corc|fdis|fdiscorw|fdiscorc)$/) {
            my $jis = sprintf '%d-%d-%d', $1, $2, $3;
            push @item, ['jis', $jis, $4];
          } elsif (/^(10)-([0-9]+)-([0-9]+):(2000|2003|2011|2023)$/) {
            my $jis = sprintf '%d-%d-%d', $1, $2, $3;
            push @item, ['jis', $jis, 0+$4];
          } elsif (/^(10)-([0-9]+)-([0-9]+):(U52|U151|U15|U61|U62|U13)$/) {
            my $jis = sprintf '%d-%d-%d', $1, $2, $3;
            push @item, ['jis', $jis, $4];
          } elsif (/^(24|16)-([0-9]+)-([0-9]+)$/) {
            my $jis = sprintf '%d-%d-%d', 1, $2, $3;
            push @item, ['jis', $jis, $1];
          } elsif (/^U\+([0-9A-F]+)J:(1993|2000|2003|2008|2010|2011|2016|2020|2023)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucs', $ucs, 0+$2];
          } elsif (/^U\+([0-9A-F]+)([GTHUMKVS]|UK|KP|UCS2003):(1993|2000|2003|2009|2020|2023)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucs'.$2, $ucs, 0+$3];
          } elsif (/^U\+([0-9A-F]+)(T):(2008)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucs'.$2, $ucs, 0+$3];
          } elsif (/^U\+([0-9A-F]+)J:(U52|U61|U62|U13|U151|U15)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucs', $ucs, $2];
          } elsif (/^U\+([0-9A-F]+)([GTHUMKVS]|UK|KP|UCS2003):(U52|U61|U62|U9|U10|U13|U151|U15)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucs' . $2, $ucs, $3];
          } elsif (/^U\+([0-9A-F]+):(ipa1|ipa3|ex|mj|SWC)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucs', $ucs, $2];
          } elsif (/^JA-([0-9A-F]{2})([0-9A-F]{2}):(2000|2003|2011|2023)$/) {
            my $jis = sprintf '%d-%d-%d', 10, (hex $1) - 0x20, (hex $2) - 0x20;
            push @item, ['jis', $jis, 0+$3];
          } elsif (/^JA-([0-9A-F]{2})([0-9A-F]{2}):(U52)$/) {
            my $jis = sprintf '%d-%d-%d', 10, (hex $1) - 0x20, (hex $2) - 0x20;
            push @item, ['jis', $jis, $3];
          } elsif (/^(MJ[0-9]+)$/) {
            push @item, ['mj', $1, ''];
          } elsif (/^:MJ-(v0010[01])-([0-9]+)$/) {
            push @item, ['mj', 'MJ' . $2, $1];
          } elsif (/^rev(([0-9]+)-([0-9]+)-([0-9]+)(R|))$/) {
            push @item, ['jisrev', $1, ''];
          } elsif (/^(aj[1-9][0-9]*)$/) {
            push @item, ['aj', $1, ''];
          } elsif (/^(aj[1-9][0-9]*),shs$/) {
            push @item, ['aj', $1, ''];
            push @item, ['aj', $1, 'shs'];
          } elsif (/^shs([1-9][0-9]*)$/) {
            push @item, ['aj', 'aj' . $1, 'shs'];
          } elsif (/^:aj2-([1-9][0-9]*)$/) {
            push @item, ['aj2', $1, ''];
          } elsif (/^(swc[1-9][0-9]*)$/) {
            push @item, ['swc', $1, ''];
          } elsif (/^(g[1-9][0-9]*)$/) {
            push @item, ['g', $1, ''];
          } elsif (/^([a-z][0-9a-z_-]+)$/) {
            push @item, ['gw', $1, ''];
          } elsif (/^([FHIJKTA][0-9A-Z]+)$/) {
            push @item, ['heisei', $1, ''];
          } elsif (/^U\+([0-9A-F]+),U\+([0-9A-F]+)$/) {
            push @item, ['ivs', (sprintf '%04X %04X', hex $1, hex $2), ''];
          } elsif (/^U\+([0-9A-F]+),U\+([0-9A-F]+):(ipa1|ipa3|ex|mj)$/) {
            push @item, ['ivs', (sprintf '%04X %04X', hex $1, hex $2), $3];
          } elsif (/^s(\p{Han})$/) {
            push @item, ['jistype', $1, 'simplified'];
          } elsif (/^s(\p{Han}):1969$/) {
            push @item, ['jistype', $1, '1969'];
          } elsif (/^k(\p{Han})$/) {
            push @item, ['jouyou', $1, 'kyoyou'];
          } elsif (/^U\+([0-9A-F]+):(jinmei)$/) {
            my $c = chr hex $1;
            push @item, ['jinmei', $c, ''];
          } elsif (/^:(koseki|touki)([0-9]+)$/) {
            push @item, [$1, $2, ''];
          } elsif (/^:gb([0-9]+)-([0-9]+)-([0-9]+)$/) {
            push @item, ['gb', (sprintf '%d-%d-%d', $1, $2, $3), ''];
          } elsif (/^:ks([0-9]+)-([0-9]+)-([0-9]+)$/) {
            push @item, ['ks', (sprintf '%d-%d-%d', $1, $2, $3), ''];
          } elsif (/^:(UTC|UCI)-([0-9]+)$/) {
            push @item, [$1, $2, ''];
          } elsif (/^:u-juki-([0-9a-f]+)$/) {
            push @item, ['juuki', (sprintf '%04X', hex $1), ''];
          } elsif (/^:cns-(kai|sung)-([0-9]+)-([0-9]+)-([0-9]+)$/) {
            push @item, ['cns', (sprintf '%d-%d-%d', $2, $3, $4), $1];
          } elsif (/^:cns-(kai|sung)-([0-9]+)-([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/) {
            push @item, ['cns', (sprintf '%d-%d-%d', $2, -0x20 + hex $3, -0x20 + hex $4), $1];
          } elsif (/^:cns-(kai|sung)-T([0-9A-F])-([0-9A-F]{2})([0-9A-F]{2})$/) {
            push @item, ['cns', (sprintf '%d-%d-%d', hex $2, -0x20 + hex $3, -0x20 + hex $4), $1];
          } elsif (/^:inherited-(\w)$/) {
            push @item, ['inherited', $1, ''];
          } elsif (/^:m([0-9]+)$/) {
            push @item, ['m', 0+$1, ''];
          } elsif (/^:irg2021-([0-9]+)$/) {
            push @item, ['irg2021', 0+$1, ''];
          } else {
            die "Bad value |$_|";
          }
        }

        my $group = {};
        for (@item) {
          $group->{$_->[0]}->{$_->[2]}->{$_->[1]} = 1;
        }

        for (sort { $a cmp $b } keys %{$group->{mj} or {}}) {
          my $v = [sort { $a cmp $b } keys %{$group->{mj}->{$_}}]->[0];
          $group->{selected} = ['mj', $v, $_];
          last;
        }
        if (not defined $group->{selected} and
            defined $group->{aj} and
            defined $group->{aj}->{shs}) {
          $group->{selected} = ['aj', [sort { $a cmp $b }
                                       #grep { $group->{aj}->{''}->{$_} }
                                       keys %{$group->{aj}->{'shs'}}]->[0], 'shs'];
        }
        if (not defined $group->{selected} and
            defined $group->{gw}) {
          $group->{selected} = ['gw', [sort { $a cmp $b } keys %{$group->{gw}->{''}}]->[0], ''];
        }
        if (not defined $group->{selected} and
            defined $group->{g}) {
          $group->{selected} = ['g', [sort { $a cmp $b } keys %{$group->{g}->{''}}]->[0], ''];
        }
        
        if (not defined $group->{selected} and
            defined $group->{ucsT} and
            defined $group->{ucsT}->{2023}) {
          #$group->{selected} = ['ucsT', [sort { $a cmp $b } keys %{$group->{ucsT}->{2023}}]->[0], ''];
        }
        
        push @group, $group;
      }

      my $selected;
      for (@group) {
        $selected //= $_->{selected};
      }
      if (defined $selected) {
        for (@group) {
          $_->{selected_similar} = $selected if not defined $_->{selected};
        }
      }
      
      push @{$Data->{groups} ||= []}, \@group;
    } elsif (/^#/) {
      #
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
