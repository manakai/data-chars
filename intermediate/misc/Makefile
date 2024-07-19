ROOT_PATH = ../..
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
TEMP_PATH = $(ROOT_PATH)/local/iwm
DATA_PATH = $(ROOT_PATH)/local/maps
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)
WGET = wget
SAVEURL = $(WGET) -O

all: build

build: $(TEMP_PATH) variants.list maps.list sets.json swc-0.list gmap.json \
    build-pages

build-nightly: build

build-pages: $(TEMP_PATH) \
    $(DATA_PATH)/codes.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/dict.ts:
	$(SAVEURL) $@ https://raw.githubusercontent.com/geolonia/normalize-japanese-addresses/master/src/lib/dictionaries/jisDai2.ts

$(TEMP_PATH)/swglyphs.json:
	$(SAVEURL) $@ https://raw.githubusercontent.com/suikawiki/extracted/master/data/extracted/data-glyph-.json
$(TEMP_PATH)/swchars.json:
	$(SAVEURL) $@ https://raw.githubusercontent.com/suikawiki/extracted/master/data/extracted/data-p8sx0v.json
$(TEMP_PATH)/swjinmeikana.json:
	$(SAVEURL) $@ https://raw.githubusercontent.com/suikawiki/extracted/8433de52e653498c99769612c7e05d6f9db511b7/data/extracted/data-gmqueu7nba.json

variants.list: variants.pl $(VGEN_PATH)/chars.pl \
    $(ROOT_PATH)/src/han-variants.txt \
    $(ROOT_PATH)/src/other-variants.txt \
    $(ROOT_PATH)/src/doukun.txt \
    kakekotoba.txt engo.txt \
    $(TEMP_PATH)/dict.ts
	$(PERL) $< > $@

maps.list: maps.pl $(VGEN_PATH)/chars.pl \
    aribchars.txt \
    aribothers.txt \
    hngl.txt \
    ak1.txt \
    b5-map-*.txt \
    ccciiv.txt ccciim.txt \
    tron-kana.txt \
    kana.txt
	$(PERL) $< > $@

sets.json: sets.pl $(VGEN_PATH)/chars.pl \
    $(ROOT_PATH)/data/sets.json
	$(PERL) $< > $@

$(DATA_PATH)/codes.list: codes.pl $(VGEN_PATH)/chars.pl
	mkdir -p $(DATA_PATH)
	$(PERL) $< > $@

gmap.json: gmap.pl gmap.txt
	$(PERL) $< > $@

swc-0.list: swc.pl \
    $(TEMP_PATH)/swglyphs.json \
    $(TEMP_PATH)/swchars.json \
    $(TEMP_PATH)/swjinmeikana.json
	$(PERL) $<

## License: Public Domain.
