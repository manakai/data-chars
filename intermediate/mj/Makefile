ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/imj
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib

WGET = wget
SAVEURL = $(WGET) -O

all: build

build: $(TEMP_PATH) variants.json maps.json

$(TEMP_PATH):
	mkdir -p $@

#mji.00601.xlsx.xls.csv:
        ## Generated from
        ## <https://moji.or.jp/wp-content/mojikiban/oscdl/mji.00601-xlsx.zip>.
$(TEMP_PATH)/mj.json: mj.pl mji.00601.xlsx.xls.csv
	$(PERL) $< > $@

$(TEMP_PATH)/map.json:
	$(SAVEURL) $@ https://moji.or.jp/wp-content/mojikiban/oscdl/MJShrinkMap.1.2.0.json

variants.json: variants.pl $(TEMP_PATH)/mj.json $(TEMP_PATH)/map.json
	$(PERL) $< > $@

maps.json: maps.pl $(TEMP_PATH)/mj.json
	$(PERL) $< > $@

## License: Public Domain.
