ROOT_PATH = ../..
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib

all: variants.json

variants.json: variants.pl \
    $(ROOT_PATH)/data/maps.json \
    $(ROOT_PATH)/data/sets.json \
    $(ROOT_PATH)/src/han-variants.txt \
    aggregated.json
	$(PERL) $< > $@

## License: Public Domain.
