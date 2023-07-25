ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/imj
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build: $(TEMP_PATH) variants.json maps-0.list fmaps-0.list kmaps.list \
    tmaps.list

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

variants.json: variants.pl $(TEMP_PATH)/mj.json $(TEMP_PATH)/map.json
	$(PERL) $< > $@

maps-0.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/mj.json \
    $(TEMP_PATH)/daikanwa-ucs.txt
	$(PERL) $<
maps-*.list: maps-0.list

fmaps-0.list: fmaps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/map.json \
    $(TEMP_PATH)/mjsu.json
	$(PERL) $<
fmaps-*.list: fmaps-0.list

tmaps.list: tmaps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/toukimap.json \
    $(TEMP_PATH)/tksu.json
	$(PERL) $< > $@

kmaps.list: kmaps.pl $(VGEN_PATH)/chars.pl \
    wakan-kana.txt \
    ninjal-kana.txt \
    mj-kana.txt \
    mj-voiced.txt \
    $(TEMP_PATH)/hikanji.txt
	$(PERL) $< > $@

## License: Public Domain.
