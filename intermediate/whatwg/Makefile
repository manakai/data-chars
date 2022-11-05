ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iwh
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly:

build: $(TEMP_PATH) maps.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/index-big5.txt:
	$(SAVEURL) $@ https://encoding.spec.whatwg.org/index-big5.txt

maps.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/index-big5.txt \
    ../misc/b5-map-1.txt
	$(PERL) $< > $@

## License: Public Domain.
