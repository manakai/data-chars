all: deps all-data
clean: clean-data

WGET = wget
GIT = git
PERL = ./perl

updatenightly: dataautoupdate

dataautoupdate: clean deps all
	$(GIT) add data/ src/

## ------ Setup ------

deps: git-submodules pmbp-install

git-submodules:
	$(GIT) submodule update --init

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(WGET) -O $@ https://raw.github.com/wakaba/perl-setupenv/master/bin/pmbp.pl
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl --update-pmbp-pl
pmbp-update: git-submodules pmbp-upgrade
	perl local/bin/pmbp.pl --update
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl --install \
            --create-perl-command-shortcut perl \
            --create-perl-command-shortcut prove

## ------ Data construction ------

all-data: all-ucd unicode-general-category-latest \
    unicode-prop-list-latest data/sets.json data/names.json \
    data/maps.json

clean-data:
	rm -fr local/ucd/touch local/langtags.json local/tr31.html
	rm -fr local/unicode/latest local/iana-idna/latest.xml

all-ucd: prepare-ucd data/scripts.json local/ucd/touch
prepare-ucd:
	mkdir -p local/ucd
local/ucd/touch:
	touch $@

local/ucd/Scripts.txt:
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/Scripts.txt
local/ucd/ScriptExtensions.txt:
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/ScriptExtensions.txt
local/ucd/PropertyValueAliases.txt:
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/PropertyValueAliases.txt

local/tr31.html:
	$(WGET) -O $@ http://www.unicode.org/reports/tr31/
local/tr31.json: local/tr31.html bin/extract-tr31.pl
	$(PERL) bin/extract-tr31.pl > $@

src/set/uax31/files: bin/uax31.pl local/tr31.json
	$(PERL) bin/uax31.pl
	touch $@

local/langtags.json:
	$(WGET) -O $@ https://raw.github.com/manakai/data-web-defs/master/data/langtags.json

data/scripts.json: bin/scripts.pl local/ucd/Scripts.txt \
    local/ucd/PropertyValueAliases.txt local/tr31.json \
    local/langtags.json
	$(PERL) bin/scripts.pl > $@

local/unicode/latest/NamesList.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UNIDATA/NamesList.txt
local/unicode/latest/NameAliases.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UNIDATA/NameAliases.txt
local/unicode/latest/NamedSequences.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UNIDATA/NamedSequences.txt

data/names.json: local/unicode/latest/NamesList.txt \
    local/unicode/latest/NameAliases.txt \
    local/unicode/latest/NamedSequences.txt \
    bin/names.pl src/janames-jisx0213.json src/janames-jisx0211.json
	$(PERL) bin/names.pl > $@

unicode-general-category-2.0: local/unicode/2.0/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl 2.0 $<
unicode-general-category-2.1: local/unicode/2.1/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl 2.1 $<
unicode-general-category-3.0: local/unicode/3.0/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl 3.0 $<
unicode-general-category-3.2: local/unicode/3.2/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl 3.2 $<
unicode-general-category-5.0: local/unicode/5.0/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl 5.0 $<
unicode-general-category-5.2: local/unicode/5.2/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl 5.2 $<
unicode-general-category-6.0: local/unicode/6.0/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl 6.0 $<
unicode-general-category-6.1: local/unicode/6.1/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl 6.1 $<
unicode-general-category-6.2: local/unicode/6.2/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl 6.2 $<
unicode-general-category-6.3: local/unicode/6.3/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl 6.3 $<
unicode-general-category-latest: local/unicode/latest/UnicodeData.txt
	$(PERL) bin/generate-general-category.pl latest $<

local/unicode/2.0/UnicodeData.txt:
	mkdir -p local/unicode/2.0
	$(WGET) -O $@ http://www.unicode.org/Public/2.0-Update/UnicodeData-2.0.14.txt
local/unicode/2.1/UnicodeData.txt:
	mkdir -p local/unicode/2.1
	$(WGET) -O $@ http://www.unicode.org/Public/2.1-Update4/UnicodeData-2.1.9.txt
local/unicode/3.0/UnicodeData.txt:
	mkdir -p local/unicode/3.0
	$(WGET) -O $@ http://www.unicode.org/Public/3.0-Update1/UnicodeData-3.0.1.txt
local/unicode/3.2/UnicodeData.txt:
	mkdir -p local/unicode/3.2
	$(WGET) -O $@ http://www.unicode.org/Public/3.2-Update/UnicodeData-3.2.0.txt
local/unicode/5.0/UnicodeData.txt:
	mkdir -p local/unicode/5.0
	$(WGET) -O $@ http://www.unicode.org/Public/5.0.0/ucd/UnicodeData.txt
local/unicode/5.2/UnicodeData.txt:
	mkdir -p local/unicode/5.2
	$(WGET) -O $@ http://www.unicode.org/Public/5.2.0/ucd/UnicodeData.txt
local/unicode/6.0/UnicodeData.txt:
	mkdir -p local/unicode/6.0
	$(WGET) -O $@ http://www.unicode.org/Public/6.0.0/ucd/UnicodeData.txt
local/unicode/6.1/UnicodeData.txt:
	mkdir -p local/unicode/6.1
	$(WGET) -O $@ http://www.unicode.org/Public/6.1.0/ucd/UnicodeData.txt
local/unicode/6.2/UnicodeData.txt:
	mkdir -p local/unicode/6.2
	$(WGET) -O $@ http://www.unicode.org/Public/6.2.0/ucd/UnicodeData.txt
local/unicode/6.3/UnicodeData.txt:
	mkdir -p local/unicode/6.3
	$(WGET) -O $@ http://www.unicode.org/Public/6.3.0/ucd/UnicodeData.txt
local/unicode/latest/UnicodeData.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt

