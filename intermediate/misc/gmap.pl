use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $Data = {};

{
  my $name = shift;
  my $path = $ThisPath->child ($name);
  my $is_kana = $name =~ /kana|ryuukyuu/;
  my $ScriptFeatPattern = qr/HIRA|KATA|KRTR|KNNA|MRTN|AHIR|HTMA|KTDM|ANIT|TYKN|TYKO|HSMI|IZMO|KIBI|TATU|AHKS|NKTM|IRHO|NANC|UMAS|TUSM|TNKS|AWAM|KIBK|KAMI|RUKU|HNDE|TAYM|MROK/;
  for (split /\n/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/\S/) {
      my @group;
      for (split /~/, $_) {
        my @item;
        for (grep { length } split /\s+/, $_) {
          if (m{^([1])-([0-9]+)-([0-9]+):(2000ir|2000t|2004ir|2000|2004|1990ir|1990|1983ir|1983r1|1983r5|1983|1978ir|1978cor24c|1978cor24w|1978|1997a7e1a1|1997a7e1t1|1997a7e1|1997|78/1|78/4-|-78/4|-78/4X|78/4X-|78|78w|78-83|83|ipa1|ipa3|ex|1978cor24xw|1978cor24xc|1997a7e1r1|78/2-|1997a7e1r2-4|1997a7e1r7-|1997a7e1r4corc|1997a7e1r5|78/4c|78/5|1997a7e1r4corw|1997a7e1r7-|1997a7e1draft|1997a7e1r1|1997a7e1r5|1978cor1w|1978cor1c|dict78w|fdis|fdiscorw|fdiscorc|1997v|2000g1v|2000g2v?|2000g3v|2000g4v)$}) {
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
          } elsif (/^:jis-dot((?:16|24)v)-(1)-([0-9]+)-([0-9]+)$/) {
            my $jis = sprintf '%d-%d-%d', $2, $3, $4;
            push @item, ['jis', $jis, $1];
          } elsif (/^:jis-(arib|kjis)-([0-9]+)-([0-9]+)-([0-9]+)$/) {
            my $jis = sprintf '%d-%d-%d', $2, $3, $4;
            push @item, ['jis', $jis, $1];
          } elsif (/^(F[0-9A-Fa-f])([0-9A-Fa-f]{2}):(biblos)$/) {
            my $c1 = ((hex $1) - 0xF0) * 2 + 1;
            my $c2 = hex $2;
            $c2-- if $c2 > 0x7F;
            $c2 = $c2 - 0x40 + 1;
            if ($c2 > 94) {
              $c1++;
              $c2 -= 94;
            }
            my $jis = sprintf '%d-%d-%d', 1, $c1, $c2;
            push @item, ['jis', $jis, $3];
          } elsif (/^(kami)([89EFef][0-9A-Fa-f])([0-9A-Fa-f]{2})$/) {
            my $c1 = hex $2;
            my $c2 = hex $3;
            $c1 = $c1 >= 0xE0 ? ($c1 - 0xE0) * 2 + 63 : ($c1 - 0x81) * 2 + 1;
            $c2-- if $c2 > 0x7F;
            $c2 = $c2 - 0x40 + 1;
            if ($c2 > 94) {
              $c1++;
              $c2 -= 94;
            }
            my $jis = sprintf '%d-%d-%d', 1, $c1, $c2;
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
          } elsif (/^U\+([0-9A-F]+)J:(U52|U61|U62|U13|U151|U15|DIS12)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucs', $ucs, $2];
            ## For historical reasons, |ucs| is UCS for J column.
          } elsif (/^U\+([0-9A-F]+)([GTHUMKVS]|UK|KP|UCS2003):(U52|U61|U62|U9|U10|U13|U151|U15|DIS12)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucs' . $2, $ucs, $3];
          } elsif (/^U\+([0-9A-F]+):(ipa1v?|ipa3v?|exv?|mjv?|SWC)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucs', $ucs, $2];
          } elsif (/^U\+(F[0-9A-F]{3}):(DIS12)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucsU', $ucs, $2];
          } elsif (/^U\+([0-9A-F]+):(U2|U31|U32|18030-2022)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucsU', $ucs, $2];
          } elsif (/^U\+([0-9A-F]+):(18030-2022)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucsG', $ucs, $2];
          } elsif ($is_kana and /^U\+([0-9A-F]+):(Uv|Uh1|Uh2|U15|U6)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['ucsU', $ucs, $2];
          } elsif ($is_kana and /^U\+([0-9A-F]+):(shsv?|bshv?|kai|sung|shgv?|kleev?|notohentai|shokaki|refv?|refsmallv?|twkana)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['uni', $ucs, $2];
          } elsif (/^:u-(hannomkhai)-([0-9a-f]+)$/) {
            my $ucs = sprintf '%04X', hex $2;
            push @item, ['uni', $ucs, $1];
          } elsif (/^(GL[1-5])"(.)"(v?)$/) {
            my $ucs = sprintf '%04X', ord $2;
            push @item, ['uni', $ucs, $1.$3];
          } elsif (/^(GL1-5)"(.)"(v?)$/) {
            my $ucs = sprintf '%04X', ord $2;
            push @item, ['uni', $ucs, 'GL1'.$3];
            push @item, ['uni', $ucs, 'GL2'.$3];
            push @item, ['uni', $ucs, 'GL3'.$3];
            push @item, ['uni', $ucs, 'GL4'.$3];
            push @item, ['uni', $ucs, 'GL5'.$3];
          } elsif (/^(GL1-5)"(.)"U\+3099(v?)$/) {
            my $ucs = sprintf '%04X', ord $2;
            push @item, ['voiced', $ucs, 'GL1'.$3];
            push @item, ['voiced', $ucs, 'GL2'.$3];
            push @item, ['voiced', $ucs, 'GL3'.$3];
            push @item, ['voiced', $ucs, 'GL4'.$3];
            push @item, ['voiced', $ucs, 'GL5'.$3];
          } elsif (/^U\+([0-9A-F]+):(glnmv?|kaku|jitaichou|nishikitekiv?)$/) {
            my $ucs = sprintf '%04X', hex $1;
            push @item, ['pua', $ucs, $2];
          } elsif (/^U[+-]([0-9A-Fa-f]+):(antenna)$/) {
            push @item, ['pua', (sprintf '%08X', hex $1), $2];
          } elsif (/^(SMAL|LARG|w2|w3|w4|h2|h3|h4|bsquared|rsquared|rbsquared)<U\+([0-9A-F]+):(mj|jitaichou)>(v?)$/) {
            my $ucs = sprintf '%04X', hex $2;
            push @item, [$1.'of', $ucs, $3.$4];
          } elsif (/^(SMAL)<(GL[1-5])"(.)"(v?)>$/) {
            my $ucs = sprintf '%04X', ord $3;
            push @item, [$1.'of', $ucs, $2.$4];
          } elsif (/^(vrt2|bsquared|rsquared|rbsquared)<(eg[0-9]+)>$/) {
            push @item, [$1.'of', $2, 'eg'];
          } elsif (/^(SMAL|LARG|vrt2|bsquared|rsquared|rbsquared)<([a-z][0-9a-z_-]+)>$/) {
            push @item, [$1.'of', $2, 'gw'];
          } elsif (/^JA-([0-9A-F]{2})([0-9A-F]{2}):(2000|2003|2011|2023)$/) {
            my $jis = sprintf '%d-%d-%d', 10, (hex $1) - 0x20, (hex $2) - 0x20;
            push @item, ['jis', $jis, 0+$3];
          } elsif (/^JA-([0-9A-F]{2})([0-9A-F]{2}):(U52)$/) {
            my $jis = sprintf '%d-%d-%d', 10, (hex $1) - 0x20, (hex $2) - 0x20;
            push @item, ['jis', $jis, $3];
          } elsif (/^(MJ[0-9]+)$/) {
            push @item, ['mj', $1, ''];
          } elsif (/^(GL[0-9]+)$/) {
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
          } elsif (/^:aj-ext-([1-9][0-9]*)$/) {
            push @item, ['aj', $1, 'ext'];
          } elsif (/^:aj2-([1-9][0-9]*)$/) {
            push @item, ['aj2', $1, ''];
          } elsif (/^(am[1-9][0-9]*)$/) {
            push @item, ['am', $1, ''];
          } elsif (/^(swc[1-9][0-9]*)$/) {
            push @item, ['swc', $1, ''];
          } elsif (/^(g[1-9][0-9]*)$/) {
            push @item, ['g', $1, ''];
          } elsif (/^(eg[1-9][0-9]*)$/) {
            push @item, ['g', $1, 'eg'];
          } elsif (/^(ex[1-9][0-9]*)$/) {
            push @item, ['g', $1, 'ex'];
          } elsif (/^(:ep-[0-9a-z_-]+-[0-9a-f]+)$/) {
            push @item, ['g', $1, 'ep'];
          } elsif (/^([a-z][0-9a-z_-]+)$/) {
            push @item, ['gw', $1, ''];
          } elsif (/^([a-z][0-9a-z_-]+)\@([0-9]+)$/) {
            push @item, ['gw', $1, $2];
          } elsif (/^([FHIJKTA][0-9A-Z]+)$/) {
            push @item, ['heisei', $1, ''];
          } elsif (/^U\+([0-9A-F]+),U\+([0-9A-F]+)$/) {
            my $code2 = hex $2;
            my $key = $code2 == 0x3099 ? 'voiced' :
                $code2 == 0x309A ? 'semivoiced' : 'ivs';
            if ($key eq 'ivs') {
              push @item, [$key, (sprintf '%04X %04X', hex $1, $code2), ''];
            } else {
              push @item, [$key, (sprintf '%04X', hex $1), 'ref'];
            }
          } elsif (/^U\+([0-9A-F]+),U\+([0-9A-F]+):(ipa1|ipa3|ex|mj|notohentai)$/) {
            my $code2 = hex $2;
            my $key = $code2 == 0x3099 ? 'voiced' :
                $code2 == 0x309A ? 'semivoiced' : 'ivs';
            if ($key eq 'ivs') {
              push @item, [$key, (sprintf '%04X %04X', hex $1, $code2), $3];
            } else {
              push @item, [$key, (sprintf '%04X', hex $1), $3];
            }
          } elsif (/^U\+([0-9A-F]+),U\+3099:(refv?|refsmallv?)$/) {
            push @item, ['voiced', (sprintf '%04X', hex $1), $2];
          } elsif (/^U\+([0-9A-F]+),U\+309A:(refv?|refsmallv?)$/) {
            push @item, ['semivoiced', (sprintf '%04X', hex $1), $2];
          } elsif (/^U\+([0-9A-F]+),U\+20DD:(ref)$/) {
            push @item, ['circled', (sprintf '%04X', hex $1), $2];
          } elsif (/^s(\p{Han})$/) {
            push @item, ['jistype', $1, 'simplified'];
          } elsif (/^s(\p{Han}):1969$/) {
            push @item, ['jistype', $1, '1969'];
          } elsif (/^:jistype-(.)$/) {
            push @item, ['jistype', $1, ''];
          } elsif (/^:jisfusai([0-9]+)$/) {
            push @item, ['jisfusai', $1, ''];
          } elsif (/^:jisfusai([0-9]+)-([0-9]+)$/) {
            push @item, ['jisfusai', $1 . '-' . $2, ''];
          } elsif (/^:ninjal-([0-9]+)$/) {
            push @item, ['ninjal', $1, ''];
          } elsif (/^m33([\p{Hira}\p{Kana}])$/) {
            push @item, ['m33', $1, ''];
          } elsif (/^m33([\p{Hira}\p{Kana}])x$/) {
            push @item, ['m33', $1, 'fixed'];
          } elsif (/^k(\p{Han})$/) {
            push @item, ['jouyou', $1, 'kyoyou'];
          } elsif (/^:ocrhh-(\p{Hira}|\x{3001}|\x{3002})$/) {
            push @item, ['ocrhh', $1, ''];
          } elsif (/^U\+([0-9A-F]+):(jinmei)$/) {
            my $c = chr hex $1;
            push @item, ['jinmei', $c, ''];
          } elsif (/^:(koseki|touki)([0-9]+)$/) {
            push @item, [$1, $2, ''];
          } elsif (/^:gb([0-9]+)-([0-9]+)-([0-9]+)$/) {
            push @item, ['gb', (sprintf '%d-%d-%d', $1, $2, $3), ''];
          } elsif (/^:G([0-9]+)-([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/) {
            push @item, ['gb', (sprintf '%d-%d-%d', $1, -0x20 + hex $2, -0x20 + hex $3), ''];
          } elsif (/^:ks([0-9]+)-([0-9]+)-([0-9]+)$/) {
            push @item, ['ks', (sprintf '%d-%d-%d', $1, $2, $3), ''];
          } elsif (/^:(UTC|UCI)-([0-9]+)$/) {
            push @item, [$1, $2, ''];
          } elsif (/^:u-juki-([0-9a-f]+)$/) {
            push @item, ['juuki', (sprintf '%04X', hex $1), ''];
          } elsif (/^:u-(dakutenv?|touki)-([0-9a-f]+)$/) {
            push @item, ['pua', (sprintf '%04X', hex $2), $1];
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
          } elsif (/^:jisx0201-([0-9a-f]+)$/) {
            push @item, ['jisx0201', hex $1, ''];
          } elsif (/^:jisx0201-(ir|ocrhk|ocrk)-([0-9a-f]+)$/) {
            push @item, ['jisx0201', hex $2, $1];
          } elsif (/^:arib-([0-9a-f]+)-([0-9a-f]+)$/) {
            push @item, ['arib', hex $2, hex $1];
          } elsif (/^:tron([0-9]+)-([0-9a-f]+)$/) {
            push @item, ['tron', hex $2, hex $1];
          } elsif (/^(HIRA|KATA)([0-9]+)"([^"\x{25CB}]+)\x{25CB}"$/) {
            push @item, [$1, $3."\x{20DD}", (0+$2)];
          } elsif (/^($ScriptFeatPattern|KMOD)([0-9]+)"([^"]+)"(?:U\+([0-9A-Fa-f]+)|)(v?)$/o) {
            push @item, [$1, $3.(defined $4 ? chr hex $4 : ''), (0+$2).$5];
          } elsif (/^($ScriptFeatPattern)([0-9]+)"([^"]+)"(?:U\+([0-9A-Fa-f]+):|)(MK[LCR][TMB])([0-9]+)$/o) {
            push @item, [$1, $3.(defined $4 ? chr hex $4 : ''), (0+$2).$5.(0+$6)];
          } elsif (/^($ScriptFeatPattern)([0-9]+)"([^"]+)"U\+([0-9A-Fa-f]+),(MK[LCR][TMB])([0-9]+)$/o) {
            push @item, [$1, $3.(chr hex $4), (0+$2).$5.(0+$6)];
          } elsif (/^(MKRT)([0-9]+)"([\x{309B}\x{309C}])"(v?)$/) {
            push @item, [$1, undef, (0+$2).$4];
            my $s = $3;
            $s =~ tr/\x{309B}\x{309C}/\x{3099}\x{309A}/;
            $item[-1]->[1] = $s;
          } elsif (/^U\+([0-9A-Fa-f]+):(MK[LCR][TMB]|$ScriptFeatPattern|KMOD)([0-9]+)(v?)$/o) {
            push @item, [$2, (chr hex $1), (0+$3).$4];
          } elsif (/^U\+([0-9A-Fa-f]+):(WHIT|WDLT|WDRT)$/) {
            push @item, [$2, (chr hex $1), ''];
          } elsif (/^U\+([0-9A-Fa-f]+),U\+([0-9A-Fa-f]+),(SMAL|WHIT)$/) {
            push @item, [$3, (chr hex $1).(chr hex $2), ''];
          } elsif (/^"(.)",U\+([0-9A-Fa-f]+),SMAL$/) {
            push @item, ['SMAL', $1.(chr hex $2), ''];
          } elsif (/^U\+([0-9A-Fa-f]+),(SMAL):(HIRA|KATA)([0-9]+)(v?)$/) {
            push @item, [$3, (chr hex $1), $2.(0+$4).$5];
          } elsif (/^U\+([0-9A-Fa-f]+):(HIRA|KATA)([0-9]+),(WHIT)(v?)$/) {
            push @item, [$2, (chr hex $1), $4.(0+$3).$5];
          } elsif (/^(WHIT|LARG|SMSM)"([^"]+)"$/) {
            push @item, [$1, $2, ''];
          } elsif (/^(HIRA|KATA)([0-9]+)"([^"]+)"(SMAL|WHIT)$/) {
            push @item, [$1, $3, $4.(0+$2)];
          } elsif (/^U\+([0-9A-Fa-f]+),U\+([0-9A-Fa-f]+):(MK[LCR][TMB]|$ScriptFeatPattern|KMOD)([0-9]+)(v?)$/o) {
            push @item, [$3, (chr hex $1).(chr hex $2), (0+$4).$5];
          } elsif (/^U\+([0-9A-Fa-f]+),U\+([0-9A-Fa-f]+),U\+([0-9A-Fa-f]+):(MK[LCR][TMB]|$ScriptFeatPattern|KMOD)([0-9]+)(v?)$/o) {
            push @item, [$4, (chr hex $1).(chr hex $2).(chr hex $3), (0+$5).$6];
          } elsif (/^U\+(0020|302D),U\+(0020|302D),U\+(0020|302D),U\+([0-9A-Fa-f]+):(MK[LCR][TMB])([0-9]+)(v?)$/) {
            push @item, [$5, (chr hex $1).(chr hex $2).(chr hex $3).(chr hex $4), (0+$6).$7];
          } elsif (/^U\+([0-9A-Fa-f]+),U\+(200D|034F),U\+([0-9A-Fa-f]+):ref(v?)$/) {
            push @item, ['text', (chr hex $1).(chr hex $2).(chr hex $3), $4];
          } elsif (/^vrt2,hwid"([^"]+)"$/) {
            push @item, ['vrt2', $1, 'hwid'];
          } elsif (/^(SQAR)"([^"\x{25A2}\x{25CB}\x{25A1}]+)(?:\x{25A2}|\x{25CB}\x{25A1})"(v?)$/) {
            push @item, [$1, $2."\x{25A2}", $3];
          } elsif (/^(SQAR)"([^"\x{25A2}\x{25CB}\x{25A1}]+)(?:\x{25A1})"(v?)$/) {
            push @item, ['squared', $2, $3];
          } elsif (/^(SQAR)"([^"\x{25A2}\x{25CB}\x{25A1}]+)"(v?)$/) {
            push @item, [$1, $2, $3];
          } elsif (/^:(tf-[0-9a-z]+|TF-AHIYK|Tf-morit|tfmhisum)-([0-9a-f]{2})$/) {
            push @item, ['kami', hex $2, lc $1];
          } elsif (/^:(ahiru-tate|ahiru-yoko|koretari|katakamna|ajichi|ajitiMohitu|hotukk|hotuma101|woshite)-([0-9a-f]+)$/) {
            push @item, ['pua', (sprintf '%04X', hex $2), $1];
          } elsif (/^XX(?:)Xnoglyph$/) {
            #
          } elsif (/^%([0-9a-z]+)/) {
            push @item, ['tags', $1, ''];
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
            defined $group->{g} and defined $group->{g}->{''}) {
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
