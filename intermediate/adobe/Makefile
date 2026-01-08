ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iad
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly:

build: $(TEMP_PATH) maps-0.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/aj17.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-Japan1-7/cid2code.txt

$(TEMP_PATH)/aj17-kanji.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-Japan1/master/aj17-kanji.txt

$(TEMP_PATH)/aj20.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/deprecated/Adobe-Japan2-0/cid2code.txt
$(TEMP_PATH)/jisx0212-jp90.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-Japan1-7/jisx0212-jp90.txt
$(TEMP_PATH)/jisx0212-jp04.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-Japan1-7/jisx0212-jp04.txt

$(TEMP_PATH)/ac17.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-CNS1-7/cid2code.txt

$(TEMP_PATH)/ag15.txt:
	#$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-GB1-5/cid2code.txt
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/accdf06a1aee73ce53be2e0c1ff14fb2a2b96cdd/Adobe-GB1-5/cid2code.txt
$(TEMP_PATH)/ag16.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-GB1-6/cid2code.txt

$(TEMP_PATH)/ak9.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-KR-9/cid2code.txt

$(TEMP_PATH)/ak12.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-Korea1-2/cid2code.txt

$(TEMP_PATH)/aj-vs.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-Japan1/master/Adobe-Japan1_sequences.txt

$(TEMP_PATH)/ac-vs.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-CNS1/master/Adobe-CNS1_sequences.txt

$(TEMP_PATH)/ag-vs.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-GB1/master/Adobe-GB1_sequences.txt

$(TEMP_PATH)/ak-vs.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-KR/master/Adobe-KR_sequences.txt

$(TEMP_PATH)/aj17.fea:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-Japan1/master/GSUB/aj17-gsub.fea

$(TEMP_PATH)/ac17.fea:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-CNS1/master/GSUB/ac17-gsub.fea

$(TEMP_PATH)/ag15.fea:
	#$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-GB1/master/GSUB/ag15-gsub.fea
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-GB1/463318291007e231fd9a11d0e70d657455a9a586/GSUB/ag15-gsub.fea
$(TEMP_PATH)/ag16.fea:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-GB1/master/GSUB/ag16-gsub.fea

$(TEMP_PATH)/akr9.fea:
	$(SAVEURL) $@ https://github.com/adobe-type-tools/Adobe-KR/raw/master/GSUB/akr9-gsub.fea
$(TEMP_PATH)/akr9-hangul.txt:
	$(SAVEURL) $@ https://github.com/adobe-type-tools/Adobe-KR/raw/master/akr9-hangul.txt

$(TEMP_PATH)/aglfn.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/agl-aglfn/master/aglfn.txt
$(TEMP_PATH)/glyphlist.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/agl-aglfn/master/glyphlist.txt

$(TEMP_PATH)/opentype.js:
	$(SAVEURL) $@ https://raw.githubusercontent.com/manakai/opentypejs/master/dist/opentype.js
$(TEMP_PATH)/dumpotf.js: dumpotf.js
	cp $< $@

$(TEMP_PATH)/kml.zip:
	#$(SAVEURL) $@ http://www.akenotsuki.com/eyeben/fonts/files/KiriMinL4_002.zip
	$(SAVEURL) $@ https://www.akenotsuki.com/eyeben/fonts/files/KiriMinL4_01.zip

$(TEMP_PATH)/KiriMinL.otf: $(TEMP_PATH)/kml.zip
	cd $(TEMP_PATH) && unzip kml.zip
	touch $@
$(TEMP_PATH)/KiriMinL-dump.json: $(TEMP_PATH)/KiriMinL.otf \
    $(TEMP_PATH)/dumpotf.js $(TEMP_PATH)/opentype.js
	docker run -i -v `cd $(TEMP_PATH) && pwd`:/temppath node temppath/dumpotf.js /temppath/KiriMinL.otf > $@

../jp/jouyouh22-table.json:
	cd ../jp && $(MAKE) jouyouh22-table.json

maps-0.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/aj17.txt $(TEMP_PATH)/aj17-kanji.txt $(TEMP_PATH)/aj20.txt \
    $(TEMP_PATH)/ac17.txt $(TEMP_PATH)/ag15.txt $(TEMP_PATH)/ag16.txt \
    $(TEMP_PATH)/ak9.txt $(TEMP_PATH)/ak12.txt \
    $(TEMP_PATH)/aj-vs.txt $(TEMP_PATH)/ac-vs.txt \
    $(TEMP_PATH)/ag-vs.txt $(TEMP_PATH)/ak-vs.txt \
    $(TEMP_PATH)/ac17.fea $(TEMP_PATH)/ag15.fea $(TEMP_PATH)/ag16.fea \
    $(TEMP_PATH)/aj17.fea \
    $(TEMP_PATH)/akr9.fea \
    $(TEMP_PATH)/akr9-hangul.txt \
    $(TEMP_PATH)/aglfn.txt \
    $(TEMP_PATH)/glyphlist.txt \
    $(TEMP_PATH)/KiriMinL-dump.json \
    ../jp/jouyouh22-table.json \
    $(TEMP_PATH)/jisx0212-jp90.txt \
    ivd-fallback.txt
	$(PERL) $<
maps-*.list: maps-0.list

always:

## License: Public Domain.
