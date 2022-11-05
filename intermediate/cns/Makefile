ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/icns
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly: 

build: $(TEMP_PATH) maps.list maps2.list

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
$(TEMP_PATH)/cnsb5-0.txt: $(TEMP_PATH)/cns.zip
	cd $(TEMP_PATH) && unzip cns.zip Open_Data/MapingTables/Big5/CNS2BIG5.txt
	mv $(TEMP_PATH)/Open_Data/MapingTables/Big5/CNS2BIG5.txt $@
	touch $@
$(TEMP_PATH)/cnsb5-1.txt: $(TEMP_PATH)/cns.zip
	-unzip -o -U -p $< "Open_Data/MapingTables/Big5/CNS2BIG5_#U7b26#U865f.txt" > $@
$(TEMP_PATH)/cnsb5-2.txt: $(TEMP_PATH)/cns.zip
	-unzip -o -U -p $< "Open_Data/MapingTables/Big5/CNS2BIG5_#U4e03#U500b#U501a#U5929#U5916#U5b57.txt" > $@

maps.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/cns-0.txt $(TEMP_PATH)/cns-2.txt $(TEMP_PATH)/cns-15.txt \
    $(TEMP_PATH)/cnsb5-0.txt $(TEMP_PATH)/cnsb5-1.txt $(TEMP_PATH)/cnsb5-2.txt
	$(PERL) $<
maps2.list: maps.list

## License: Public Domain.
