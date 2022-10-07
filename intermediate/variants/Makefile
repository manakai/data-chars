ROOT_PATH = ../..
PERL5OPTS =  \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib
PERL = $(ROOT_PATH)/perl $(PERL5OPTS)
PROVE = $(ROOT_PATH)/prove $(PERL5OPTS)
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen

WGET = wget
SAVEURL = $(WGET) -O

all: build-vgen \
    cluster-props-*.txt \
    char-leaders.jsonl char-leaders-part-*.jsonl

build-nightly: build-vgen-nightly
build-pages: build-vgen-pages

VGEN_MERGED_INPUTS = input.json \
    ../unicode/variants.json \
    ../mj/variants.json \
    ../cjkvi/variants.json \
    ../wikimedia/variants.json \
    ../misc/variants.json

cluster-root.json cluster-chars-*.txt merged-misc.json \
build-vgen build-vgen-nightly build-vgen-pages test perl-test:: %:
	$(MAKE) -f $(VGEN_PATH)/Makefile.vgen $@ \
	    VGEN_MERGED_INPUTS="$(VGEN_MERGED_INPUTS)"

cluster-props-*.txt: cluster-props.pl cluster-chars-*.txt merged-misc.json
	$(PERL) $<

char-leaders.jsonl: char-leaders.pl cluster-root.json cluster-props-*.txt
	$(PERL) $< > $@

char-leaders-part-*.jsonl: $(VGEN_PATH)/split-jsonl.pl \
    char-leaders.jsonl
	$(PERL) $< char-leaders

## License: Public Domain.
