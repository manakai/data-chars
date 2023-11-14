all: deps all-data
clean: clean-data

WGET = wget
CURL = curl
GIT = git
PERL = ./perl
SAVEURL = curl -fL -o

updatenightly: update-submodules dataautoupdate build-generated-git-commish

build-generated-git-commish:
	#cd local/generated && $(MAKE) build-git-commish

update-submodules:
	$(CURL) https://gist.githubusercontent.com/motemen/667573/raw/git-submodule-track | sh
	$(GIT) add bin/modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config
	$(CURL) -sSLf https://raw.githubusercontent.com/wakaba/ciconfig/master/ciconfig | RUN_GIT=1 REMOVE_UNUSED=1 perl

dataautoupdate: clean deps build-nightly all build-git-add

build-git-add:
	$(GIT) add data/ src/ intermediate

## ------ Setup ------

deps: git-submodules pmbp-install

git-submodules:
	$(GIT) submodule update --init

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(SAVEURL) $@ https://raw.github.com/wakaba/perl-setupenv/master/bin/pmbp.pl
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl --update-pmbp-pl
pmbp-update: git-submodules pmbp-upgrade
	perl local/bin/pmbp.pl --update
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl --install \
            --create-perl-command-shortcut perl \
            --create-perl-command-shortcut prove

## ------ Data construction ------

data: all-data

all-data: all-ucd unicode-general-category-latest \
    unicode-prop-list-latest data/sets.json data/names.json \
    data/maps.json data/number-values.json \
    data/tests/cjk-numbers.json data/seqs.json data/keys.json \
    data/perl/unicore-CombiningClass.pl data/perl/unicore-Decomposition.pl \
    data/tests/kana-tokana.json data/tests/kana-normalize.json

clean-data: clean-perl-unicode
	rm -fr local/ucd/touch local/langtags.json local/tr31.html
	rm -fr local/unicode
	rm -fr local/iana-idna/latest.xml local/iana-precis/latest.xml
	rm -fr src/set/unicode/has_canon_decomposition.expr
	rm -fr src/set/unicode/has_compat_decomposition.expr
	rm -fr src/set/unicode/canon_decomposition_second.expr
	rm -fr src/set/unicode/CompositionExclusions.expr

all-ucd: prepare-ucd data/scripts.json local/ucd/touch
prepare-ucd: local/ucd
local/ucd:
	mkdir -p local/ucd
local/ucd/touch:
	touch $@

local/ucd/PropertyValueAliases.txt: local/ucd
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/PropertyValueAliases.txt

local/security/latest/confusables.txt:
	mkdir -p local/security/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/security/latest/confusables.txt
local/security/latest/intentional.txt:
	mkdir -p local/security/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/security/latest/intentional.txt

local/tr31.html:
	$(SAVEURL) $@ https://www.unicode.org/reports/tr31/
local/tr31.json: local/tr31.html bin/extract-tr31.pl
	$(PERL) bin/extract-tr31.pl > $@

src/set/uax31/files: bin/uax31.pl local/tr31.json
	$(PERL) bin/uax31.pl
	touch $@
src/set/unicode/Script/files: \
    bin/script-sets.pl data/scripts.json \
    local/unicode/latest/Scripts.txt \
    local/unicode/latest/ScriptExtensions.txt
	$(PERL) bin/script-sets.pl latest
	touch $@

local/langtags.json:
	$(SAVEURL) $@ https://raw.github.com/manakai/data-web-defs/master/data/langtags.json
local/html-charrefs.json:
	$(SAVEURL) $@ https://raw.githubusercontent.com/manakai/data-web-defs/master/data/html-charrefs.json

data/scripts.json: bin/scripts.pl local/unicode/latest/Scripts.txt \
    local/ucd/PropertyValueAliases.txt local/tr31.json \
    local/langtags.json
	$(PERL) bin/scripts.pl > $@

