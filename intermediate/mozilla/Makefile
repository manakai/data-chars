ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/imz
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly: 

build: $(TEMP_PATH) maps.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/b5-1984.txt:
	$(SAVEURL) $@ https://moztw.org/docs/big5/table/big5_1984.txt
$(TEMP_PATH)/b5-uao250.txt:
	$(SAVEURL) $@ https://moztw.org/docs/big5/table/uao250-b2u.txt

maps.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/b5-1984.txt \
    $(TEMP_PATH)/b5-uao250.txt \
    ../misc/b5-map-1.txt
	$(PERL) $< > $@

## License: Public Domain.
