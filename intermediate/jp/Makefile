ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/ijp
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build: variants-0.list

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

$(TEMP_PATH)/hyougai.pdf:
	$(SAVEURL) $@ https://www.bunka.go.jp/kokugo_nihongo/sisaku/joho/joho/kakuki/22/pdf/jitaihyo.pdf
$(TEMP_PATH)/hyougai.xml: $(TEMP_PATH)/hyougai.pdf
	pdftohtml $< $@ -xml
hyougai-table.json: hyougai-table.pl $(TEMP_PATH)/hyougai.xml
	$(PERL) $< > $@

$(TEMP_PATH)/jouyouh22.pdf:
	$(SAVEURL) $@ https://www.bunka.go.jp/kokugo_nihongo/sisaku/joho/joho/kijun/naikaku/pdf/joyokanjihyo_20101130.pdf
$(TEMP_PATH)/jouyouh22.xml: $(TEMP_PATH)/jouyouh22.pdf
	pdftohtml $< $@ -xml
jouyouh22-table.json: jouyouh22-table.pl $(TEMP_PATH)/jouyouh22.xml
	$(PERL) $< > $@

variants-0.list: variants.pl $(VGEN_PATH)/chars.pl \
    doukun-*.txt \
    $(TEMP_PATH)/nyukanseiji.json \
    jissyukutaimap1_0_0.xslx.tsv \
    ../../local/jis-0208.txt \
    $(TEMP_PATH)/nihuINT.tsv \
    $(ROOT_PATH)/data/sets.json \
    hyougai-table.json \
    hyougai-mapping.txt \
    jouyouh22-table.json \
    jouyouh22-mapping.txt \
    jiskouki-mapping.txt \
    jinmeih16-mapping.txt \
    heisei-fallback.txt \
    jis-heisei.txt \
    jisucs.txt \
    jismoved.txt \
    gsi-r060301.txt
	$(PERL) $<
variants-*.list: variants-0.list

## License: Public Domain.
