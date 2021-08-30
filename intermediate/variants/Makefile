ROOT_PATH = ../..
PERL5OPTS =  \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib
PERL = $(ROOT_PATH)/perl $(PERL5OPTS)
PROVE = $(ROOT_PATH)/prove $(PERL5OPTS)

WGET = wget
SAVEURL = $(WGET) -O

all: merged-misc.json cluster-root.json cluster-props-*.txt \
    char-cluster.jsonl \
    testdata.json

merged-misc.json: merged.pl \
    ../unicode/variants.json \
    ../mj/variants.json \
    ../cjkvi/variants.json \
    ../wikimedia/variants.json \
    ../misc/variants.json
	$(PERL) $<
merged-rels-*.jsonl: merged-misc.json

cluster-root.json: clusters.pl merged-misc.json merged-rels-*.jsonl
	$(PERL) $<
cluster-chars-*.txt: cluster-root.json
cluster-rels-*.jsonl: cluster-root.json

cluster-props-*.txt: cluster-props.pl cluster-chars-*.txt merged-misc.json
	$(PERL) $<

char-cluster.jsonl: char-cluster.pl cluster-root.json cluster-chars-*.txt
	$(PERL) $< > $@

testdata.json: testdata.pl cluster-root.json tests.txt
	$(PERL) $< > $@

test: test.pl testdata.pl cluster-root.json char-cluster.jsonl testdata.json
	$(PROVE) $<

## License: Public Domain.
