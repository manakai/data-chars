ROOT_PATH = ../..
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
TEMP_PATH = $(ROOT_PATH)/local/iwm
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)
WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly: build

build: variants.list maps.list sets.json

$(TEMP_PATH)/dict.ts:
	$(SAVEURL) $@ https://raw.githubusercontent.com/geolonia/normalize-japanese-addresses/master/src/lib/dict.ts

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

## License: Public Domain.
