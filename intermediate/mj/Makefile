ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/imj
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
DATA_PATH = $(ROOT_PATH)/local/maps
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build: $(TEMP_PATH) variants.json maps-0.list fmaps-0.list kmaps.list \
    $(DATA_PATH)/imaps-0.list

build-pages: $(TEMP_PATH) \
    $(DATA_PATH)/imaps-0.list

$(TEMP_PATH):
	mkdir -p $@

#mji.00601.xlsx.xls.csv:
        ## Generated from
        ## <https://moji.or.jp/wp-content/mojikiban/oscdl/mji.00601-xlsx.zip>.
$(TEMP_PATH)/mj.json: mj.pl mji.00601.xlsx.xls.csv
	$(PERL) $< > $@

$(TEMP_PATH)/map.json:
	$(SAVEURL) $@ https://moji.or.jp/wp-content/mojikiban/oscdl/MJShrinkMap.1.2.0.json

$(TEMP_PATH)/toukimap.json:
	$(SAVEURL) $@ https://moji.or.jp/wp-content/mojikiban/oscdl/ToukiShrinkMap.1.0.0.json

$(TEMP_PATH)/mjsu.json:
	$(SAVEURL) $@ https://moji.or.jp/wp-content/mojikiban/lab/xb657/MJSU.1.2.0.json

$(TEMP_PATH)/tksu.json:
	$(SAVEURL) $@ https://moji.or.jp/wp-content/mojikiban/lab/xb657/TKSU0930.json

$(TEMP_PATH)/hikanji.txt:
	$(SAVEURL) $@ https://moji.or.jp/wp-content/mojikiban/lab/xb857/IPAmjMinchoHikanji.txt

$(TEMP_PATH)/daikanwa-ucs.txt:
	$(SAVEURL) $@ https://moji.or.jp/wp-content/mojikiban/lab/xb3428/daikanwa-ucs.txt

$(TEMP_PATH)/MJMojiJouhouIchiranhyou00101.zip:
	$(SAVEURL) $@ https://warp.ndl.go.jp/info:ndljp/pid/3488806/ossipedia.ipa.go.jp/ipamjfont/mjmojiichiran/MJMojiJouhouIchiranhyou00101.zip
$(TEMP_PATH)/mj00101.csv: $(TEMP_PATH)/MJMojiJouhouIchiranhyou00101.zip
	mkdir $(TEMP_PATH)/mj00101
	-cd $(TEMP_PATH)/mj00101 && unzip ../MJMojiJouhouIchiranhyou00101.zip
	cd $(TEMP_PATH)/mj00101 && mv MJ*/*.csv ../mj00101.csv
	touch $@
$(TEMP_PATH)/mji00501.zip:
	$(SAVEURL) $@ https://moji.or.jp/wp-content/mojikiban/oscdl/mji.00501.zip
$(TEMP_PATH)/mji00501: $(TEMP_PATH)/mji00501.zip
	mkdir -p $@
	cd $@ && unzip ../mji00501.zip
$(TEMP_PATH)/mjheisei-00101.txt: mjheisei-00101.pl $(TEMP_PATH)/mj00101.csv
	$(PERL) $< $(TEMP_PATH)/mj00101.csv > $@
$(TEMP_PATH)/mjheisei-00501.txt: mjheisei-00501.pl $(TEMP_PATH)/mji00501
	$(PERL) $< $(TEMP_PATH)/mji00501/mji.00501.xml > $@
$(TEMP_PATH)/mjivs-00501.txt: mjivs-00501.pl $(TEMP_PATH)/mji00501
	$(PERL) $< $(TEMP_PATH)/mji00501/mji.00501.xml > $@
$(TEMP_PATH)/mjdkw-00101.txt: mjdkw-00101.pl $(TEMP_PATH)/mj00101.csv
	$(PERL) $< $(TEMP_PATH)/mj00101.csv > $@

variants.json: variants.pl $(TEMP_PATH)/mj.json $(TEMP_PATH)/map.json
	$(PERL) $< > $@

maps-0.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/mj.json \
    $(TEMP_PATH)/daikanwa-ucs.txt \
    $(TEMP_PATH)/mjheisei-00101.txt \
    $(TEMP_PATH)/mjheisei-00501.txt \
    $(TEMP_PATH)/mjivs-00501.txt \
    $(TEMP_PATH)/mjdkw-00101.txt \
    mj-old.txt \
    $(TEMP_PATH)/toukimap.json \
    $(TEMP_PATH)/tksu.json
	$(PERL) $<
maps-*.list: maps-0.list

fmaps-0.list: fmaps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/map.json \
    $(TEMP_PATH)/mjsu.json
	$(PERL) $<
fmaps-*.list: fmaps-0.list

kmaps.list: kmaps.pl $(VGEN_PATH)/chars.pl \
    wakan-kana.txt \
    ninjal-kana.txt \
    mj-kana.txt \
    mj-voiced.txt \
    $(TEMP_PATH)/hikanji.txt
	$(PERL) $< > $@

$(DATA_PATH)/imaps-0.list: imaps.pl $(VGEN_PATH)/chars.pl \
    tensho-chars.txt \
    modmag-chars.txt \
    kuzushiji-chars.txt
	$(PERL) $<

## License: Public Domain.
