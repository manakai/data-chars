ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/icjkvi
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: $(TEMP_PATH) repos variants.list hd-0.list maps-0.list

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

variants.list: variants.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/variants.txt \
    $(TEMP_PATH)/cjkvi-data/gb2ucs.txt \
    $(TEMP_PATH)/cjkvi-variants/*.txt
	$(PERL) $< > $@

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

## License: Public Domain.
