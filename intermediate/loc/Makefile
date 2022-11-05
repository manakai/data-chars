ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/ilo
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly:

build: $(TEMP_PATH) maps.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/eacc2uni.txt:
	$(SAVEURL) $@ http://memory.loc.gov/diglib/codetables/eacc2uni.txt
$(TEMP_PATH)/marcpua1.html:
	$(SAVEURL) $@ https://www.loc.gov/marc/specifications/specchar.chg9-04.html

maps.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/eacc2uni.txt \
    $(TEMP_PATH)/marcpua1.html
	$(PERL) $< > $@

## License: Public Domain.
