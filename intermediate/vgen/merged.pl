use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;
my $Data = {};

my $Input;
{
  my $path = $DataPath->child ('input.json');
  $Input = json_bytes2perl $path->slurp;
}

my $Rels = {};

$Data->{cluster_levels} = [
  {key => 'SAME', label => 'Same', min_weight => 700},
  {key => 'UNIFIED', label => 'Unified', min_weight => 600},
  {key => 'EQUIV', label => 'Equivalent', min_weight => 500},
  {key => 'COVERED', label => 'Covered', min_weight => 400},
  {key => 'OVERLAP', label => 'Overlapping', min_weight => 300},
  {key => 'RELATED', label => 'Related', min_weight => 200},
  {key => 'LINKED', label => 'Linked', min_weight => 100},
];
for (0..$#{$Data->{cluster_levels}}) {
  $Data->{cluster_levels}->[$_]->{index} = $_ + 1;
}
{
  my $w = {};
  $w->{$_->{key}} = $_->{min_weight} for @{$Data->{cluster_levels}};
  sub W ($) { $w->{$_[0]} // die $_[0] }
}

my $TypeWeight = {
    "cjkvi:non-cjk/bopomofo" => -404,
    "cjkvi:non-cjk/bracketed" => -404,
    "cjkvi:non-cjk/circle" => -404,
    "cjkvi:non-cjk/katakana" => -404,
    "cjkvi:non-cjk/parenthesized" => -404,
    "cjkvi:non-cjk/square" => -404,
    "rev:cjkvi:non-cjk/bopomofo" => -404,
    "rev:cjkvi:non-cjk/bracketed" => -404,
    "rev:cjkvi:non-cjk/circle" => -404,
    "rev:cjkvi:non-cjk/katakana" => -404,
    "rev:cjkvi:non-cjk/parenthesized" => -404,
    "rev:cjkvi:non-cjk/square" => -404,
};
my $TypeMergeableWeight = {};
my $DiredTypes = [];
my $PairedTypes = [];
{
  use utf8;
  
  ## SAME: Same character by definition.  Characters are
  ## unconditionally replaceable.
  for my $vtype (
    "mj:実装したMoji_JohoコレクションIVS",
    "mj:実装したSVS",
    "mj:対応する互換漢字",
    "mj:戸籍統一文字:同一",
    "unicode:svs:cjk",
    "ivd:duplicate",
    "cjkvi:cjkvi/duplicate",
    "manakai:same",

    "adobe:vs",
  ) {
    $TypeWeight->{$vtype} = W 'SAME';
    $TypeWeight->{'rev:'.$vtype} = W 'SAME';
  }

  ## UNIFIED: Characters unified into a single abstract character in
  ## typical coded character set standards.
  for my $vtype (
    "mj:対応するUCS",
    "ivd:base",

    "unicode:canonical-decomposition",
    "ucd:Equivalent_Unified_Ideograph",
    "cjkvi:non-cjk/hangzhou-num",
    "cjkvi:non-cjk/kangxi",
    "cjkvi:non-cjk/radical",
    "cjkvi:non-cjk/strokes",
    "cjkvi:non-cjk/kanbun",

    "mj:JIS包摂規準・UCS統合規則",
    
    "unihan:kZVariant",
    "cjkvi:ucs-scs/variant",
    "manakai:unified",
    
    "unicode:canon_composition",
    "unicode:canon_decomposition",

    "unicode:svs",
    "unicode:svs:obsolete",

    "mj:X0212",
    "mj:X0213",
    "mj:X0213:2",
    "mj:実装したUCS",
    "mj:住基ネット統一文字コード",
    "mj:入管外字コード",
    "mj:入管正字コード",
    "cns:unicode",
    
    "unihan3.0:kCNS1986",
    "unihan3.0:kCNS1992",
    "unihan3.0:kGB0",
    "unihan3.0:kGB1",
    "unihan3.0:kPseudoGB1",
    "unihan3.0:kGB3",
    "unihan3.0:kGB5",
    "unihan3.0:kGB8",
    "unihan3.0:kIRG_GSource:0",
    "unihan3.0:kIRG_GSource:1",
    "unihan3.0:kIRG_GSource:3",
    "unihan3.0:kIRG_GSource:5",
    "unihan3.0:kIRG_GSource:8",
    "unihan:kIRG_GSource:0",
    "unihan:kIRG_GSource:1",
    "unihan:kIRG_GSource:3",
    "unihan:kIRG_GSource:5",
    "unihan:kIRG_GSource:8",
    "unihan3.0:kIRG_TSource",
    "unihan:kIRG_KSource",
    
    "adobe:uni",
    "adobe:uni:v",
    "adobe:uni:pro",
    "adobe:uni:x0213",
    "adobe:uni:x0213:v",
    "adobe:uni:2004",
    "adobe:uni:2004:v",
    "adobe:uni:x02132004",
    "adobe:uni:x02132004:v",
    "adobe:expt",
    "adobe:jis78",
    "adobe:jisx0212",
    "adobe:jp04",
    "adobe:jp78",
    "adobe:jp83",
    "adobe:jp90",
    "adobe:jisx0213:2000",
    "adobe:jisx0213:2004",
    "adobe:cns11643",
    "adobe:cns11643:v",

    "opentype:fwid",
    "opentype:hwid",
    "opentype:pwid",
    "opentype:qwid",
    "opentype:twid",
    "opentype:pkna",
    "opentype:ruby",
    "opentype:ljmo:contextual",
    "opentype:tjmo:contextual",
    "opentype:vjmo:contextual",
  ) {
    $TypeWeight->{$vtype} = W 'UNIFIED';
    $TypeWeight->{'rev:'.$vtype} = W 'UNIFIED';
  }
  
  ## EQUIV: Characters that are considered equivalent such that they
  ## are generally replaceable each other.
  for my $vtype (
    "mj:法務省戸籍法関連通達・通知:民一2842号通達別表 誤字俗字・正字一覧表",
    "mj:法務省戸籍法関連通達・通知:民二5202号通知別表 正字・俗字等対照表",
    
    "mj:法務省戸籍法関連通達・通知:戸籍統一文字情報 親字・正字",
    "mj:法務省戸籍法関連通達・通知:戸籍統一文字情報 親字・正字:2",
    "mj:法務省戸籍法関連通達・通知:戸籍統一文字情報 親字・正字:3",
    "mj:法務省戸籍法関連通達・通知:戸籍統一文字情報 親字・正字:4",
    "mj:法務省戸籍法関連通達・通知:戸籍統一文字情報 親字・正字:5",

    "unihan:hkglyph",

    "unihan:koreanname:variant",

    "cjkvi:koseki/variant",
    "cjkvi:x0213-x0212/variants",
    "cjkvi:x0213-x0212/variants:JIS-X-0213:2004",

    "manakai:variant:simplified",
    "manakai:variant:jpnewstyle",
    "manakai:variant:wu",
    "manakai:variant:taboo",
    "manakai:equivalent",

    "fwhw:normalize",
    "fwhw:strict_normalize",
    "kana:normalize",

    "ucd:names:discouraged",
    "ucd:names:obsoleted",
    "ucd:names:preferred",

    "opentype:zero",
    "opentype:ital",
    "opentype:vert",
    "opentype:vrt2",
    "opentype:hkna",
    "opentype:vkna",
    
    "adobe:trad",
    "opentype:trad",
    "opentype:expt",
    "opentype:hojo",
    "opentype:jp04",
    "opentype:jp78",
    "opentype:jp83",
    "opentype:nlck",
  ) {
    $TypeWeight->{$vtype} = W 'EQUIV';
    $TypeWeight->{'rev:'.$vtype} = -1;
  }

  ## COVERED: A character is replaceable by another.
  for my $vtype (
    "cjkvi:joyo/variant",
    "cjkvi:jinmei1/variant",
    "cjkvi:jinmei2/variant",
    "cjkvi:hyogai/variant",

    "cjkvi:jp-old-style",
    "cjkvi:jp-old-style:comment",
    "cjkvi:jp-old-style:compatibility",

    "cjkvi:cjkvi/pseudo-simplified",
    "cjkvi:cjkvi/variant-simplified",
    "cjkvi:hydzd/simplified",
    "cjkvi:dypytz/variant",
    "cjkvi:dypytz/variant/1956",
    "cjkvi:dypytz/variant/1986",
    "cjkvi:dypytz/variant/1988",
    "cjkvi:dypytz/variant/1993",
    "cjkvi:dypytz/variant/1997",
    
    "cjkvi:jp/borrowed",
    "cjkvi:jp/borrowed:拡張新字体",
    
    "cjkvi:cjkvi/numeric",
  ) {
    push @$DiredTypes, $vtype;
    $TypeWeight->{$vtype} = W 'COVERED';
    $TypeWeight->{'rev:'.$vtype} = -1;
    $TypeWeight->{'to1:'.$vtype} = -1,
    $TypeWeight->{'to1:rev:'.$vtype} = -1;
    $TypeWeight->{'1to1:'.$vtype} = W 'EQUIV';
  }
  for my $vtype (
    "manakai:variant:simplifiedconflicted",
    "manakai:variant:conflicted",
  ) {
    $TypeWeight->{$vtype} = W 'COVERED';
    $TypeWeight->{'rev:'.$vtype} = -1;
    $TypeMergeableWeight->{$vtype} = W 'COVERED';
  }
  
  for my $pair (
    ['unihan:kSimplifiedVariant', 'unihan:kTraditionalVariant'],
  ) {
    push @$PairedTypes, $pair;
    for my $vtype (@$pair) {
      $TypeWeight->{$vtype} = W 'COVERED';
      $TypeWeight->{'rev:'.$vtype} = -1;
      $TypeWeight->{'to1:'.$vtype} = -1;
      $TypeWeight->{'to1:rev:'.$vtype} = -1;
    }
    for my $vtype ($pair->[0]) {
      $TypeWeight->{'1to1:'.$vtype} = W 'EQUIV';
      $TypeWeight->{'nto1:'.$vtype} = -1;
      $TypeMergeableWeight->{'nto1:'.$vtype} = W 'COVERED';
    }
  }
  for my $pair (
    ['cjkvi:cjkvi/simplified', 'cjkvi:cjkvi/traditional'],
  ) {
    push @$PairedTypes, $pair;
    for my $vtype (@$pair) {
      $TypeWeight->{$vtype} = W 'COVERED';
      $TypeWeight->{'rev:'.$vtype} = -1;
      $TypeWeight->{'to1:'.$vtype} = -1;
      $TypeWeight->{'to1:rev:'.$vtype} = -1;
    }
    for my $vtype ($pair->[0]) {
      $TypeWeight->{'1to1:'.$vtype} = W 'EQUIV';
      $TypeWeight->{'nto1:'.$vtype} = -1;
    }
  }

  ## OVERLAP: Characters share many important characteristics such
  ## that there are many cases one can be replaced by another.
  for my $vtype (
    "mj:辞書類等による関連字",
    "mj:読み・字形による類推",
    
    "cjkvi:jisx0212/variant",
    "cjkvi:jisx0213/variant",
    
    "unihan:kSemanticVariant",

    "cjkvi:cjkvi/radical-split",
    "cjkvi:cjkvi/radical-variant",
    "cjkvi:cjkvi/radical-variant-simplified",
    "cjkvi:cjkvi/radical-variant-simplified:left",
    "cjkvi:cjkvi/radical-variant:bottom",
    "cjkvi:cjkvi/radical-variant:left",
    "cjkvi:cjkvi/radical-variant:partial",
    "cjkvi:cjkvi/radical-variant:right",
    "cjkvi:cjkvi/radical-variant:top",

    "manakai:variant",

    "irc:ascii-lowercase",
    "irc:rfc1459-lowercase",
    "irc:strict-rfc1459-lowercase",
    "ucd:names:lc",
    "ucd:names:lc-some",
    "ucd:names:uc",
    "ucd:names:uc-some",
    "unicode:Case_Folding",
    "unicode:Titlecase_Mapping",
    "unicode:Uppercase_Mapping",
    "unicode:Lowercase_Mapping",

    "rfc3454:B.2",
    "rfc3454:B.3",
    "rfc5051:titlecase-canonical",
    "unicode:NFKC_Casefold",
    "unicode:compat_decomposition",
    "uts46:mapping",
    
    "ucd:names:variant",
    "ucd:names:preferred-some",
    "ucd:names:prefers-some",

    "kana:h2k",
    "kana:k2h",
    "kana:large",
    "kana:small",

    "unicode5.1:Bidi_Mirroring_Glyph",
    "unicode5.1:Bidi_Mirroring_Glyph-BEST-FIT",
    "unicode:Bidi_Mirroring_Glyph",
    "unicode:Bidi_Mirroring_Glyph-BEST-FIT",
  ) {
    $TypeWeight->{$vtype} = W 'OVERLAP';
    $TypeWeight->{'rev:'.$vtype} = -1;
  }

  ## RELATED: They share some of characteristics such that in some
  ## case a character may be replaced by another.
  for my $vtype (
    "mj:法務省告示582号別表第四:一:第1順位",
    "mj:法務省告示582号別表第四:二:第1順位",
    "mj:法務省告示582号別表第四:一:第2順位",
    "mj:法務省告示582号別表第四:二:第2順位",
    
    "unihan:kSpecializedSemanticVariant",
    "cjkvi:jp/borrowed:文脈依存",
    "cjkvi:jp/borrowed:文脈依存・拡張新字体",
    
    "cjkvi:hydzd/variant",
    "cjkvi:twedu/variant",
    "cjkvi:sawndip/variant",
    "cjkvi:cjkvi/variant",
    "cjkvi:hydcd/borrowed",
    "cjkvi:variants",

    "manakai:alt",
    "manakai:related",
    "manakai:taboo",
    
    "ucd:names:transliterated",

    "opentype:ccmp",
    "opentype:ccmp:contextual",
    "opentype:dlig",
    "opentype:liga",
    "opentype:hngl",
    "opentype:sinf",
    "opentype:subs",
    "opentype:sups",
    "opentype:nalt",
    "opentype:aalt",
    "opentype:afrc",
    "opentype:dnom",
    "opentype:frac",
    "opentype:frac:contextual",
    "opentype:numr",
    "opentype:calt:contextual",
    "opentype:locl",
  ) {
    $TypeWeight->{$vtype} = W 'RELATED';
    $TypeWeight->{'rev:'.$vtype} = -1;
  }

  ## LINKED: They have some similar characteristics, but they may or
  ## may not have considered as "similar".
  for my $vtype (
    "unihan:kSpoofingVariant",
    "mj:新しいMJ文字図形名",

    "manakai:private",
    
    "ucd:names:confused",
    "ucd:names:related",
    "ucd:names:x",
    "unicode:Bidi_Paired_Bracket",
    "unicode:security:confusable",
    "unicode:security:intentional",
  ) {
    $TypeWeight->{$vtype} = W 'LINKED';
    $TypeWeight->{'rev:'.$vtype} = -1;
  }

  for my $vtype (
    "cjkvi:cjkvi/non-cognate",
  ) {
    $TypeWeight->{$vtype} = W 'LINKED';
    $TypeWeight->{'rev:'.$vtype} = -1;
    $TypeMergeableWeight->{$vtype} = W 'COVERED';
  }
  for my $vtype (
    "manakai:differentiated",
  ) {
    $TypeWeight->{$vtype} = -1;
    $TypeWeight->{'rev:'.$vtype} = -1;
    $TypeMergeableWeight->{$vtype} = W 'COVERED';
  }
  for my $vtype (
    "manakai:inset",
    "manakai:inset:original",
    "rev:manakai:inset:original",
  ) {
    $TypeWeight->{$vtype} = -1;
    $TypeMergeableWeight->{$vtype} = W 'COVERED';
  }
  for my $vtype (
    "manakai:inset:cn",
    "manakai:inset:hk",
    "manakai:inset:jp",
    "manakai:inset:jp2",
    "manakai:inset:tw",
    "manakai:inset:cn:variant",
    "manakai:inset:hk:variant",
    "manakai:inset:jp:variant",
    "manakai:inset:jp2:variant",
    "manakai:inset:tw:variant",
  ) {
    $TypeWeight->{$vtype} = -1;
  }
  $Data->{inset_mergeable_weight} = W 'COVERED';
  $Data->{min_unmergeable_weight} = W 'SAME';
  $Data->{inset_keys} = [sort { $a cmp $b } qw(cn jp jp2 tw hk)];
  for (values %$TypeMergeableWeight) {
    if ($_ < $Data->{min_unmergeable_weight}) {
      $Data->{min_unmergeable_weight} = $_;
    }
  }
}

my $HasRels = {};
my $HasRelTos = {};
my $RevRels = [];
for (
  map {
    [$_->{path}, $_->{rels_key} || 'variants',
     $_->{set_map} || {}, $_->{mv_map} || {}],
  } @{$Input->{inputs}},
) {
  my ($x, $rels_key, $setmap, $mvmap) = @$_;
  my $path = $DataPath->child ($x);
  print STDERR "\r$path...";
  my $json = json_bytes2perl $path->slurp;
  for my $c1 (keys %{$json->{$rels_key}}) {
    for my $c2 (keys %{$json->{$rels_key}->{$c1}}) {
      next if $c1 eq $c2;
      my $has = 0;
      for (keys %{$json->{$rels_key}->{$c1}->{$c2}}) {
          my $w = $TypeWeight->{$_} || 0;
          next if $w == -404;
          $Rels->{$c1}->{$c2}->{$_} = $w;
          push @$RevRels, [$c1, $c2, $_, $w];
          $HasRels->{$_}->{$c1} = 1;
          $HasRelTos->{$_}->{$c2} = 1;
          next if $w < 0;
          my $set_key = $mvmap->{$_};
          if (defined $set_key) {
            $Rels->{$c1}->{$c2}->{'manakai:inset:'.$set_key.':variant'} = 1;
            $Rels->{$c2}->{$c1}->{'manakai:inset:'.$set_key.':variant'} = 1;
          }
          $has = 1;
        }
    }
  }
  for my $set_key (keys %$setmap) {
    for my $c (keys %{$json->{sets}->{$set_key}}) {
      $Data->{sets}->{$setmap->{$set_key}}->{$c} = 1;
    }
  }
}
for my $r (@$RevRels) {
  if (exists $Rels->{$r->[1]}->{$r->[0]}->{$r->[2]}) {
    #
  } else {
    $Rels->{$r->[1]}->{$r->[0]}->{'rev:'.$r->[2]} = $r->[3];
    $HasRels->{'rev:'.$r->[2]}->{$r->[1]} = 1;
  }
} # $RevRels
for my $vtype (qw(
  cjkvi:joyo/variant
  cjkvi:jinmei1/variant
  cjkvi:jinmei2/variant
  cjkvi:hyogai/variant
  cjkvi:jp-old-style
  cjkvi:jp-old-style:comment
  cjkvi:jp-old-style:compatibility
), (map { @$_ } @$PairedTypes)) {
  for my $vtype ($vtype, 'rev:'.$vtype) {
    C1: for my $c1 (sort { $a cmp $b } keys %{$HasRels->{$vtype}}) {
      my $n = 0;
      my $c;
      for my $c2 (sort { $a cmp $b } grep { $Rels->{$c1}->{$_}->{$vtype} } keys %{$Rels->{$c1}}) {
        next C1 if ++$n > 1;
        $c = $c2;
      }
      $Rels->{$c1}->{$c}->{'to1:'.$vtype} = 1;
    }
  } # C1
}
for my $vtype (qw(
  cjkvi:joyo/variant
  cjkvi:jinmei1/variant
  cjkvi:jinmei2/variant
  cjkvi:hyogai/variant
  cjkvi:jp-old-style
  cjkvi:jp-old-style:comment
  cjkvi:jp-old-style:compatibility
)) {
  for my $c1 (sort { $a cmp $b } keys %{$HasRels->{$vtype}}) {
    for my $c2 (sort { $a cmp $b } keys %{$Rels->{$c1}}) {
      if ($Rels->{$c1}->{$c2}->{'to1:'.$vtype} and
          $Rels->{$c2}->{$c1}->{'to1:rev:'.$vtype}) {
        $Rels->{$c1}->{$c2}->{'1to1:'.$vtype} = 1;
        $Rels->{$c2}->{$c1}->{'1to1:'.$vtype} = 1;
      }
    }
  }
}
for (@$PairedTypes) {
  my ($vtype1, $vtype2) = @$_;
  for my $c1 (sort { $a cmp $b } keys %{$HasRels->{$vtype1}}) {
    for my $c2 (sort { $a cmp $b } keys %{$Rels->{$c1}}) {
      if ($Rels->{$c1}->{$c2}->{'to1:'.$vtype1} and
          $Rels->{$c2}->{$c1}->{'to1:'.$vtype2}) {
        $Rels->{$c1}->{$c2}->{'1to1:'.$vtype1} = 1;
        $Rels->{$c2}->{$c1}->{'1to1:'.$vtype1} = 1;
      } elsif ($Rels->{$c1}->{$c2}->{'to1:'.$vtype1}) {
        $Rels->{$c1}->{$c2}->{'nto1:'.$vtype1} = 1;
      }
    }
  }
}

my $HasUnmergeable = {};
{
  printf STDERR "\rRels (%d)...", 0+keys %$Rels;
  my $UnweightedTypes = {};
  for my $c1 (keys %$Rels) {
    for my $c2 (keys %{$Rels->{$c1}}) {
      my $types = $Rels->{$c1}->{$c2};
      die perl2json_bytes [$c1, $c2, $types] if $c1 eq $c2;
      $types->{_} = [sort { $b <=> $a } map {
        $TypeWeight->{$_} || do {
          $UnweightedTypes->{$_} = 1;
          0;
        };
      } keys %$types]->[0];
      $types->{_u} = [sort { $a <=> $b } map {
        $TypeMergeableWeight->{$_} || W 'SAME';
      } keys %$types]->[0];
      if ($types->{_u} != W 'SAME') {
        $HasUnmergeable->{$c1} = 1;
        $HasUnmergeable->{$c2} = 1;
      }
    }
  }

  warn "Unweighted: \n", join ("\n", sort { $a cmp $b } keys %$UnweightedTypes), "\n"
      if keys %$UnweightedTypes;
}

{
  for my $vtype (qw(
    cjkvi:jp-old-style
    cjkvi:jp-old-style:compatibility
    manakai:variant:jpnewstyle
  )) {
    for my $c1 (keys %{$HasRelTos->{$vtype}}) {
      $Data->{sets}->{"to:$vtype"}->{$c1} = 1;
    }
  }
  for my $vtype (qw(
    cjkvi:jp-old-style
  )) {
    for my $c1 (keys %{$HasRels->{$vtype}}) {
      $Data->{sets}->{"from:$vtype"}->{$c1} = 1;
    }
  }
}

for (keys %$TypeWeight) {
  $Data->{rel_types}->{$_}->{weight} = $TypeWeight->{$_};
  $Data->{rel_types}->{$_}->{mergeable_weight} = $TypeMergeableWeight->{$_} || W 'SAME';
}

{
  my $c1s = [sort { $a cmp $b } keys %$Rels];
  print STDERR "\rWrite[1]...";
  my $path = $DataPath->child ("merged-rels.jsonll");
  my $file = $path->openw;
  for my $c1 (@$c1s) {
    print $file perl2json_bytes_for_record $c1; # trailing \x0A
    print $file "\x0A";
    print $file perl2json_bytes_for_record $Rels->{$c1}; # trailing \x0A
    print $file "\x0A";
  }
}
{
  print STDERR "\rWrite[2]...";
  my $path = $DataPath->child ('merged-misc.json');
  $path->spew (perl2json_bytes_for_record $Data);
}
{
  print STDERR "\rWrite[3]...";
  my $path = $DataPath->child ('merged-chars.json');
  my $chars = {};
  for (keys %$Rels) {
    my $x = $chars->{$_} = {};
    $x->{has_unmergeable} = 1 if $HasUnmergeable->{$_};
  }
  $path->spew (perl2json_bytes_for_record $chars);
}

printf STDERR "Done (%d s)", time - $StartTime;

## License: Public Domain.