data/names.json: bin/names.pl \
    local/unicode/latest/NamesList.txt \
    local/unicode/latest/NameAliases.txt \
    local/unicode/latest/NamedSequences.txt \
    src/janames-jisx0213.json src/janames-jisx0211.json \
    src/set/unicode/Script/Han.expr
	$(PERL) $< > $@

UNICODE_VERSION = XXXVERSIONNOTSPECIFIEDXXX

unicode-general-category-2.0: local/unicode/2.0/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl 2.0 $<
unicode-general-category-2.1: local/unicode/2.1/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl 2.1 $<
unicode-general-category-3.0: local/unicode/3.0/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl 3.0 $<
unicode-general-category-3.2: local/unicode/3.2/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl 3.2 $<
unicode-general-category-5.0: local/unicode/5.0/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl 5.0 $<
unicode-general-category-5.2: local/unicode/5.2/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl 5.2 $<
unicode-general-category-6.0: local/unicode/6.0/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl 6.0 $<
unicode-general-category-6.1: local/unicode/6.1/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl 6.1 $<
unicode-general-category-6.2: local/unicode/6.2/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl 6.2 $<
unicode-general-category-6.3: local/unicode/6.3/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl 6.3 $<
unicode-general-category-latest: src/set/unicode/Cc.expr
src/set/unicode/Cc.expr: local/unicode/latest/UnicodeData.txt \
    bin/generate-general-category.pl
	$(PERL) bin/generate-general-category.pl latest $<

local/unicode/2.0/UnicodeData.txt:
	mkdir -p local/unicode/2.0
	$(SAVEURL) $@ https://www.unicode.org/Public/2.0-Update/UnicodeData-2.0.14.txt
local/unicode/2.1/UnicodeData.txt:
	mkdir -p local/unicode/2.1
	$(SAVEURL) $@ https://www.unicode.org/Public/2.1-Update4/UnicodeData-2.1.9.txt
local/unicode/3.0/UnicodeData.txt:
	mkdir -p local/unicode/3.0
	$(SAVEURL) $@ https://www.unicode.org/Public/3.0-Update1/UnicodeData-3.0.1.txt
local/unicode/3.2/UnicodeData.txt:
	mkdir -p local/unicode/3.2
	$(SAVEURL) $@ https://www.unicode.org/Public/3.2-Update/UnicodeData-3.2.0.txt
local/unicode/5.0/UnicodeData.txt:
	mkdir -p local/unicode/5.0
	$(SAVEURL) $@ https://www.unicode.org/Public/5.0.0/ucd/UnicodeData.txt
local/unicode/5.2/UnicodeData.txt:
	mkdir -p local/unicode/5.2
	$(SAVEURL) $@ https://www.unicode.org/Public/5.2.0/ucd/UnicodeData.txt
local/unicode/6.0/UnicodeData.txt:
	mkdir -p local/unicode/6.0
	$(SAVEURL) $@ https://www.unicode.org/Public/6.0.0/ucd/UnicodeData.txt
local/unicode/6.1/UnicodeData.txt:
	mkdir -p local/unicode/6.1
	$(SAVEURL) $@ https://www.unicode.org/Public/6.1.0/ucd/UnicodeData.txt
local/unicode/6.2/UnicodeData.txt:
	mkdir -p local/unicode/6.2
	$(SAVEURL) $@ https://www.unicode.org/Public/6.2.0/ucd/UnicodeData.txt
local/unicode/6.3/UnicodeData.txt: local/unicode/6.3.0/UnicodeData.txt
	mkdir -p local/unicode/6.3
	cp local/unicode/6.3.0/UnicodeData.txt $@
local/unicode/6.3.0/UnicodeData.txt:
	mkdir -p local/unicode/6.3.0
	$(SAVEURL) $@ https://www.unicode.org/Public/6.3.0/ucd/UnicodeData.txt