local/unicode/latest/Blocks.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/Blocks.txt
local/unicode/latest/SpecialCasing.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/SpecialCasing.txt
local/unicode/latest/HangulSyllableType.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/HangulSyllableType.txt
local/unicode/latest/DerivedCombiningClass.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/extracted/DerivedCombiningClass.txt

src/set/unicode/Block/files: \
    bin/blocks.pl \
    local/unicode/latest/Blocks.txt
	$(PERL) bin/blocks.pl
	touch $@
src/set/unicode/Hangul_Syllable_Type/files: \
    bin/hangul-syllable-type.pl \
    local/unicode/latest/HangulSyllableType.txt
	$(PERL) bin/hangul-syllable-type.pl
	touch $@
src/set/unicode/Canonical_Combining_Class/files: \
    bin/ccc.pl \
    local/unicode/latest/DerivedCombiningClass.txt
	$(PERL) bin/ccc.pl
	touch $@

local/perl-unicode/lib/unicore/CombiningClass.pl: \
    src/set/unicode/Canonical_Combining_Class/files
local/perl-unicode/lib/unicore/Decomposition.pl: \
    bin/unicore-decomposition.pl local/unicode/latest/UnicodeData.txt
	$(PERL) bin/unicore-decomposition.pl
bin/lib/Unicode/Normalize.pm:
	$(WGET) -O $@ http://cpansearch.perl.org/src/SADAHIRO/Unicode-Normalize-1.17/Normalize.pmN
src/set/unicode/has_canon_decomposition.expr: bin/unicode-decompositions.pl \
    local/unicode/latest/UnicodeData.txt
	$(PERL) bin/unicode-decompositions.pl
src/set/unicode/has_compat_decomposition.expr: \
    src/set/unicode/has_canon_decomposition.expr

PERL_UNICODE_NORMALIZE = \
  local/perl-unicode/lib/unicore/CombiningClass.pl \
  local/perl-unicode/lib/unicore/Decomposition.pl \
  bin/lib/Unicode/Normalize.pm

unicode-prop-list-3.2: local/unicode/3.2/PropList.txt
	$(PERL) bin/generate-prop-list.pl 3.2 $<
unicode-prop-list-5.0: local/unicode/5.0/PropList.txt
	$(PERL) bin/generate-prop-list.pl 5.0 $<
unicode-prop-list-5.2: local/unicode/5.2/PropList.txt
	$(PERL) bin/generate-prop-list.pl 5.2 $<
unicode-prop-list-latest: local/unicode/latest/PropList.txt \
    local/unicode/latest/DerivedCoreProperties.txt \
    local/unicode/latest/DerivedNormalizationProps.txt
	$(PERL) bin/generate-prop-list.pl latest local/unicode/latest/PropList.txt
	$(PERL) bin/generate-prop-list.pl latest local/unicode/latest/DerivedCoreProperties.txt
	$(PERL) bin/generate-prop-list.pl latest local/unicode/latest/DerivedNormalizationProps.txt

local/unicode/3.2/PropList.txt:
	mkdir -p local/unicode/3.2
	$(WGET) -O $@ http://www.unicode.org/Public/3.2-Update/PropList-3.2.0.txt
local/unicode/5.0/PropList.txt:
	mkdir -p local/unicode/5.0
	$(WGET) -O $@ http://www.unicode.org/Public/5.0.0/ucd/PropList.txt
local/unicode/5.2/PropList.txt:
	mkdir -p local/unicode/5.0
	$(WGET) -O $@ http://www.unicode.org/Public/5.2.0/ucd/PropList.txt
local/unicode/latest/PropList.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/PropList.txt

local/unicode/latest/CaseFolding.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/CaseFolding.txt
local/unicode/latest/DerivedCoreProperties.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/DerivedCoreProperties.txt
local/unicode/latest/DerivedNormalizationProps.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UCD/latest/ucd/DerivedNormalizationProps.txt

src/set/rfc5892/Unstable.expr: bin/idna2008-unstable.pl \
    bin/lib/Charinfo/Set.pm $(PERL_UNICODE_NORMALIZE)
# data/maps.json
	$(PERL) bin/idna2008-unstable.pl > $@

UNICODE_VERSION = XXXVERSIONNOTSPECIFIEDXXX

local/iana-idna/$(UNICODE_VERSION).xml:
	mkdir -p local/iana-idna
	$(WGET) -O $@ http://www.iana.org/assignments/idna-tables-$(UNICODE_VERSION)/idna-tables-$(UNICODE_VERSION).xml
local/iana-idna/latest.xml:
	mkdir -p local/iana-idna
	$(WGET) -O $@ http://www.iana.org/assignments/idna-tables/idna-tables.xml

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

data/sets.json: bin/sets.pl \
    bin/lib/Charinfo/Name.pm bin/lib/Charinfo/Set.pm \
    src/set/rfc5892/Unstable.expr \
    src/set/unicode/Block/files \
    src/set/unicode/Hangul_Syllable_Type/files \
    src/set/unicode/Canonical_Combining_Class/files \
    src/set/unicode/has_canon_decomposition.expr \
    src/set/unicode/has_compat_decomposition.expr \
    src/set/uax31/files \
    src/set/idna-tables-latest/files \
    src/set/*/*.expr data/names.json
	$(PERL) bin/sets.pl > $@

data/maps.json: bin/maps.pl local/unicode/latest/UnicodeData.txt \
    local/unicode/latest/SpecialCasing.txt \
    local/unicode/latest/DerivedNormalizationProps.txt \
    local/unicode/latest/CaseFolding.txt \
    data/sets.json src/tn1150table.txt src/tn1150lowercase.json
	$(PERL) bin/maps.pl > $@

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
#	$(PROVE) t/*.t