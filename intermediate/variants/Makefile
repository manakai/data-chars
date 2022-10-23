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
    ../unicode/variants2.list \
    ../unicode/namesrefs.list \
    ../unicode/maps.list \
    ../unicode/maps2.list \
    ../unicode/maps3.list \
    ../jp/variants.list \
    ../mj/maps.list \
    ../mj/fmaps.list \
    ../mj/variants.json \
    ../cns/maps.list \
    ../cns/maps2.list \
    ../mozilla/maps.list \
    ../whatwg/maps.list \
    ../perl/maps.list \
    ../loc/maps.list \
    ../adobe/maps.list \
    ../opencc/variants.list \
    ../cjkvi/variants.list \
    ../wiki/variants.json \
    ../wiki/maps.list \
    ../misc/variants.list \
    ../misc/aggregated.json \
    ../misc/maps.list \
    ../misc/sets.json

build-vgen build-vgen-nightly build-vgen-pages test perl-test:: %:
	$(MAKE) -f $(VGEN_PATH)/Makefile.vgen $@ \
	    VGEN_MERGED_INPUTS="$(VGEN_MERGED_INPUTS)"

## License: Public Domain.