local/unicode/$(UNICODE_VERSION)/UnicodeData.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/UnicodeData.txt
local/unicode/latest/UnicodeData.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt
local/unicode/latest/NamesList.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/NamesList.txt
local/unicode/latest/NameAliases.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/NameAliases.txt
local/unicode/latest/NamedSequences.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/NamedSequences.txt
local/unicode/latest/Blocks.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/Blocks.txt
local/unicode/$(UNICODE_VERSION)/Blocks.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/Blocks.txt
local/unicode/latest/Scripts.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/Scripts.txt
local/unicode/latest/ScriptExtensions.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/ScriptExtensions.txt
local/unicode/latest/SpecialCasing.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/SpecialCasing.txt
local/unicode/latest/HangulSyllableType.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/HangulSyllableType.txt
local/unicode/$(UNICODE_VERSION)/HangulSyllableType.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/HangulSyllableType.txt
local/unicode/latest/DerivedCombiningClass.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/extracted/DerivedCombiningClass.txt
local/unicode/$(UNICODE_VERSION)/DerivedCombiningClass.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/extracted/DerivedCombiningClass.txt
local/unicode/latest/DerivedAge.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/DerivedAge.txt
local/unicode/$(UNICODE_VERSION)/DerivedBidiClass.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://unicode.org/Public/$(UNICODE_VERSION)/ucd/extracted/DerivedBidiClass.txt
local/unicode/latest/DerivedBidiClass.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/extracted/DerivedBidiClass.txt
local/unicode/$(UNICODE_VERSION)/DerivedDecompositionType.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://unicode.org/Public/$(UNICODE_VERSION)/ucd/extracted/DerivedDecompositionType.txt
local/unicode/latest/DerivedDecompositionType.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/extracted/DerivedDecompositionType.txt
local/unicode/$(UNICODE_VERSION)/BidiMirroring.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/BidiMirroring.txt
local/unicode/latest/BidiMirroring.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/BidiMirroring.txt

src/set/unicode/Block/files: \
    bin/blocks.pl \
    local/unicode/latest/Blocks.txt
	$(PERL) bin/blocks.pl latest
	touch $@
src/set/unicode$(UNICODE_VERSION:.0=)/Block/files: \
    bin/blocks.pl \
    local/unicode/$(UNICODE_VERSION)/Blocks.txt
	$(PERL) bin/blocks.pl $(UNICODE_VERSION)
	touch $@
src/set/unicode/Hangul_Syllable_Type/files: \
    bin/hangul-syllable-type.pl \
    local/unicode/latest/HangulSyllableType.txt
	$(PERL) bin/hangul-syllable-type.pl latest
	touch $@
src/set/unicode$(UNICODE_VERSION:.0=)/Hangul_Syllable_Type/files: \
    bin/hangul-syllable-type.pl \
    local/unicode/$(UNICODE_VERSION)/HangulSyllableType.txt
	$(PERL) bin/hangul-syllable-type.pl $(UNICODE_VERSION)
	touch $@
src/set/unicode/Canonical_Combining_Class/files: \
    bin/ccc.pl \
    local/unicode/latest/DerivedCombiningClass.txt
	$(PERL) bin/ccc.pl latest
	touch $@
src/set/unicode$(UNICODE_VERSION:.0=)/Canonical_Combining_Class/files: \
    bin/ccc.pl \
    local/unicode/$(UNICODE_VERSION)/DerivedCombiningClass.txt
	$(PERL) bin/ccc.pl $(UNICODE_VERSION)
	touch $@
src/set/unicode/Bidi_Class/files: \
    bin/bidiclass.pl \
    local/unicode/latest/DerivedBidiClass.txt \
    local/unicode/latest/BidiMirroring.txt \
    local/unicode/latest/DerivedBinaryProperties.txt \
    local/unicode/latest/BidiBrackets.txt \
    local/unicode/latest/VerticalOrientation.txt \
    local/unicode/latest/DerivedDecompositionType.txt
	$(PERL) bin/bidiclass.pl latest
	touch $@
