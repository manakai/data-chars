ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/ivn
TEMPAD_PATH = $(ROOT_PATH)/local/iad
TEMPUC_PATH = $(ROOT_PATH)/local/iuc
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
DATA_PATH = $(ROOT_PATH)/local/maps
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly:

build: $(TEMP_PATH) maps-0.list build-pages

build-pages: $(DATA_PATH) \
    $(DATA_PATH)/vietglyphs-0.list \
    $(DATA_PATH)/vietsets.json

$(TEMP_PATH):
	mkdir -p $@

$(DATA_PATH):
	mkdir -p $@

$(TEMP_PATH)/features.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/nomfoundation/font/master/src/features.txt

$(TEMP_PATH)/uvs.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/nomfoundation/font/master/src/UnicodeVariationSequences.txt
$(TEMP_PATH)/uvs.txt.2:
	$(SAVEURL) $@ https://raw.githubusercontent.com/nomfoundation/font/06838db0f1ad960adb7659072ba67c45e10b6d75/src/UnicodeVariationSequences.txt
$(TEMP_PATH)/uvs.txt.3:
	$(SAVEURL) $@ https://raw.githubusercontent.com/nomfoundation/font/10c78eaadc898794687213cf1127c73f86a1c5a4/src/UnicodeVariationSequences.txt

$(TEMPUC_PATH)/opentype.js:
	$(SAVEURL) $@ https://raw.githubusercontent.com/manakai/opentypejs/master/dist/opentype.js
$(TEMPUC_PATH)/dumpotf.js: ../adobe/dumpotf.js
	cp $< $@
$(TEMPUC_PATH)/nnt.ttf:
	$(SAVEURL) $@ https://fonts.suikawiki.org/opentype/nom-506/NomNaTong-Regular.ttf
$(TEMPUC_PATH)/nnt-dump.json: \
    $(TEMPUC_PATH)/dumpotf.js $(TEMPUC_PATH)/opentype.js \
    $(TEMPUC_PATH)/nnt.ttf
	docker run -i -v `cd $(TEMPUC_PATH) && pwd`:/temppath node temppath/dumpotf.js /temppath/nnt.ttf > $@


maps-0.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/features.txt \
    $(TEMP_PATH)/uvs.txt.2 \
    $(TEMP_PATH)/uvs.txt.3 \
    ca.txt \
    rcv.json
	$(PERL) $<

$(DATA_PATH)/vietglyphs-0.list: glyphs.pl $(VGEN_PATH)/chars.pl \
    rcv.json
	$(PERL) $<

$(DATA_PATH)/vietsets.json: sets.pl rcv.json
	$(PERL) $< > $@

## License: Public Domain.
