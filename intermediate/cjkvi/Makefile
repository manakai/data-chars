ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/icjkvi
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib

WGET = wget
SAVEURL = $(WGET) -O

all: $(TEMP_PATH) variants.json

$(TEMP_PATH):
	mkdir -p $@

repo:
	cd $(TEMP_PATH) && \
	(git clone https://github.com/cjkvi/cjkvi-variants repo || \
	(cd repo && git pull))
$(TEMP_PATH)/variants.txt:
	$(SAVEURL) $@ http://kanji-database.sourceforge.net/variants/variants.txt

variants.json: variants.pl \
    $(TEMP_PATH)/variants.txt \
    repo $(TEMP_PATH)/repo/*.txt
	$(PERL) $< > $@

## License: Public Domain.