src/set/unicode$(UNICODE_VERSION:.0=)/Bidi_Class/files: \
    bin/bidiclass.pl \
    local/unicode/$(UNICODE_VERSION)/DerivedBidiClass.txt \
    local/unicode/$(UNICODE_VERSION)/BidiMirroring.txt \
    local/unicode/$(UNICODE_VERSION)/DerivedBinaryProperties.txt \
    local/unicode/$(UNICODE_VERSION)/BidiBrackets.txt \
    local/unicode/$(UNICODE_VERSION)/VerticalOrientation.txt \
    local/unicode/$(UNICODE_VERSION)/DerivedDecompositionType.txt
	$(PERL) bin/bidiclass.pl $(UNICODE_VERSION)
	touch $@
src/set/unicode/Age/files: \
    bin/ccc.pl \
    local/unicode/latest/DerivedAge.txt
	$(PERL) bin/age.pl latest
	touch $@
src/set/unicode/Joining_Type/files: \
    local/unicode/latest/DerivedJoiningType.txt \
    bin/extract-enum-prop.pl
	$(PERL) bin/extract-enum-prop.pl latest Joining_Type
	touch $@
src/set/unicode/Joining_Group/files: \
    local/unicode/latest/DerivedJoiningGroup.txt \
    bin/extract-enum-prop.pl
	$(PERL) bin/extract-enum-prop.pl latest Joining_Group
	touch $@

local/perl-unicode/latest/lib/unicore-CombiningClass.pl: \
    src/set/unicode/Canonical_Combining_Class/files
local/perl-unicode/$(UNICODE_VERSION)/lib/unicore-CombiningClass.pl: \
    src/set/unicode$(UNICODE_VERSION:.0=)/Canonical_Combining_Class/files
local/perl-unicode/latest/lib/unicore-Decomposition.pl: \
    bin/unicore-decomposition.pl local/unicode/latest/UnicodeData.txt
	$(PERL) bin/unicore-decomposition.pl latest
local/perl-unicode/$(UNICODE_VERSION)/lib/unicore-Decomposition.pl: \
    bin/unicore-decomposition.pl \
    local/unicode/$(UNICODE_VERSION)/UnicodeData.txt
	$(PERL) bin/unicore-decomposition.pl $(UNICODE_VERSION)
src/set/unicode/has_canon_decomposition.expr: bin/unicode-decompositions.pl \
    local/unicode/latest/UnicodeData.txt
	$(PERL) bin/unicode-decompositions.pl
src/set/unicode/has_compat_decomposition.expr: \
    src/set/unicode/has_canon_decomposition.expr
src/set/unicode/canon_decomposition_second.expr: \
    src/set/unicode/has_canon_decomposition.expr

src/set/unicode/Uppercase_Letter.expr: bin/general-category-aliases.pl
	$(PERL) bin/general-category-aliases.pl latest

PERL_UNICODE_NORMALIZE = \
  local/perl-unicode/latest/lib/unicore-CombiningClass.pl \
  local/perl-unicode/latest/lib/unicore-Decomposition.pl \
  bin/lib/UnicodeNormalize.pm
PERL_UNICODE_NORMALIZE_VERSIONED = \
  local/perl-unicode/$(UNICODE_VERSION)/lib/unicore-CombiningClass.pl \
  local/perl-unicode/$(UNICODE_VERSION)/lib/unicore-Decomposition.pl \
  bin/lib/UnicodeNormalize.pm

clean-perl-unicode:
	rm -fr local/perl-unicode
	rm -fr src/set/unicode/Canonical_Combining_Class/files

data/perl/unicore-CombiningClass.pl: \
    local/perl-unicode/latest/lib/unicore-CombiningClass.pl
	cp $< $@
	$(PERL) -c $@
data/perl/unicore-Decomposition.pl: \
    local/perl-unicode/latest/lib/unicore-Decomposition.pl
	cp $< $@
	$(PERL) -c $@

unicode-prop-list-3.2: local/unicode/3.2/PropList.txt
	$(PERL) bin/generate-prop-list.pl 3.2 $<
