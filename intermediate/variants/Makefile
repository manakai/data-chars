ROOT_PATH = ../..
PERL5OPTS =  \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib
PERL = $(ROOT_PATH)/perl $(PERL5OPTS)
PROVE = $(ROOT_PATH)/prove $(PERL5OPTS)
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen

WGET = wget
SAVEURL = $(WGET) -O

all: build-vgen

build-nightly: build-vgen-nightly
build-pages: build-vgen-pages

VGEN_MERGED_INPUTS = input.json \
    ../unicode/variants.json \
    ../unicode/namesrefs.json \
    ../mj/maps.json \
    ../mj/fmaps.json \
    ../mj/variants.json \
    ../cjkvi/variants.json \
    ../wikimedia/variants.json \
    ../misc/variants.json

build-vgen build-vgen-nightly build-vgen-pages test perl-test:: %:
	$(MAKE) -f $(VGEN_PATH)/Makefile.vgen $@ \
	    VGEN_MERGED_INPUTS="$(VGEN_MERGED_INPUTS)"

## License: Public Domain.
