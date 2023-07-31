ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/ijp
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: variants-0.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/nyukanseiji.json: $(TEMP_PATH)
	$(SAVEURL) $@ https://raw.githubusercontent.com/mandel59/nyukanseiji/main/nyukanseiji.json

$(TEMP_PATH)/nihuINT.zip:
	$(SAVEURL) $@ https://www.bridge.nihu.jp/researchdata/file/20221125_ITOBYb
$(TEMP_PATH)/nihuINT: $(TEMP_PATH)/nihuINT.zip
	mkdir -p $@
	cd $(TEMP_PATH)/nihuINT && unzip ../nihuINT.zip
$(TEMP_PATH)/nihuINT.tsv: $(TEMP_PATH)/nihuINT
	cp $(TEMP_PATH)/nihuINT/*TSV*.txt $@

../../local/jis-0208.txt:
	cd ../.. && $(MAKE) local/jis-0208.txt

variants-0.list: variants.pl $(VGEN_PATH)/chars.pl \
    doukun-*.txt \
    $(TEMP_PATH)/nyukanseiji.json \
    jissyukutaimap1_0_0.xslx.tsv \
    ../../local/jis-0208.txt \
    $(TEMP_PATH)/nihuINT.tsv \
    $(ROOT_PATH)/data/sets.json
	$(PERL) $<
variants-*.list: variants-0.list

## License: Public Domain.
