ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/ipl
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly: 

build: $(TEMP_PATH) maps.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/encode.ucm:
	$(SAVEURL) $@ https://fastapi.metacpan.org/source/AUDREYT/Encode-HanExtra-0.23/ucm/cccii.ucm

maps.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/encode.ucm
	$(PERL) $< > $@

## License: Public Domain.
