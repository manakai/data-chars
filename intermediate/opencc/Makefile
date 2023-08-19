ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/ioc
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build: $(TEMP_PATH) repo
	$(MAKE) variants.list

build-nightly: $(TEMP_PATH) repo
	$(MAKE) variants.list

$(TEMP_PATH):
	mkdir -p $@

repo:
	cd $(TEMP_PATH) && \
	(git clone https://github.com/BYVoid/OpenCC repo || \
	(cd repo && git pull))

variants.list: variants.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/repo/data/dictionary/*.txt \
    $(TEMP_PATH)/repo/data/scheme/*.txt
	$(PERL) $< > $@

## License: Public Domain.
