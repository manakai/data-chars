ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iad
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly:

build: $(TEMP_PATH) maps.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/aj17.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-Japan1-7/cid2code.txt

$(TEMP_PATH)/aj17-kanji.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-Japan1/master/aj17-kanji.txt

$(TEMP_PATH)/aj20.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/deprecated/Adobe-Japan2-0/cid2code.txt

$(TEMP_PATH)/ac17.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-CNS1-7/cid2code.txt

$(TEMP_PATH)/ag15.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/cmap-resources/master/Adobe-GB1-5/cid2code.txt

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
	$(SAVEURL) $@ https://raw.githubusercontent.com/adobe-type-tools/Adobe-GB1/master/GSUB/ag15-gsub.fea

$(TEMP_PATH)/akr9.fea:
	$(SAVEURL) $@ https://github.com/adobe-type-tools/Adobe-KR/raw/master/GSUB/akr9-gsub.fea
$(TEMP_PATH)/akr9-hangul.txt:
	$(SAVEURL) $@ https://github.com/adobe-type-tools/Adobe-KR/raw/master/akr9-hangul.txt

maps.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/aj17.txt $(TEMP_PATH)/aj17-kanji.txt $(TEMP_PATH)/aj20.txt \
    $(TEMP_PATH)/ac17.txt $(TEMP_PATH)/ag15.txt \
    $(TEMP_PATH)/ak9.txt $(TEMP_PATH)/ak12.txt \
    $(TEMP_PATH)/aj-vs.txt $(TEMP_PATH)/ac-vs.txt \
    $(TEMP_PATH)/ag-vs.txt $(TEMP_PATH)/ak-vs.txt \
    $(TEMP_PATH)/ac17.fea $(TEMP_PATH)/ag15.fea \
    $(TEMP_PATH)/aj17.fea \
    $(TEMP_PATH)/akr9.fea \
    $(TEMP_PATH)/akr9-hangul.txt
	$(PERL) $< > $@

## License: Public Domain.