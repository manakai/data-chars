ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/ijp
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: variants.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/nyukanseiji.json: $(TEMP_PATH)
	$(SAVEURL) $@ https://raw.githubusercontent.com/mandel59/nyukanseiji/main/nyukanseiji.json

variants.list: variants.pl $(VGEN_PATH)/chars.pl \
    doukun-*.txt \
    $(TEMP_PATH)/nyukanseiji.json
	$(PERL) $< > $@

## License: Public Domain.
