ROOT_PATH = ../..
PERL5OPTS =  \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib
PERL = $(ROOT_PATH)/perl $(PERL5OPTS)
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
VGEN_DATA_PATH = $(ROOT_PATH)/local/generated/charrels

all: _build-all

build-nightly: _build-all
build-pages: _build-all

clean-pages: _clean-pages

_build-all: \
    build-chars build-components \
    build-tc1 build-tc2 \
    build-hans build-descs build-glyphs build-kanas build-kchars

build-chars:
	$(PERL) $(VGEN_PATH)/generate.pl chars-input.json
	cd $(VGEN_DATA_PATH)/chars/ && $(MAKE) all test
build-components:
	$(PERL) $(VGEN_PATH)/generate.pl components-input.json
	cd $(VGEN_DATA_PATH)/components/ && $(MAKE) all test
build-tc1:
	$(PERL) $(VGEN_PATH)/generate.pl tc1-input.json
	cd $(VGEN_DATA_PATH)/tc1/ && $(MAKE) all test
build-tc2:
	$(PERL) $(VGEN_PATH)/generate.pl tc2-input.json
	cd $(VGEN_DATA_PATH)/tc2/ && $(MAKE) all test

## OBSOLETE
build-kanas:
	$(PERL) $(VGEN_PATH)/generate.pl kanas-input.json
	cd $(VGEN_DATA_PATH)/kanas/ && $(MAKE) all test
build-kchars:
	$(PERL) $(VGEN_PATH)/generate.pl kchars-input.json
	cd $(VGEN_DATA_PATH)/kchars/ && $(MAKE) all test
build-hans:
	$(PERL) $(VGEN_PATH)/generate.pl hans-input.json
	cd $(VGEN_DATA_PATH)/hans/ && $(MAKE) all test
build-glyphs:
	$(PERL) $(VGEN_PATH)/generate.pl glyphs-input.json
	cd $(VGEN_DATA_PATH)/glyphs/ && $(MAKE) all test
build-descs:
	$(PERL) $(VGEN_PATH)/generate.pl descs-input.json
	cd $(VGEN_DATA_PATH)/descs/ && $(MAKE) all test

perl-test-chars:
	$(PERL) $(VGEN_PATH)/generate.pl chars-input.json
	cd $(VGEN_DATA_PATH)/chars/ && $(MAKE) perl-test

_clean-pages:
	cd $(VGEN_DATA_PATH)/chars/ && $(MAKE) clean-vgen-pages
	cd $(VGEN_DATA_PATH)/kanas/ && $(MAKE) clean-vgen-pages
	cd $(VGEN_DATA_PATH)/kchars/ && $(MAKE) clean-vgen-pages
	cd $(VGEN_DATA_PATH)/hans/ && $(MAKE) clean-vgen-pages
	cd $(VGEN_DATA_PATH)/glyphs/ && $(MAKE) clean-vgen-pages
	cd $(VGEN_DATA_PATH)/descs/ && $(MAKE) clean-vgen-pages
	cd $(VGEN_DATA_PATH)/components/ && $(MAKE) clean-vgen-pages

## License: Public Domain.
