ROOT_PATH = ../..
DATA_PATH = $(ROOT_PATH)/intermediate/variants
PERL5OPTS =  \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib
PERL = $(ROOT_PATH)/perl $(PERL5OPTS)

all: ivar list.html list-rels.html

ivar:
	cd ../../intermediate/misc && $(MAKE) all
	cd ../../intermediate/variants && $(MAKE) all test

list.html: generate.pl \
    $(DATA_PATH)/cluster-root.json \
    $(DATA_PATH)/cluster-chars-*.txt \
    $(DATA_PATH)/cluster-props-*.txt
	$(PERL) $< > $@
list-html-*.txt: list.html
list-rels.html: generate.pl \
    $(DATA_PATH)/cluster-root.json \
    $(DATA_PATH)/cluster-chars-*.txt \
    $(DATA_PATH)/cluster-props-*.txt \
    $(DATA_PATH)/cluster-rels-*.jsonl
	WITH_RELS=1 $(PERL) $< > $@
list-rels-html-*.txt: list-rels.html

perl-test:
	cd ../../intermediate/variants && $(MAKE) perl-test

## License: Public Domain.
