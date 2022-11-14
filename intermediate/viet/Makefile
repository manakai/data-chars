ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/ivn
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly:

build: $(TEMP_PATH) maps.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/features.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/nomfoundation/font/master/src/features.txt

$(TEMP_PATH)/uvs.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/nomfoundation/font/master/src/UnicodeVariationSequences.txt

maps.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/features.txt \
    $(TEMP_PATH)/uvs.txt \
    ca.txt
	$(PERL) $< > $@

## License: Public Domain.