unicode-prop-list-5.0: local/unicode/5.0/PropList.txt
	$(PERL) bin/generate-prop-list.pl 5.0 $<
unicode-prop-list-5.2: local/unicode/5.2/PropList.txt
	$(PERL) bin/generate-prop-list.pl 5.2 $<
unicode-prop-list-latest: src/set/unicode/White_Space.expr
src/set/unicode/White_Space.expr: local/unicode/latest/PropList.txt \
    local/unicode/latest/DerivedCoreProperties.txt \
    local/unicode/latest/DerivedNormalizationProps.txt
	$(PERL) bin/generate-prop-list.pl latest local/unicode/latest/PropList.txt
	$(PERL) bin/generate-prop-list.pl latest local/unicode/latest/DerivedCoreProperties.txt
	$(PERL) bin/generate-prop-list.pl latest local/unicode/latest/DerivedNormalizationProps.txt
src/set/unicode$(UNICODE_VERSION:.0=)/Default_Ignorable_Code_Point.expr: \
    local/unicode/$(UNICODE_VERSION)/PropList.txt \
    local/unicode/$(UNICODE_VERSION)/DerivedCoreProperties.txt \
    local/unicode/$(UNICODE_VERSION)/DerivedNormalizationProps.txt
	$(PERL) bin/generate-prop-list.pl $(UNICODE_VERSION:.0=) local/unicode/$(UNICODE_VERSION)/PropList.txt
	$(PERL) bin/generate-prop-list.pl $(UNICODE_VERSION:.0=) local/unicode/$(UNICODE_VERSION)/DerivedCoreProperties.txt
	$(PERL) bin/generate-prop-list.pl $(UNICODE_VERSION:.0=) local/unicode/$(UNICODE_VERSION)/DerivedNormalizationProps.txt

local/unicode/3.2/PropList.txt:
	mkdir -p local/unicode/3.2
	$(SAVEURL) $@ https://www.unicode.org/Public/3.2-Update/PropList-3.2.0.txt
local/unicode/5.0/PropList.txt:
	mkdir -p local/unicode/5.0
	$(SAVEURL) $@ https://www.unicode.org/Public/5.0.0/ucd/PropList.txt
local/unicode/5.2/PropList.txt:
	mkdir -p local/unicode/5.0
	$(SAVEURL) $@ https://www.unicode.org/Public/5.2.0/ucd/PropList.txt
local/unicode/$(UNICODE_VERSION)/PropList.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/PropList.txt
local/unicode/latest/PropList.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/PropList.txt

local/unicode/latest/CaseFolding.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/CaseFolding.txt
local/unicode/latest/DerivedCoreProperties.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/DerivedCoreProperties.txt
local/unicode/$(UNICODE_VERSION)/DerivedCoreProperties.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/DerivedCoreProperties.txt
local/unicode/latest/DerivedBinaryProperties.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/extracted/DerivedBinaryProperties.txt
local/unicode/$(UNICODE_VERSION)/DerivedBinaryProperties.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/extracted/DerivedBinaryProperties.txt
local/unicode/latest/DerivedNormalizationProps.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/DerivedNormalizationProps.txt
local/unicode/$(UNICODE_VERSION)/DerivedNormalizationProps.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/DerivedNormalizationProps.txt
local/unicode/latest/BidiBrackets.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/BidiBrackets.txt
local/unicode/$(UNICODE_VERSION)/BidiBrackets.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/BidiBrackets.txt
local/unicode/latest/VerticalOrientation.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/VerticalOrientation.txt
local/unicode/$(UNICODE_VERSION)/VerticalOrientation.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/VerticalOrientation.txt

local/unicode/latest/CompositionExclusions.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/CompositionExclusions.txt
src/set/unicode/CompositionExclusions.expr: \
    bin/unicode-CompositionExclusions.pl \
    local/unicode/latest/CompositionExclusions.txt
	$(PERL) $< < local/unicode/latest/CompositionExclusions.txt > $@
