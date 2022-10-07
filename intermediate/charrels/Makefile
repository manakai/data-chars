ROOT_PATH = ../..
PERL5OPTS =  \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib
PERL = $(ROOT_PATH)/perl $(PERL5OPTS)
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen

all: build-vgen

build-nightly: build-vgen-nightly
build-pages: build-vgen-pages

VGEN_MERGED_INPUTS = input.json \
    ../unicode/namesrefs.json

build-vgen build-vgen-nightly build-vgen-pages test perl-test:: %:
	$(MAKE) -f $(VGEN_PATH)/Makefile.vgen $@ \
	    VGEN_MERGED_INPUTS="$(VGEN_MERGED_INPUTS)"

## License: Public Domain.
