ROOT_PATH = ../..
PERL5OPTS =  \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib
PERL = $(ROOT_PATH)/perl $(PERL5OPTS)
PROVE = $(ROOT_PATH)/prove $(PERL5OPTS)
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen

WGET = wget
SAVEURL = $(WGET) -O

all: merged-misc.json cluster-root.json cluster-props-*.txt \
    char-cluster.jsonl \
    char-leaders.jsonl \
    testdata.json \
    tbl-clusters.dat tbl-rels.dat tbl-root.json

merged-misc.json: $(VGEN_PATH)/merged.pl \
    input.json \
    ../unicode/variants.json \
    ../mj/variants.json \
    ../cjkvi/variants.json \
    ../wikimedia/variants.json \
    ../misc/variants.json
	$(PERL) $<
merged-rels-*.jsonl: merged-misc.json

cluster-root.json: $(VGEN_PATH)/clusters.pl merged-misc.json \
    merged-rels-*.jsonl
	$(PERL) $<
cluster-chars-*.txt: cluster-root.json
cluster-rels-*.jsonl: cluster-root.json

cluster-props-*.txt: cluster-props.pl cluster-chars-*.txt merged-misc.json
	$(PERL) $<

char-cluster.jsonl: $(VGEN_PATH)/char-cluster.pl cluster-root.json \
    cluster-chars-*.txt
	$(PERL) $< > $@

char-leaders.jsonl: char-leaders.pl cluster-root.json cluster-props-*.txt
	$(PERL) $< > $@

testdata.json: $(VGEN_PATH)/testdata.pl cluster-root.json tests.txt
	$(PERL) $< > $@

tbl-clusters.dat tbl-rels.dat tbl-root.json:: %: $(VGEN_PATH)/tbl.pl \
    cluster-root.json char-cluster.jsonl merged-rels-*.jsonl
	$(PERL) $<

test: $(VGEN_PATH)/test.pl cluster-root.json char-cluster.jsonl testdata.json \
    test-size
	$(PROVE) $<
perl-test: $(VGEN_PATH)/test.pl cluster-root.json char-cluster.jsonl \
    testdata.json
	$(PERL) $<
test-size:
	cd $(ROOT_PATH) && $(MAKE) test-size

## License: Public Domain.
