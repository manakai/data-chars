# -*- Makefile -*-

all: deps all-data
clean: clean-data

## ------ Setup ------

WGET = wget
GIT = git
PERL = ./perl

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
    unicode-prop-list-latest data/sets.json data/names.json

clean-data:
	rm -fr local/ucd/touch local/langtags.json local/tr31.html
	rm -fr local/unicode/latest

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

local/langtags.json:
	$(WGET) -O $@ https://raw.github.com/manakai/data-web-defs/master/data/langtags.json

data/scripts.json: bin/scripts.pl local/ucd/Scripts.txt \
    local/ucd/PropertyValueAliases.txt local/tr31.html \
    local/langtags.json
	$(PERL) bin/scripts.pl > $@

local/unicode/latest/NamesList.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UNIDATA/NamesList.txt
local/unicode/latest/NameAliases.txt:
	mkdir -p local/unicode/latest
	$(WGET) -O $@ http://www.unicode.org/Public/UNIDATA/NameAliases.txt

data/names.json: local/unicode/latest/NamesList.txt \
    local/unicode/latest/NameAliases.txt \
    bin/names.pl
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

unicode-prop-list-3.2: local/unicode/3.2/PropList.txt
	$(PERL) bin/generate-prop-list.pl 3.2 $<
unicode-prop-list-5.0: local/unicode/5.0/PropList.txt
	$(PERL) bin/generate-prop-list.pl 5.0 $<
unicode-prop-list-5.2: local/unicode/5.2/PropList.txt
	$(PERL) bin/generate-prop-list.pl 5.2 $<
unicode-prop-list-latest: local/unicode/latest/PropList.txt
	$(PERL) bin/generate-prop-list.pl latest $<

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

data/sets.json: bin/sets.pl \
    bin/lib/Charinfo/Name.pm bin/lib/Charinfo/Set.pm \
    src/set/*/*.expr
	$(PERL) bin/sets.pl > $@

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
#	$(PROVE) t/*.t