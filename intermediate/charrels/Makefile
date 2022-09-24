ROOT_PATH = ../..
PERL5OPTS =  \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib
PERL = $(ROOT_PATH)/perl $(PERL5OPTS)
PROVE = $(ROOT_PATH)/prove $(PERL5OPTS)
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen

WGET = wget
SAVEURL = $(WGET) -O

all: build-nightly

build-nightly: merged-misc.json cluster-root.json \
    char-cluster.jsonl \
    testdata.json \
    tbl-clusters.dat tbl-rels.dat tbl-root.json

merged-misc.json: $(VGEN_PATH)/merged.pl input.json
	$(PERL) $<
merged-rels-*.jsonl: merged-misc.json

cluster-root.json: $(VGEN_PATH)/clusters.pl merged-misc.json \
    merged-rels-*.jsonl
	$(PERL) $<
cluster-chars-*.txt: cluster-root.json
cluster-rels-*.jsonl: cluster-root.json

char-cluster.jsonl: $(VGEN_PATH)/char-cluster.pl cluster-root.json \
    cluster-chars-*.txt
	$(PERL) $< > $@

testdata.json: $(VGEN_PATH)/testdata.pl cluster-root.json tests.txt
	$(PERL) $< > $@

test: $(VGEN_PATH)/test.pl cluster-root.json char-cluster.jsonl testdata.json
	$(PROVE) $<
perl-test: $(VGEN_PATH)/test.pl cluster-root.json char-cluster.jsonl \
    testdata.json
	$(PERL) $<

tbl-clusters.dat tbl-rels.dat tbl-root.json:: %: $(VGEN_PATH)/tbl.pl \
    cluster-root.json char-cluster.jsonl merged-rels-*.jsonl
	$(PERL) $<

## License: Public Domain.
