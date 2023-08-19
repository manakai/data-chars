ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iwh
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
DATA_PATH = $(ROOT_PATH)/local/maps
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build: $(TEMP_PATH) components-0.list maps-0.list

build-nightly:

build-pages:

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/wadalab.tar.gz:
	$(SAVEURL) $@ https://gps.tanaka.ecc.u-tokyo.ac.jp/wadalabfont/viewcvs/viewcvs.cgi/root.tar.gz?view=tar
$(TEMP_PATH)/wadalabfont-kit: $(TEMP_PATH)/wadalab.tar.gz
	cd $(TEMP_PATH) && tar zxf wadalab.tar.gz
	touch $@
$(TEMP_PATH)/wadalabfont-kit/jointdata/alljoint.l: $(TEMP_PATH)/wadalabfont-kit
$(TEMP_PATH)/wadalabfont-kit/jointdata/jis3-0.l: $(TEMP_PATH)/wadalabfont-kit
$(TEMP_PATH)/wadalabfont-kit/jointdata/jis3-1.l: $(TEMP_PATH)/wadalabfont-kit
$(TEMP_PATH)/wadalabfont-kit/jointdata/jis3-2.l: $(TEMP_PATH)/wadalabfont-kit
$(TEMP_PATH)/wadalabfont-kit/jointdata/jis3-3.l: $(TEMP_PATH)/wadalabfont-kit

components-0.list: components.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/wadalabfont-kit/jointdata/alljoint.l \
    $(TEMP_PATH)/wadalabfont-kit/jointdata/jis3-*.l
	$(PERL) $<
components-*.list: components-0.list

maps-0.list: maps.pl $(VGEN_PATH)/chars.pl \
    inherited-tables.json
	$(PERL) $<

## License: Public Domain.
