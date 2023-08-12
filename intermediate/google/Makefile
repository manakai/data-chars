ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iad
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
DATA_PATH = $(ROOT_PATH)/local/maps
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build: $(TEMP_PATH) $(DATA_PATH)/dsf-0.list

build-nightly:

build-pages: $(TEMP_PATH) $(DATA_PATH)/dsf-0.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/opentype.js:
	$(SAVEURL) $@ https://data.suikawiki.org/js/opentype.js
$(TEMP_PATH)/dumpotfg.js: dumpotfg.js
	cp $< $@

$(TEMP_PATH)/DroidSansFallback-ff.ttf:
	$(SAVEURL) $@ https://fonts.suikawiki.org/opentype/DroidSansFallback/DroidSansFallback-ff.ttf
$(TEMP_PATH)/DroidSansFallback-ff-dump.json: \
    $(TEMP_PATH)/DroidSansFallback-ff.ttf \
    $(TEMP_PATH)/dumpotfg.js $(TEMP_PATH)/opentype.js
	docker run -it -v `cd $(TEMP_PATH) && pwd`:/temppath node temppath/dumpotfg.js /temppath/DroidSansFallback-ff.ttf > $@

$(TEMP_PATH)/DroidSansFallback-aosp.ttf:
	$(SAVEURL) $@ https://fonts.suikawiki.org/opentype/DroidSansFallback/DroidSansFallback-aosp.ttf
$(TEMP_PATH)/DroidSansFallback-aosp-dump.json: \
    $(TEMP_PATH)/DroidSansFallback-aosp.ttf \
    $(TEMP_PATH)/dumpotfg.js $(TEMP_PATH)/opentype.js
	docker run -it -v `cd $(TEMP_PATH) && pwd`:/temppath node temppath/dumpotfg.js /temppath/DroidSansFallback-aosp.ttf > $@

$(TEMP_PATH)/DroidSansFallbackFull-aosp.ttf:
	$(SAVEURL) $@ https://fonts.suikawiki.org/opentype/DroidSansFallback/DroidSansFallbackFull-aosp.ttf
$(TEMP_PATH)/DroidSansFallbackFull-aosp-dump.json: \
    $(TEMP_PATH)/DroidSansFallbackFull-aosp.ttf \
    $(TEMP_PATH)/dumpotfg.js $(TEMP_PATH)/opentype.js
	docker run -it -v `cd $(TEMP_PATH) && pwd`:/temppath node temppath/dumpotfg.js /temppath/DroidSansFallbackFull-aosp.ttf > $@

$(DATA_PATH)/dsf-0.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/DroidSansFallback-ff-dump.json \
    $(TEMP_PATH)/DroidSansFallback-aosp-dump.json \
    $(TEMP_PATH)/DroidSansFallbackFull-aosp-dump.json
	$(PERL) $<
$(DATA_PATH)/dsf-*.list: $(DATA_PATH)/dsf-0.list

## License: Public Domain.
