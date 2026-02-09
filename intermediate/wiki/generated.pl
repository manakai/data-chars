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
my $Types = {};

{
  my $UnicodeRelTypes = {
    # uni
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
    Uv => 'uax44:vertical',
    Uh1 => 'uax44:horizontal',
    Uh2 => 'uax44:horizontal',
    "18030-2022" => 'gb18030:2022:glyph',
  };
  my $FontCharPatterns = {
    # uni
    klee => ':u-klee-%x',
    kleev => ':u-klee-%xv',
    GL1 => ':u-gl1-%x',
    GL2 => ':u-gl2-%x',
    GL3 => ':u-gl3-%x',
    GL4 => ':u-gl4-%x',
    GL5 => ':u-gl5-%x',
    GL1v => ':u-gl1-%xv',
    GL2v => ':u-gl2-%xv',
    GL3v => ':u-gl3-%xv',
    GL4v => ':u-gl4-%xv',
    GL5v => ':u-gl5-%xv',
    shs => ':u-haranom-%x',
    shsv => ':u-haranom-%xv',
    shg => ':u-haranog-%x',
    shgv => ':u-haranog-%xv',
    twkana => ':u-twkana-%x',
    shokaki => ':u-shokaki-%x',
    notohentai => ':u-notohentai-%x',
    bsh => ':u-babel-%x',
    bshv => ':u-babel-%xv',

    # ucs
    ipa1 => ':u-ipa1-%x',
    ipa1v => ':u-ipa1-%xv',
    ipa3 => ':u-ipa3-%x',
    ipa3v => ':u-ipa3-%xv',
    ex => ':u-ipaex-%x',
    exv => ':u-ipaex-%xv',
    mj => ':u-mj-%x',
    mjv => ':u-mj-%xv',

    # pua
    glnm => ':u-glnm-%x',
    glnmv => ':u-glnm-%xv',
    dakuten => ':u-dakuten-%x',
    dakutenv => ':u-dakuten-%xv',
    nishikiteki => ':u-nishikiteki-%x',
    antenna => ':u-antenna-%x',
    jitaichou => ':u-jitaichou-%x',
    woshite => ':u-woshite-%x',
    hotukk => ':u-hotukk-%x',
    hotuma101 => ':u-hotuma101-%x',
    'ahiru-tate' => ':u-ahirutate-%x',
    'ahiru-yoko' => ':u-ahiruyoko-%x',
    ajichi => ':u-ajichi-%x',
    ajitiMohitu => ':u-ajitimohitu-%x',
    koretari => ':u-koretari-%x',
    katakamna => ':u-katakamna-%x',
  };
my $ScriptFeatList = [qw(
  HIRA KATA
  KRTR KNNA MRTN AHIR HTMA TNKS AWAM KIBK
  KTDM ANIT TYKN TYKO HSMI IZMO KIBI TATU AHKS NKTM IRHO NANC UMAS TUSM
  KAMI RUKU HNDE TAYM MROK
  OCRF
)]; 

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
    my $non_han = $_->[1] ne 'hans';
  
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
      my $uc;
      my $feats = [];
      G: for my $group (@$group_list) {
        my $matched = 0;
        for (sort { $a cmp $b } keys %{$group->{uni}->{ref} or {}}) {
          $uc = chr hex $_;
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{voiced}->{ref} or {}}) {
          $uc = chr hex $_;
          $uc .= "\x{3099}";
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{semivoiced}->{ref} or {}}) {
          $uc = chr hex $_;
          $uc .= "\x{309A}";
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{uni}->{refv} or {}}) {
          $uc = chr hex $_;
          push @$feats, 'vert';
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{voiced}->{refv} or {}}) {
          $uc = chr hex $_;
          $uc .= "\x{3099}";
          push @$feats, 'vert';
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{semivoiced}->{refv} or {}}) {
          $uc = chr hex $_;
          $uc .= "\x{309A}";
          push @$feats, 'vert';
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{uni}->{refsmall} or {}}) {
          $uc = chr hex $_;
          push @$feats, 'SMAL';
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{voiced}->{refsmall} or {}}) {
          $uc = chr hex $_;
          $uc .= "\x{3099}";
          push @$feats, 'SMAL';
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{semivoiced}->{refsmall} or {}}) {
          $uc = chr hex $_;
          $uc .= "\x{309A}";
          push @$feats, 'SMAL';
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{uni}->{refsmallv} or {}}) {
          $uc = chr hex $_;
          push @$feats, 'SMAL', 'vert';
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{voiced}->{refsmallv} or {}}) {
          $uc = chr hex $_;
          $uc .= "\x{3099}";
          push @$feats, 'SMAL', 'vert';
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{semivoiced}->{refsmallv} or {}}) {
          $uc = chr hex $_;
          $uc .= "\x{309A}";
          push @$feats, 'SMAL', 'vert';
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{circled}->{ref} or {}}) {
          $uc = chr hex $_;
          $uc .= "\x{20DD}";
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{squared}->{ref} or {}}) {
          $uc = chr hex $_;
          $uc .= "\x{20DE}";
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{SQAR}->{''} or {}}) {
          $uc = $_;
          push @$feats, 'SQAR';
          $matched = 1;
        }
        for (sort { $a cmp $b } keys %{$group->{SQAR}->{v} or {}}) {
          $uc = $_;
          push @$feats, 'SQAR', 'vert';
          $matched = 1;
        }
        for my $k1 (qw(
          KMOD MKRT MKRM MKRB MKCB MKLB MKLM MKLT MKCT MKCM
        ), @$ScriptFeatList) {
          for my $k2 (keys %{$group->{$k1}}) {
            for (sort { $a cmp $b } keys %{$group->{$k1}->{$k2}}) {
              $uc = $_;
              if ($k2 =~ /^[0-9]+$/) {
                push @$feats, $k1 . $k2;
              } elsif ($k2 =~ /^([0-9]+)v$/) {
                push @$feats, $k1 . $1, 'vert';
              } elsif ($k2 =~ /^([A-Z]{4})([0-9]+)$/) {
                push @$feats, $k1.$2, $1;
              } elsif ($k2 =~ /^([A-Z]{4})([0-9]+)v$/) {
                push @$feats, $k1, $1.$2, 'vert';
              } elsif ($k2 =~ /^([0-9]+)([A-Z]{4})([0-9]+)$/) {
                push @$feats, $k1.$1, $2.$3;
              } else {
                die $k2;
              }
              $matched = 1;
            }
          }
        }
        for my $k1 (qw(
          LARG SMSM WHIT SANB
          vrt2
        )) {
          for my $k2 (keys %{$group->{$k1}}) { # index or ""
            for (sort { $a cmp $b } keys %{$group->{$k1}->{$k2}}) {
              $uc = $_;
              if (length $k2) {
                push @$feats, $k2, $k1;
              } else {
                push @$feats, $k1;
              }
              $matched = 1;
            }
          }
        }
        last G if $matched;
        
        for my $k1 (grep { /^(?:ucs|uni|voiced|semivoiced)/ } sort { $a cmp $b } keys %{$group}) {
          for my $k2 (sort { $a cmp $b } keys %{$group->{$k1}}) {
            for (sort { $a cmp $b } keys %{$group->{$k1}->{$k2}}) {
              $uc = chr hex $_;
              $uc .= "\x{3099}" if $k1 eq 'voiced';
              $uc .= "\x{309A}" if $k1 eq 'semivoiced';
              last G;
            }
          }
        }
      } # G
      my $c0 = $uc;
      if (defined $c0) {
        my @f;
        my $cp = $c0;
        for (@$feats) {
          push @f, $_;
          $c0 = sprintf ':u-swk-%s%s',
              (join '-', map { sprintf '%x', ord $_ } split //, $uc),
              (join '', map { "-$_" } @f);
          
          my $type = 'swk:' . (substr $_, 0, 4);
          $type .= ':' . substr $_, 4 if 4 < length $_;
          $Types->{$type} = 1;
          $Data->{$key}->{$cp}->{$c0}->{$type} = 1;

          $cp = $c0;
        }

        my $cx = $c0;
        if (@$feats and {SQAR => 1}->{$feats->[0]}) {
          $cx =~ s/[○●□■❑‥∴∵\(\)\x{20DD}\x{20DE}\x{25A2}]//g;
          unless ($cx eq $c0) {
            $Data->{$key}->{$cx}->{$c0}->{'manakai:related'} = 1;
          }
        }
        
        if (1 < length $c0) {
          for my $c2 (split //, $cx) {
            $Data->{components}->{$c0}->{$c2}->{'string:contains'} = 1;
          }
        }
      }
      
      my $prev_group_c;
      for my $group (@$group_list) {
        my @c1;
        my @cx;

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
          for my $k2 (sort { $a cmp $b } keys %{$group->{$k1}}) {
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
              push @cx, [$c1, $rel_type.':equiv', $rel_type.':similar'];
            }
          }
        } # ucs*
        for my $k1 ('ucs', 'uni') {
          for my $k2 (sort { $a cmp $b } keys %{$group->{$k1}}) {
            my $rel_type = $UnicodeRelTypes->{$k2};
            next unless defined $rel_type;

            my $eq_type = $rel_type.':equiv';
            my $sm_type = $rel_type.':similar';
            s/:X:/:u:/ for $eq_type, $sm_type;

            for (keys %{$group->{$k1}->{$k2} or {}}) {
              my $c1 = chr hex $_;
              push @cx, [$c1, $eq_type, $sm_type];
            }
          } # $k2
        } # $k1
        
        unless ($group->{tags}->{''}->{nofont} or
                $group->{tags}->{''}->{p}) {
          my $tags = [grep { /^[a-z]+[0-9]+$/ } keys %{$group->{tags}->{''}}];
          if (defined $c0 and @$tags) {
            my $tt = join '', map { '-' . $_ } sort { $a cmp $b } @$tags;
            my $c1 = sprintf ':u-swk-%s%s%s',
                (join '-', map { sprintf '%x', ord $_ } split //, $uc),
                (join '', map { "-$_" } @$feats),
                $tt;
            my $type = 'swk:' . $tt;
            $type =~ s/^swk:-/swk:/g;
            $Types->{$type} = 1;
            $Data->{$key}->{$c0}->{$c1}->{$type} = 1;
            push @c1, $c1;
            if ($c1 =~ /-SMAL/) {
              for my $tag2 (qw(
                vert vrt2 WDRT WDLT
              ),
              'SMLB', 'SMCB', 'SMRB', 'SMLM', 'SMCM', 'SMRM', 'SMLT', 'SMCT',
              'SMRT', 'SMPB', 'SMPM', 'SMPT', 'SMLP', 'SMCP', 'SMRP',
              ) {
                next if $tt =~ /-\Q$tag2\E/;
                my $c2 = sprintf ':u-swk-%s%s%s',
                    (join '-', map { sprintf '%x', ord $_ } split //, $uc),
                    (join '', map { "-$_" } sort { $a cmp $b } @$feats, $tag2),
                    (join '', map { '-' . $_ } sort { $a cmp $b } @$tags);
                my $type = 'swk:' . $tag2;
                $Types->{$type} = 1;
                $Data->{$key}->{$c1}->{$c2}->{$type} = 1;
                for my $tag3 (qw(SMLO SMLQ)) {
                  next if $tag2 eq 'SMCM' or $tag2 =~ /v|WD/;
                  my $c3 = sprintf ':u-swk-%s%s%s',
                      (join '-', map { sprintf '%x', ord $_ } split //, $uc),
                      (join '', map { "-$_" } sort { $a cmp $b } @$feats, $tag2, $tag3),
                      (join '', map { '-' . $_ } sort { $a cmp $b } @$tags);
                  my $type = 'swk:' . $tag3;
                  $Types->{$type} = 1;
                  $Data->{$key}->{$c2}->{$c3}->{$type} = 1;
                }
              }
            }
          } elsif (defined $c0) {
            push @c1, $c0;
          }

          if (keys %{$group->{ocrhh}->{''} or {}}) {
            my $c1 = sprintf ':u-swk-%s%s',
                (join '-', map { sprintf '%x', ord $_ } split //, $uc),
                (join '', map { "-$_" } @$feats, 'OCRF0'),
            ;
            my $type = 'swk:OCRF:0';
            $type =~ s/^swk:-/swk:/g;
            $Types->{$type} = 1;
            $Data->{$key}->{$c0}->{$c1}->{$type} = 1;
          }
          if (keys %{$group->{ocrk}->{''} or {}}) {
            my $c1 = sprintf ':u-swk-%s%s',
                (join '-', map { sprintf '%x', ord $_ } split //, $uc),
                (join '', map { "-$_" } @$feats, 'OCRF0'),
            ;
            my $type = 'swk:OCRF:0';
            $type =~ s/^swk:-/swk:/g;
            $Types->{$type} = 1;
            $Data->{$key}->{$c0}->{$c1}->{$type} = 1;
          }
          if (keys %{$group->{ocrhk}->{''} or {}}) {
            my $c1 = sprintf ':u-swk-%s%s',
                (join '-', map { sprintf '%x', ord $_ } split //, $uc),
                (join '', map { "-$_" } @$feats, 'OCRF0'),
            ;
            my $type = 'swk:OCRF:1';
            $type =~ s/^swk:-/swk:/g;
            $Types->{$type} = 1;
            $Data->{$key}->{$c0}->{$c1}->{$type} = 1;
          }
        } # ! nofonts
        for (sort { $a cmp $b } keys %{$group->{mj}->{''} or {}}) {
          push @c1, ':' . $_;
        }
        for (sort { $a cmp $b } keys %{$group->{aj}->{shs} or {}}) {
          my $x = $_;
          $x =~ s/^aj/aj-shs-/;
          push @c1, ':' . $x;
        }
        for (sort { $a cmp $b } keys %{$group->{cns}->{kai} or {}}) {
          push @c1, ':cns-kai-' . $_;
        }
        for (sort { $a cmp $b } keys %{$group->{cns}->{sung} or {}}) {
          push @c1, ':cns-sung-' . $_;
        }
        for (sort { $a cmp $b } keys %{$group->{gw}->{''} or {}}) {
          push @c1, ':gw-' . $_;
        }
        for (sort { $a cmp $b } keys %{$group->{g}->{''} or {}}) {
          push @c1, ':sw' . $_; # :swg{d}
        }
        for (sort { $a cmp $b } keys %{$group->{g}->{eg} or {}}) {
          push @c1, ':sw' . $_; # :sweg{d}
        }
        for my $k1 ('ucs', 'uni', 'pua', 'voiced', 'semivoiced') {
          for my $k2 (keys %{$group->{$k1}}) {
            my $pattern = $FontCharPatterns->{$k2};
            next unless defined $pattern;
            for (keys %{$group->{$k1}->{$k2} or {}}) {
              my $c3 = u_chr hex $_;
              my $c1 = sprintf $pattern, hex $_;
              if ($k1 eq 'voiced') {
                $c3 .= "\x{3099}";
                $c1 .= sprintf $pattern, 0x3099;
              } elsif ($k1 eq 'semivoiced') {
                $c3 .= "\x{309A}";
                $c1 .= sprintf $pattern, 0x309A;
              }
              push @c1, $c1;
              if (is_private $c3 or $c3 =~ /^:u/) {
                $Data->{$key}->{$c3}->{$c1}->{'manakai:private'} = 1;
              } else {
                $Data->{$key}->{$c1}->{$c3}->{'manakai:implements'} = 1;
              }
            }
          } # $k2
        } # $k1
        for (sort { $a cmp $b } keys %{$group->{jis}->{24} or {}}) {
          push @c1, ':jis-dot124-' . $_;
        }
        for (sort { $a cmp $b } keys %{$group->{jis}->{16} or {}}) {
          push @c1, ':jis-dot16-' . $_;
        }
        for (sort { $a cmp $b } keys %{$group->{jis}->{"24v"} or {}}) {
          push @c1, ':jis-dot24v-' . $_;
        }
        for (sort { $a cmp $b } keys %{$group->{jis}->{"16v"} or {}}) {
          push @c1, ':jis-dot16v-' . $_;
        }
        for (sort { $a cmp $b } keys %{$group->{jis}->{kjis} or {}}) {
          push @c1, ':jis-kjis-' . $_;
        }
        for (sort { $a cmp $b } keys %{$group->{jis}->{kami} or {}}) {
          my $c1 = ':jis-tcm-' . $_;
          my $c3 = ':jis' . $_;
          $Data->{$key}->{$c3}->{$c1}->{'manakai:private'} = 1;
          push @c1, $c1;
        }
        for my $key (qw(heisei aj am)) {
          for (sort { $a cmp $b } keys %{$group->{$key}->{''} or {}}) {
            push @c1, ':' . $_;
          }
        }
        for my $x (sort { $a cmp $b } keys %{$group->{kami} or {}}) {
          for my $y (sort { $a cmp $b } keys %{$group->{kami}->{$x}}) {
            my $k2 = $x;
            $k2 =~ s/^tf-//;
            my $c1 = sprintf ':jisx0201-tcm%s-%x', $k2, $y;
            my $c3 = sprintf ':jisx0201-%x', $y;
            push @c1, $c1;
            $Data->{$key}->{$c3}->{$c1}->{'manakai:private'} = 1;
          }
        }
        for my $x (sort { $a cmp $b } keys %{$group->{arib} or {}}) {
          for my $y (sort { $a cmp $b } keys %{$group->{arib}->{$x}}) {
            push @c1, sprintf ':arib-%x-%x', $x, $y;
          }
        }
        for my $x (sort { $a cmp $b } keys %{$group->{tron} or {}}) {
          for my $y (sort { $a cmp $b } keys %{$group->{tron}->{$x}}) {
            push @c1, sprintf ':tron%d-%x', $x, $y;
          }
        }
        for (sort { $a cmp $b } keys %{$group->{jisrev}->{''} or {}}) {
          push @c1, ':jis-pubrev-' . $_;
        }
        for my $key (qw(juki)) {
          for (sort { $a cmp $b } keys %{$group->{$key}->{''} or {}}) {
            push @c1, sprintf ':u-%s-%x', $key, $_;
          }
        }
        for my $key (qw(jisx0201)) {
          for (sort { $a cmp $b } keys %{$group->{$key}->{''} or {}}) {
            push @c1, sprintf ':%s-%x', $key, $_;
          }
        }
        for my $key (qw(irg2021)) {
          for (sort { $a cmp $b } keys %{$group->{$key}->{''} or {}}) {
            push @c1, sprintf ':%s-%d', $key, $_;
          }
        }
        for my $key (qw(koseki touki)) {
          for (sort { $a cmp $b } keys %{$group->{$key}->{''} or {}}) {
            push @c1, sprintf ':%s%d', $key, $_;
          }
        }
        for my $key (qw(ocrhh jistype m33 inherited UTC UCI)) {
          for (sort { $a cmp $b } keys %{$group->{$key}->{''} or {}}) {
            push @c1, ':'.({
              m33 => 'meiji33',
            }->{$key} // $key).'-' . $_; # string
          }
        }
        for my $key (qw(jisfusai)) {
          for (sort { $a cmp $b } keys %{$group->{$key}->{''} or {}}) {
            push @c1, sprintf ':%s%s', $key, $_;
          }
        }
        for (sort { $a cmp $b } keys %{$group->{jistype}->{simplified} or {}}) {
          push @c1, sprintf':jistype-simplified-%s', $_;
        }
        for (sort { $a cmp $b } keys %{$group->{gb}->{''} or {}}) {
          if (/^20-/ or /^1-93-/) { # GK
            push @c1, ':gb' . $_;
          }
        }
        for (sort { $a cmp $b } keys %{$group->{ks}->{''} or {}}) {
          push @c1, ':ks' . $_;
        }
        for (sort { $a cmp $b } keys %{$group->{m}->{''} or {}}) {
          push @c1, ':m' . $_;
        }
        for my $c (keys %{$group->{jouyou}->{kyoyou} or {}}) {
          my $jouyou = $Jouyou->{$c} or die $_;
          my $c1 = sprintf ':jouyou-h22kyoyou-%d', $jouyou;
          die "Bad glyph for |$c1| (@c1)" unless @c1 and $c1[0] =~ /^:MJ/;
          push @cx, [$c1, 'manakai:hasglyph', undef];
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
            my $c1 = $JA2Char->{$jis} // die $jis;
            #$c1 = ':jis' . $jis if not defined $c1;
            die "Bad JA |$jis|" unless defined $c1;
            push @cx, [$c1, $rel_type.':equiv', $rel_type.':similar'];
          }
        } # jis
        if ($non_han) {
          for (sort { $a cmp $b } keys %{$group->{jis}->{'1978ir'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jisx0208:1978:glyph', undef];
          }
          for (sort { $a cmp $b } keys %{$group->{jis}->{'1983ir'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jisx0208:1983:glyph', undef];
          }
          for (sort { $a cmp $b } keys %{$group->{jis}->{'1990ir'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jis:1990:glyph', undef];
          }
          for (sort { $a cmp $b } keys %{$group->{jis}->{'2000t'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jisx0213:2000:glyph', undef];
          }
          for (sort { $a cmp $b } keys %{$group->{jis}->{'2000ir'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jisx0213:ir:glyph', undef];
          }
          # 2000 2004ir
          for (sort { $a cmp $b } keys %{$group->{jis}->{'1997v'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jisx0208:1997:vert', undef];
          }
          for (sort { $a cmp $b } keys %{$group->{jis}->{'2000g1v'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jisx0213:2000:vert', undef];
          }
          for (sort { $a cmp $b } keys %{$group->{jis}->{'2000g2'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jisx0213:2000:vert', undef];
          }
          for (sort { $a cmp $b } keys %{$group->{jis}->{'2000g2v'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jisx0213:2000:vert', undef];
          }
          for (sort { $a cmp $b } keys %{$group->{jis}->{'2000g3v'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jisx0213:2000:vert', undef];
          }
          for (sort { $a cmp $b } keys %{$group->{jis}->{'2000g4v'} or {}}) {
            push @cx, [':jis' . $_, 'manakai:equivglyph:jisx0213:2000:vert', undef];
          }
        }
        if (@c1) {
          my $c1 = shift @c1;
          for my $c2 (@c1) {
            $Data->{$key}->{$c2}->{$c1}->{'manakai:equivglyph'} = 1;
          }
          for my $cx (@cx) {
            $Data->{$key}->{$cx->[0] // die "1: @$cx"}->{$c1}->{$cx->[1] // die 3} = 1;
          }
          if (defined $prev_group_c) {
            $Data->{$key}->{$prev_group_c}->{$c1}->{'manakai:similarglyph'} = 1;
          }
          $prev_group_c = $c1;
        } else {
          $prev_group_c //= glyph_to_char $sel->($group->{selected_similar})
              if defined $group->{selected_similar};
          if (@cx or defined $prev_group_c) {
            my $c1 = $prev_group_c // $cx[0]->[0];
            for my $cx (@cx) {
              $Data->{$key}->{$cx->[0]}->{$c1}->{$cx->[2]} = 1 if defined $cx->[2];
            }
            $prev_group_c //= $c1;
          }
        } # @c1 @cx
      } # $group
    } # $group_list
  }
}

write_rel_data_sets
    $Data => $TempPath, 'generated',
    [];

{
  my $path = $TempPath->child ('generatedreltypes.json');
  $path->spew (perl2json_bytes_for_record [sort { $a cmp $b } keys %$Types]);
}

## License: Public Domain.
