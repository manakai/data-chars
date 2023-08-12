ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iwh
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly:

build: $(TEMP_PATH) maps.list entities-0.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/index-big5.txt:
	$(SAVEURL) $@ https://encoding.spec.whatwg.org/index-big5.txt
$(TEMP_PATH)/html-charrefs.json:
	$(SAVEURL) $@ https://html.spec.whatwg.org/entities.json

$(TEMP_PATH)/unicode.xml:
	$(SAVEURL) $@ https://raw.githubusercontent.com/w3c/xml-entities/gh-pages/unicode.xml

maps.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/index-big5.txt \
    ../misc/b5-map-1.txt
	$(PERL) $< > $@

entities-0.list: entities.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/html-charrefs.json \
    $(TEMP_PATH)/unicode.xml
	$(PERL) $<
entities-*.list: entities-0.list

## License: Public Domain.