local/unicode/latest/DerivedJoiningGroup.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/extracted/DerivedJoiningGroup.txt
local/unicode/$(UNICODE_VERSION)/DerivedJoiningGroup.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/extracted/DerivedJoiningGroup.txt
local/unicode/latest/DerivedJoiningType.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/extracted/DerivedJoiningType.txt
local/unicode/$(UNICODE_VERSION)/DerivedJoiningType.txt:
	mkdir -p local/unicode/$(UNICODE_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/Public/$(UNICODE_VERSION)/ucd/extracted/DerivedJoiningType.txt
local/unicode/latest/StandardizedVariants.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/StandardizedVariants.txt

local/unicode/latest/IdnaMappingTable.txt:
	mkdir -p local/unicode/latest
	$(SAVEURL) $@ https://www.unicode.org/Public/idna/latest/IdnaMappingTable.txt
local/map-data/uts46--mapping.json: bin/uts46-idna-mapping.pl \
    local/unicode/latest/IdnaMappingTable.txt
	$(PERL) $<
src/set/uts46/disallowed.expr: local/map-data/uts46--mapping.json

src/set/rfc5892/Unstable.expr: bin/idna2008-unstable.pl \
    bin/lib/Charinfo/Set.pm $(PERL_UNICODE_NORMALIZE)
# data/maps.json
	$(PERL) bin/idna2008-unstable.pl latest
src/set/rfc7564/HasCompat.expr: src/set/rfc5892/Unstable.expr
src/set/rfc5892-$(UNICODE_VERSION)/Unstable.expr: bin/idna2008-unstable.pl \
    bin/lib/Charinfo/Set.pm $(PERL_UNICODE_NORMALIZE_VERSIONED)
# data/maps.json
	$(PERL) bin/idna2008-unstable.pl $(UNICODE_VERSION)
src/set/rfc7564-$(UNICODE_VERSION)/HasCompat.expr: \
    src/set/rfc5892-$(UNICODE_VERSION)/Unstable.expr

local/iana-idna/$(UNICODE_VERSION).xml:
	mkdir -p local/iana-idna
	$(SAVEURL) $@ https://www.iana.org/assignments/idna-tables-$(UNICODE_VERSION)/idna-tables-$(UNICODE_VERSION).xml
local/iana-idna/latest.xml:
	mkdir -p local/iana-idna
	$(SAVEURL) $@ https://www.iana.org/assignments/idna-tables/idna-tables.xml
local/iana-precis/$(UNICODE_VERSION).xml:
	mkdir -p local/iana-precis
	$(SAVEURL) $@ https://www.iana.org/assignments/precis-tables-$(UNICODE_VERSION)/precis-tables-$(UNICODE_VERSION).xml
local/iana-precis/latest.xml:
	mkdir -p local/iana-precis
	$(SAVEURL) $@ https://www.iana.org/assignments/precis-tables/precis-tables.xml

src/set/idna-tables-$(UNICODE_VERSION)/files: \
    local/iana-idna/$(UNICODE_VERSION).xml \
    bin/idna-tables.pl
	mkdir -p src/set/idna-tables-$(UNICODE_VERSION)
	$(PERL) bin/idna-tables.pl $(UNICODE_VERSION)
	touch $@
src/set/idna-tables-latest/files: \
    local/iana-idna/latest.xml \
    bin/idna-tables.pl
	mkdir -p src/set/idna-tables-latest
	$(PERL) bin/idna-tables.pl latest
	touch $@
src/set/precis-tables-$(UNICODE_VERSION)/files: \
    local/iana-precis/$(UNICODE_VERSION).xml \
    bin/precis-tables.pl
	mkdir -p src/set/precis-tables-$(UNICODE_VERSION)
	$(PERL) bin/precis-tables.pl $(UNICODE_VERSION)
	touch $@
src/set/precis-tables-latest/files: \
    local/iana-precis/latest.xml \
    bin/precis-tables.pl
	mkdir -p src/set/precis-tables-latest
	$(PERL) bin/precis-tables.pl latest
	touch $@

src/set/rfc5892-$(UNICODE_VERSION)/files: \
    bin/copy-for-unicode-version.pl \
    src/set/rfc5892/*.expr src/set/rfc5892/*/*.expr \
    src/set/rfc5892-$(UNICODE_VERSION)/Unstable.expr
	$(PERL) bin/copy-for-unicode-version.pl rfc5892 $(UNICODE_VERSION)
	touch $@
src/set/rfc7564-$(UNICODE_VERSION)/files: \
    bin/copy-for-unicode-version.pl \
    src/set/rfc7564/*.expr src/set/rfc7564/*/*.expr \
    src/set/rfc7564-$(UNICODE_VERSION)/HasCompat.expr \
    src/set/rfc5892-$(UNICODE_VERSION)/files
	$(PERL) bin/copy-for-unicode-version.pl rfc7564 $(UNICODE_VERSION)
	touch $@

src/set/isoiec10646/300.expr: src/set/isoiec10646/generate.pl
	$(PERL) $<

local/hentai_to_standard.json \
src/set/mj/hentaigana-han.expr \
src/set/mj/hentaigana.expr:: %: bin/mj-kana.pl \
    src/mj-hentai.json
	$(PERL) $<

local/mozilla-prefs.js:
	$(SAVEURL) $@ https://raw.githubusercontent.com/mozilla/gecko-dev/master/modules/libpref/init/all.js
#src/set/mozilla/IDN-blacklist-chars.expr: local/mozilla-prefs.js \
#    bin/mozilla-idn-blacklist-chars.pl
#	$(PERL) bin/mozilla-idn-blacklist-chars.pl < $< > $@
## network.IDN.blacklist_chars is gone

local/jis-0208.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/wakaba/data-chartables/master/generated/jisx0208_1997_irv.tbl
local/jis-0213-1.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/wakaba/data-chartables/master/generated/jisx0213_2000_1.tbl
local/jis-0213-2.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/wakaba/data-chartables/master/generated/jisx0213_2000_2.tbl
local/encoding-0208.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/whatwg/encoding/master/index-jis0208.txt
src/set/jisx0208/files: bin/jisx0208.pl \
    local/jis-0208.txt local/encoding-0208.txt
	$(PERL) bin/jisx0208.pl
	touch $@
src/set/jisx4051/files: bin/jisx4051.pl \
    local/jis-0213-1.txt local/jis-0213-2.txt
	$(PERL) bin/jisx4051.pl
	mkdir -p src/set/jisx4051
	touch $@

data/sets.json: bin/sets.pl \
    bin/lib/Charinfo/Name.pm bin/lib/Charinfo/Set.pm \
    src/set/rfc5892/Unstable.expr src/set/rfc7564/HasCompat.expr \
    src/set/unicode/Block/files \
    src/set/unicode/Script/files \
    src/set/unicode/Hangul_Syllable_Type/files \
    src/set/unicode/Canonical_Combining_Class/files \
    src/set/unicode/Bidi_Class/files \
    src/set/unicode/Age/files \
    src/set/unicode/has_canon_decomposition.expr \
    src/set/unicode/has_compat_decomposition.expr \
    src/set/unicode/canon_decomposition_second.expr \
    src/set/unicode/Uppercase_Letter.expr \
    src/set/unicode/Joining_Type/files \
    src/set/unicode/Joining_Group/files \
    src/set/uax31/files \
    src/set/idna-tables-latest/files \
    src/set/precis-tables-latest/files \
    src/set/*/*.expr src/set/*/*/*.expr data/names.json \
    src/set/mozilla/IDN-blacklist-chars.expr \
    src/set/numbers/CJK-digit.expr \
    src/set/isoiec10646/300.expr \
    src/set/mj/hentaigana.expr \
    src/set/mj/hentaigana-han.expr \
    src/set/unicode/CompositionExclusions.expr src/set/uts46/disallowed.expr \
    src/set/jisx0208/files \
    src/set/jisx4051/files
	$(PERL) bin/sets.pl > $@

data/maps.json: bin/maps.pl local/unicode/latest/UnicodeData.txt \
    local/unicode/latest/SpecialCasing.txt \
    local/unicode/latest/DerivedNormalizationProps.txt \
    local/unicode/latest/CaseFolding.txt \
    data/sets.json src/tn1150table.txt src/tn1150lowercase.json \
    local/map-data/uts46--mapping.json \
    local/hentai_to_standard.json \
    src/map/*/*.expr \
    local/security/latest/confusables.txt \
    local/security/latest/intentional.txt
	$(PERL) bin/maps.pl > $@

src/map/unicode/hangul_decomposition.expr: bin/hangul-decompose.pl
	$(PERL) $< > $@

local/spec-numbers.html:
	$(SAVEURL) $@ https://manakai.github.io/spec-numbers/
local/spec-numbers.json: bin/spec-numbers.pl local/spec-numbers.html
	$(PERL) bin/spec-numbers.pl > $@

src/set/numbers/CJK-digit.expr: bin/spec-numbers-sets.pl local/spec-numbers.json
	$(PERL) bin/spec-numbers-sets.pl

data/number-values.json: bin/number-values.pl \
    local/spec-numbers.json
	$(PERL) bin/number-values.pl > $@

data/tests/cjk-numbers.json: bin/tests-cjk-numbers.pl
	$(PERL) $< > $@

data/tests/kana-tokana.json: bin/tests-kana-tokana.pl \
    data/maps.json
	$(PERL) $< > $@
data/tests/kana-normalize.json: bin/tests-kana-normalize.pl \
    data/maps.json
	$(PERL) $< > $@

data/seqs.json: bin/seqs.pl \
    data/names.json local/langtags.json src/seqs.txt \
    local/html-charrefs.json
	$(PERL) $< > $@

data/keys.json: bin/keys.pl src/key/*.txt local/html-charrefs.json
	$(PERL) $< > $@

# referenced from https://github.com/suikawiki/swdata
build-swdata: build-pages-iu build-nightly

build-nightly: local/generated build-nightly-iu

build-github-pages: local/generated build-pages-iu
	cd intermediate/charrels && $(MAKE) clean-pages
	rm -fr ./bin/ ./modules/ ./t_deps/ intermediate src data deps
	mv local/generated generated
	rm -fr ./local
	mkdir local
	mv generated local/

	tar -cf generated.tar local/generated
	gzip generated.tar
	ls -l generated.tar.gz

	rm -fr local/ config perl prove

deployed-github-pages:
	$(CURL) -f -X POST -d "{}" $$HOOK_NEXT_STEP_URL

build-for-docker: local/generated build-pages-iu
	cp config/Dockerfile.pages ./Dockerfile

build-nightly-iu: deps data/maps.json
	cd intermediate/unicode && $(MAKE) build-nightly
	cd intermediate/opencc && $(MAKE) build-nightly
	cd intermediate/misc && $(MAKE) build-nightly
	#
	#cd intermediate/charrels && $(MAKE) build-nightly

build-pages-iu: deps
	cd intermediate/wiki && $(MAKE) build-pages
	cd intermediate/google && $(MAKE) build-pages
	cd intermediate/cjkvi && $(MAKE) build-pages
	cd intermediate/mj && $(MAKE) build-pages
	cd intermediate/viet && $(MAKE) build-pages
	cd intermediate/fonts && $(MAKE) build-pages
	cd intermediate/misc && $(MAKE) build-pages
	cd intermediate/swcf && $(MAKE) build-pages
	#
	cd intermediate/charrels && $(MAKE) build-pages

local/generated:
	#$(GIT) clone https://github.com/manakai/generated-data-chars $@ || (cd $@ && $(GIT) pull)
	mkdir -p local/generated

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
	$(PROVE) t/*.t

test-size:
	$(PERL) t/filesize.t

## License: Public Domain.
