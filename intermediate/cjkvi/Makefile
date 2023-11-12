ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/icjkvi
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
DATA_PATH = $(ROOT_PATH)/local/maps
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: $(TEMP_PATH) repos variants-0.list hd-0.list maps-0.list \
    ids-0.list build-pages

build-nightly:

build-pages: $(TEMP_PATH) $(DATA_PATH)/idsc-0.list

$(TEMP_PATH):
	mkdir -p $@

repos: $(TEMP_PATH)
	cd $(TEMP_PATH) && \
	(git clone https://github.com/cjkvi/cjkvi-variants || \
	(cd cjkvi-variants && git pull))
	cd $(TEMP_PATH) && \
	(git clone https://github.com/cjkvi/cjkvi-data || \
	(cd cjkvi-data && git pull))
	cd $(TEMP_PATH) && \
	(git clone https://github.com/cjkvi/cjkvi-ids || \
	(cd cjkvi-ids && git pull))
	cd $(TEMP_PATH) && \
	(git clone https://github.com/cjkvi/cjkvi-dict || \
	(cd cjkvi-dict && git pull))
$(TEMP_PATH)/variants.txt:
	$(SAVEURL) $@ http://kanji-database.sourceforge.net/variants/variants.txt
$(TEMP_PATH)/hd2ucs.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/cjkvi/cjkvi-data/c9b9359a46d720f5a5a81d85cb5e79e93b3efdcf/hd2ucs.txt

$(TEMP_PATH)/radically-ids:
	git clone https://github.com/Transfusion/cjkvi-ids-unicode $@

$(TEMP_PATH)/ids-20230408.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/hfhchan/ids/main/release/ids-20230408.txt

$(TEMP_PATH)/ids_lv0.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/yi-bai/ids/main/ids_lv0.txt
$(TEMP_PATH)/ids_lv1.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/yi-bai/ids/main/ids_lv1.txt
$(TEMP_PATH)/ids_lv2.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/yi-bai/ids/main/ids_lv2.txt

$(TEMP_PATH)/babel-ids.txt:
	$(SAVEURL) $@ https://www.babelstone.co.uk/CJK/IDS.TXT

variants-0.list: variants.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/variants.txt \
    $(TEMP_PATH)/cjkvi-data/gb2ucs.txt \
    $(TEMP_PATH)/cjkvi-data/nom_qn.txt \
    $(TEMP_PATH)/cjkvi-variants/*.txt
	$(PERL) $<
variants-*.list: variants-0.list

maps-0.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/cjkvi-dict/kx2ucs.txt \
    $(TEMP_PATH)/cjkvi-dict/dkw2ucs.txt
	$(PERL) $<
maps-*.list: maps-0.list

hd-0.list: hd.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/hd2ucs.txt \
    $(TEMP_PATH)/cjkvi-data/hducs2ivs.txt \
    $(TEMP_PATH)/cjkvi-data/hducs2juki.txt \
    $(TEMP_PATH)/cjkvi-data/hducs2koseki.txt \
    $(TEMP_PATH)/cjkvi-ids/hanyo-ids.txt
	$(PERL) $<
hd-*.list: hd-0.list

ids-0.list: ids.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/radically-ids \
    $(TEMP_PATH)/ids-20230408.txt \
    $(TEMP_PATH)/ids_lv0.txt \
    $(TEMP_PATH)/ids_lv1.txt \
    $(TEMP_PATH)/ids_lv2.txt \
    $(TEMP_PATH)/babel-ids.txt \
    $(TEMP_PATH)/cjkvi-ids/ids.txt \
    $(TEMP_PATH)/cjkvi-ids/ids-cdp.txt \
    $(TEMP_PATH)/cjkvi-ids/ids-ext-cdef.txt \
    $(TEMP_PATH)/cjkvi-ids/ws2015-ids.txt \
    $(TEMP_PATH)/cjkvi-ids/ws2015-ids-cdp.txt \
    $(TEMP_PATH)/cjkvi-ids/waseikanji-ids.txt
	$(PERL) $<
ids-*.list: ids-0.list

$(DATA_PATH)/idsc-0.list: idsc.pl $(VGEN_PATH)/chars.pl
#    ids-0.list hd-ids.list variants-ids.list
	$(PERL) $<
idsc-*.list: idsc-0.list

## License: Public Domain.
