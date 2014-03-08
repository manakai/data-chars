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

all-data: all-ucd

clean-data:
	rm -fr local/ucd/touch local/langtags.json local/tr31.html

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

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
#	$(PROVE) t/*.t