ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/icjkvi
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: $(TEMP_PATH) variants.list

$(TEMP_PATH):
	mkdir -p $@

repo:
	cd $(TEMP_PATH) && \
	(git clone https://github.com/cjkvi/cjkvi-variants repo || \
	(cd repo && git pull))
$(TEMP_PATH)/variants.txt:
	$(SAVEURL) $@ http://kanji-database.sourceforge.net/variants/variants.txt
$(TEMP_PATH)/gb2ucs.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/cjkvi/cjkvi-data/master/gb2ucs.txt

variants.list: variants.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/variants.txt \
    $(TEMP_PATH)/gb2ucs.txt \
    repo $(TEMP_PATH)/repo/*.txt
	$(PERL) $< > $@

## License: Public Domain.
