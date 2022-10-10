ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/icns
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly: build

build: $(TEMP_PATH) maps.json

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/cns.zip:
	$(SAVEURL) $@ https://www.cns11643.gov.tw/AIDB/Open_Data.zip
$(TEMP_PATH)/cns-0.txt: $(TEMP_PATH)/cns.zip
	cd $(TEMP_PATH) && unzip cns.zip Open_Data/MapingTables/Unicode/CNS2UNICODE_Unicode\ BMP.txt
	mv $(TEMP_PATH)/Open_Data/MapingTables/Unicode/CNS2UNICODE_Unicode\ BMP.txt $@
	touch $@
$(TEMP_PATH)/cns-2.txt: $(TEMP_PATH)/cns.zip
	cd $(TEMP_PATH) && unzip cns.zip Open_Data/MapingTables/Unicode/CNS2UNICODE_Unicode\ 2.txt
	mv $(TEMP_PATH)/Open_Data/MapingTables/Unicode/CNS2UNICODE_Unicode\ 2.txt $@
	touch $@
$(TEMP_PATH)/cns-15.txt: $(TEMP_PATH)/cns.zip
	cd $(TEMP_PATH) && unzip cns.zip Open_Data/MapingTables/Unicode/CNS2UNICODE_Unicode\ 15.txt
	mv $(TEMP_PATH)/Open_Data/MapingTables/Unicode/CNS2UNICODE_Unicode\ 15.txt $@
	touch $@

maps.json: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/cns-0.txt $(TEMP_PATH)/cns-2.txt $(TEMP_PATH)/cns-15.txt
	$(PERL) $< > $@

## License: Public Domain.
