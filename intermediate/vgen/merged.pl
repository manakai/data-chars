use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
BEGIN { require 'chars.pl' };

my $ThisPath = path (__FILE__)->parent;
my $DataPath = path ('.');
my $StartTime = time;

my $Input;
{
  my $path = $DataPath->child ('input.json');
  $Input = json_bytes2perl $path->slurp;
}

my $Data = {};
my $Sets = {};
my $Rels = {};

$Data->{key} = $Input->{key};

{
  my $levels = [
    {key => 'SAME', label => 'Same', min_weight => 700},
    {key => 'UNIFIED', label => 'Unified', min_weight => 600},
    {key => 'EQUIV', label => 'Equivalent', min_weight => 500},
    {key => 'COVERED', label => 'Covered', min_weight => 400},
    {key => 'RELATED', label => 'Related', min_weight => 200},
    {key => 'LINKED', label => 'Linked', min_weight => 100},
  ];
  my $i = 0;
  for my $level (@$levels) {
    $Data->{cluster_levels}->{$level->{key}} = $level;
    $level->{index} = $i++;
  }
}
{
  my $w = {};
  $w->{$_->{key}} = $_->{min_weight} for values %{$Data->{cluster_levels}};
  sub W ($) { $w->{$_[0]} // die $_[0] }
}

my $TypeWeight = {};
my $TypeMergeableWeight = {};
my $PairedTypes = [];
my $NTypes = [];
{
  use utf8;
  
  ## SAME: Same character by definition.  Characters are
  ## unconditionally replaceable.
  for my $vtype (
    "mj:実装したMoji_JohoコレクションIVS",
    "mj:実装したSVS",
    "mj:対応する互換漢字",
    "mj:戸籍統一文字:同一",
    'mj:学術用変体仮名番号',
    'ninjal:MJ文字図形名',
    
    "unicode:svs:cjk",
    "ivd:duplicate",
    "cjkvi:cjkvi/duplicate",
    "manakai:same",

    "uk:font-code-point",
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

    "ucd:Equivalent_Unified_Ideograph",
    "cjkvi:non-cjk/hangzhou-num",
    "cjkvi:non-cjk/kangxi",
    "cjkvi:non-cjk/radical",
    "cjkvi:non-cjk/strokes",
    "cjkvi:non-cjk/kanbun",

    "mj:JIS包摂規準・UCS統合規則",
    "mj:戸籍統一文字番号",
    'mj:統合',
    
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
    "unihan:kIRG_TSource",
    "unihan3.0:kPseudoGB1",
    "unihan3.0:kGB8",
    "unihan3.0:kIRG_GSource:8",
    "unihan:kIRG_GSource:8",
    "unihan3.0:kIRG_TSource",
    "unihan:kKSC0",
    "unihan:kKSC1",
    "unihan:kIRG_KPSource",
    "unihan:kIRG_GSource:K",
    "cjkvi:gb2ucs:K",
    "unihan:kIRG_UKSource",
    "uk:gb8",
    "unihan:kIBMJapan",
    "unihan:kIRG_JSource:ARIB",
    "unicode:mapping",
    "unicode:mapping:apple",
    "unihan:kIRG_HSource",
    "unihan:kIRG_MSource:MA",
    "unihan:kIRG_MSource:MB1",
    "unihan:kIRG_MSource:MB2",
    "cns:big5",
    "cns:big5:符號",
    "cns:big5:七個倚天外字",
    "encoding:decode:big5",
    "moztw:Big5-1984",
    "moztw:UAO 2.50",

    "unihan:kIRG_JSource:1",
    "unihan:kIRG_JSource:14",
    "unihan:kIRG_JSource:4",
    "unihan:kIRG_JSource:A4",
    'mj:UCS',
    'ninjal:UNICODE',

    "glyphwiki:alias",
    "glyphwiki:juki",
    "glyphwiki:ninjal",
    
    "arib:duplicate",
    "arib:isoiec10646",
    "arib:jisx0212",
    "arib:jisx0213",
    "arib:jisx0213:variant",
    "arib:jisx0221",
    "arib:jisx0221:variant",
    "arib:ucs",
    "arib:proportional",
    
    "adobe:uni",
    "adobe:uni:v",
    "adobe:uni:pro",
    "adobe:uni:x0213",
    "adobe:uni:x0213:v",
    "adobe:uni:2004",
    "adobe:uni:2004:v",
    "adobe:uni:x02132004",
    "adobe:uni:x02132004:v",
    "adobe:jisx0212",
    "adobe:jisx0213:2000",
    "adobe:jisx0213:2004",
    "adobe:cns11643",
    "adobe:cns11643:v",
    "adobe:mapping",

    "wikt:mapping",
    "csw:mapping:gb12052",
    "pl:mapping",
    "marc:mapping",

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
    
    "jis:halfwidth",
    "jis:fullwidth",
    "apple:ku+84",
    "manakai:bold",
    "manakai:ocr",
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

    "kchar:Hunminjeongeum Haerye style",
    
    "unihan3.0:kIRG_JSource",
    "unihan:kIRG_JSource:0",
    "unihan:kIRG_JSource:13",
    "unihan:kIRG_JSource:3",
    "unihan:kIRG_JSource:A3",
    
    "manakai:variant:simplified",
    "manakai:variant:jpnewstyle",
    "manakai:variant:wu",
    "manakai:variant:taboo",
    "manakai:equivalent",

    "cccii:layer",
    "marc:variant",
    "marc:unrelated variant",

    "fwhw:normalize",
    "fwhw:strict_normalize",
    "kana:normalize",

    "ucd:names:discouraged",
    "ucd:names:obsoleted",
    "ucd:names:preferred",

    "unihan3.0:kGB0",
    "unihan3.0:kGB1",
    "unihan3.0:kGB3",
    "unihan3.0:kGB5",
    "unihan3.0:kIRG_GSource:0",
    "unihan3.0:kIRG_GSource:1",
    "unihan3.0:kIRG_GSource:3",
    "unihan3.0:kIRG_GSource:5",
    "unihan:kIRG_GSource:0",
    "unihan:kIRG_GSource:1",
    "unihan:kIRG_GSource:3",
    "unihan:kIRG_GSource:5",
    "cjkvi:gb2ucs:2",
    "cjkvi:gb2ucs:4",
    "icu:mapping:iso-ir-165",
    
    "opentype:zero",
    "opentype:ital",
    "opentype:vert",
    "opentype:vrt2",
    "opentype:hkna",
    "opentype:vkna",
    
    "opentype:trad",
    "opentype:expt",
    "opentype:hojo",
    "opentype:jp04",
    "opentype:jp78",
    "opentype:jp83",
    "opentype:nlck",
    "adobe:jis78",
    "adobe:ext",
    "adobe:add",
    "adobe:trad",
    "adobe:expt",
    "adobe:jp04",
    "adobe:jp78",
    "adobe:jp83",
    "adobe:jp90",

    "kana:origin:variant",
  ) {
    $TypeWeight->{$vtype} = W 'EQUIV';
    $TypeWeight->{'rev:'.$vtype} = -1;
  }
  for my $vtype (
    "wakan:assoc",
    "glyphwiki:字母",
    'ninjal:字母',
    'mj:字母',
    'kana:origin',
    "wikipedia:ja:合略仮名:合字",
    "wikipedia:ja:合略仮名:略体",
    "wikipedia:ja:合略仮名:草体",
    "wikipedia:ja:片仮名:省字",
  ) {
    push @$NTypes, $vtype;
    $TypeWeight->{$vtype} = W 'COVERED';
    $TypeWeight->{'rev:'.$vtype} = W 'COVERED';
    $TypeWeight->{'to1:'.$vtype} = W 'EQUIV';
    $TypeWeight->{'to1:rev:'.$vtype} = W 'EQUIV';
    $TypeWeight->{'1to1:'.$vtype} = W 'EQUIV';
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

    "opencc:HKVariants",
    "opencc:JPShinjitaiCharacters",
    "opencc:JPVariants",
    "opencc:STCharacters",
    "opencc:TSCharacters",
    "opencc:TWVariants",
    "opencc:st_multi",
    "opencc:ts_multi",
    "opencc:variant",
    
    "cjkvi:jp/borrowed",
    "cjkvi:jp/borrowed:拡張新字体",

    "wikipedia:zh:歌仔冊文字",
    "wikipedia:zh:臺語本字列表:異用字 / 俗字",
    "wikipedia:zh:臺閩字列表:異用字 / 俗字",
    
    "cjkvi:cjkvi/numeric",
    
    "wakan:assoc?",
    "wikipedia:ja:片仮名:転化か",
    
    "wakan:section",
    'ninjal:平仮名',
    'ninjal:備考:仮名',
    "glyphwiki:音価",
    'kana:modern',
    "wikipedia:ja:合略仮名:読み",
    "wikipedia:ja:片仮名:片仮名",
    'mj:音価',
      'mj:音価1',
      'mj:音価2',
      'mj:音価3',
    "kana:manyou",
    
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

    "kana:h2k",
    "kana:k2h",
    "kana:large",
    "kana:small",
    "arib:70%",

    "unicode5.1:Bidi_Mirroring_Glyph",
    "unicode5.1:Bidi_Mirroring_Glyph-BEST-FIT",
    "unicode:Bidi_Mirroring_Glyph",
    "unicode:Bidi_Mirroring_Glyph-BEST-FIT",
  ) {
    $TypeWeight->{$vtype} = W 'COVERED';
    $TypeWeight->{'rev:'.$vtype} = -1;
    $TypeWeight->{'to1:'.$vtype} = -1;
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
  push @$NTypes, qw(
    cjkvi:joyo/variant
    cjkvi:jinmei1/variant
    cjkvi:jinmei2/variant
    cjkvi:hyogai/variant
    cjkvi:jp-old-style
    cjkvi:jp-old-style:comment
    cjkvi:jp-old-style:compatibility
  );

  ## OVERLAP: Characters share many important characteristics such
  ## that there are many cases one can be replaced by another.
  #for my $vtype (
  #) {
  #  $TypeWeight->{$vtype} = W 'OVERLAP';
  #  $TypeWeight->{'rev:'.$vtype} = -1;
  #}

  ## RELATED: They share some of characteristics such that in some
  ## case a character may be replaced by another.
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
    
    "jp:法務省告示582号別表第四:一:第1順位",
    "jp:法務省告示582号別表第四:二:第1順位",
    "jp:法務省告示582号別表第四:一:第2順位",
    "jp:法務省告示582号別表第四:二:第2順位",
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

    "jp:「異字同訓」の漢字の使い分け例",
    "jp:「異字同訓」の漢字の用法",
    "jp:「異字同訓」の漢字の用法例",
    "wikipedia:ja:同訓異字",
    "manakai:doukun",
    
    "ucd:names:transliterated",

    "rfc3454:B.2",
    "rfc3454:B.3",
    "rfc5051:titlecase-canonical",
    "unicode:NFKC_Casefold",
    "unicode:compat_decomposition",
    "uts46:mapping",
    
    "ucd:names:variant",
    "ucd:names:preferred-some",
    "ucd:names:prefers-some",

    "cjkvi:non-cjk/bracketed",
    "cjkvi:non-cjk/circle",
    "cjkvi:non-cjk/parenthesized",
    "cjkvi:non-cjk/square",

    "unicode:from cp",
    "unicode:to cp",
    "csw:mapping:ksx1002",

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

    "manakai:typo",
    "ucd:names:confused",
    "ucd:names:related",
    "ucd:names:x",
    "unicode:Bidi_Paired_Bracket",
    "unicode:security:confusable",
    "unicode:security:intentional",
    
    "cjkvi:non-cjk/bopomofo",
    "cjkvi:non-cjk/katakana",

    "manakai:ne",
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
    "manakai:ne",
  ) {
    $TypeWeight->{$vtype} = -1;
    $TypeWeight->{'rev:'.$vtype} = -1;
    $TypeMergeableWeight->{$vtype} = W 'LINKED'
        unless $Data->{key} eq 'hans';
  }
  
  for my $vtype (
    "manakai:inset",
    "manakai:inset:original",
    "rev:manakai:inset:original",
    'manakai:hasspecialized',
    'rev:manakai:hasspecialized',
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
    [$_->{path}, $_->{rels_key} || '(none)',
     $_->{set_map} || {}, $_->{mv_map} || {}],
  } @{$Input->{inputs}},
) {
  my ($x, $rels_key, $setmap, $mvmap) = @$_;
  my $path = $DataPath->child ($x);
  print STDERR "\rLoading |$path|... ";
  my $json = {};
  if ($path =~ /\.json$/) {
    $json = json_bytes2perl $path->slurp;
  } else {
    parse_rel_data_file $path->openr => $json;
  }
  for my $c1 (keys %{$json->{$rels_key}}) {
    for my $c2 (keys %{$json->{$rels_key}->{$c1}}) {
      next if $c1 eq $c2;
      my $has = 0;
      for (keys %{$json->{$rels_key}->{$c1}->{$c2}}) {
          my $w = $TypeWeight->{$_} || 0;
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
      $Sets->{$setmap->{$set_key}}->{$c} = 1;
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
for my $vtype (@$NTypes, (map { @$_ } @$PairedTypes)) {
  for my $vtype ($vtype, 'rev:'.$vtype) {
    my $vt2 = $vtype;
    $vt2 =~ s/\d+$//;
    C1: for my $c1 (sort { $a cmp $b } keys %{$HasRels->{$vtype}}) {
      my $n = 0;
      my $c;
      for my $c2 (sort { $a cmp $b } grep { $Rels->{$c1}->{$_}->{$vtype} } keys %{$Rels->{$c1}}) {
        next C1 if ++$n > 1;
        $c = $c2;
      }
      $Rels->{$c1}->{$c}->{'to1:'.$vt2} = 1;
    }
  } # C1
}
for my $vtype (@$NTypes) {
  my $vt2 = $vtype;
  $vt2 =~ s/\d+$//;
  for my $c1 (sort { $a cmp $b } keys %{$HasRels->{$vtype}}) {
    for my $c2 (sort { $a cmp $b } keys %{$Rels->{$c1}}) {
      if ($Rels->{$c1}->{$c2}->{'to1:'.$vt2} and
          $Rels->{$c2}->{$c1}->{'to1:rev:'.$vt2}) {
        $Rels->{$c1}->{$c2}->{'1to1:'.$vt2} = 1;
        $Rels->{$c2}->{$c1}->{'1to1:'.$vt2} = 1;
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
      $Sets->{"to:$vtype"}->{$c1} = 1;
    }
  }
  for my $vtype (qw(
    cjkvi:jp-old-style
  )) {
    for my $c1 (keys %{$HasRels->{$vtype}}) {
      $Sets->{"from:$vtype"}->{$c1} = 1;
    }
  }
}

for (keys %$TypeWeight) {
  $Data->{rel_types}->{$_}->{weight} = $TypeWeight->{$_};
  $Data->{rel_types}->{$_}->{mergeable_weight} = $TypeMergeableWeight->{$_} || W 'SAME';
}

{
  my $i = 1;
  #0: all
  $Data->{leader_types} = {};
  for my $in (@{$Input->{leader_types} || []}) {
    my $key = $in->{key} // die;
    my $lt = $Data->{leader_types}->{$key} ||= {};
    $lt->{key} = $key;
    $lt->{index} = $i++;
    $lt->{short_label} = $in->{short_label} // $in->{label} // die;
    $lt->{label} = $in->{label} // die;
    $lt->{lang_tag} = $in->{lang_tag} // die;
  }
}

{
  my $path = $DataPath->child ('merged-index.json');
  print STDERR "\rWriting[1/4] |$path|... ";
  $path->spew (perl2json_bytes_for_record $Data);
}
{
  my $path = $DataPath->child ('merged-chars.json');
  print STDERR "\rWriting[2/4] |$path|... ";
  my $chars = {};
  for (keys %$Rels) {
    $chars->{$_} = 1;
  }
  $path->spew (perl2json_bytes_for_record $chars);
}
{
  my $path = $DataPath->child ('merged-sets.json');
  print STDERR "\rWriting[3/4] |$path|... ";
  $path->spew (perl2json_bytes_for_record $Sets);
}
{
  my $path = $DataPath->child ("merged-rels.jsonll");
  print STDERR "\rWriting[4/4] |$path|... ";
  my $file = $path->openw;
  my $c1s = [sort { $a cmp $b } keys %$Rels];
  for my $c1 (@$c1s) {
    print $file perl2json_bytes_for_record $c1; # trailing \x0A
    print $file "\x0A";
    print $file perl2json_bytes_for_record $Rels->{$c1}; # trailing \x0A
    print $file "\x0A";
  }
}

printf STDERR "\rDone (%d s) \n", time - $StartTime;

## License: Public Domain.
