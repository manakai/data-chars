ROOT_PATH = ../..
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
TEMPUC_PATH = $(ROOT_PATH)/local/iuc
TEMPWM_PATH = $(ROOT_PATH)/local/iwm
TEMPMJ_PATH = $(ROOT_PATH)/local/imj
TEMPCNS_PATH = $(ROOT_PATH)/local/icns
TEMPAD_PATH = $(ROOT_PATH)/local/iad
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)
WGET = wget
SAVEURL = $(WGET) -O

all: build

build: swcf-hanmin-mapping.txt $(TEMPAD_PATH)/swcf-hanmin-mapping.json

build-pages: build

IVD_VERSION = 2022-09-13
$(TEMPUC_PATH)/$(IVD_VERSION)/IVD_Sequences.txt \
$(TEMPUC_PATH)/unihan-irg-s.txt \
$(TEMPUC_PATH)/unihan-irg-g.txt \
$(TEMPUC_PATH)/unihan-irg-h.txt \
$(TEMPUC_PATH)/unihan-irg-uk.txt \
$(TEMPUC_PATH)/unihan-irg-t.txt \
$(TEMPUC_PATH)/unihan-irg-v.txt \
$(ROOT_PATH)/local/unicode/latest/StandardizedVariants.txt:: %:
	cd ../unicode && $(MAKE) $@
$(TEMPCNS_PATH)/cns-0.txt \
$(TEMPCNS_PATH)/cns-2.txt \
$(TEMPCNS_PATH)/cns-15.txt:: %:
	cd ../cns && $(MAKE) $@
$(TEMPWM_PATH)/gwrelated.txt \
$(TEMPWM_PATH)/gwalias.txt \
$(TEMPWM_PATH)/gwothers.txt:: %:
	cd ../wiki && $(MAKE) $@
$(TEMPMJ_PATH)/mjucssvs.txt:: %:
	cd ../mj && $(MAKE) $@
$(TEMPUC_PATH)/nnt-dump.json:: %:
	cd ../viet && $(MAKE) $@
$(TEMPAD_PATH)/ak-vs.txt:: %:
	cd ../adobe && $(MAKE) $@
$(TEMPAD_PATH)/BabelStoneHan-dump.json:: %:
	cd ../fonts && $(MAKE) $@
../misc/gmap.json: ../misc/gmap.txt ../misc/gmap.pl
	cd ../misc && $(MAKE) gmap.json

$(TEMPAD_PATH)/swcf-hanmin-mapping.json: swcf-hanmin-mapping.pl \
    $(TEMPUC_PATH)/$(IVD_VERSION)/IVD_Sequences.txt \
    $(TEMPUC_PATH)/unihan-irg-s.txt \
    $(TEMPUC_PATH)/unihan-irg-g.txt \
    $(TEMPUC_PATH)/unihan-irg-h.txt \
    $(TEMPUC_PATH)/unihan-irg-uk.txt \
    $(TEMPUC_PATH)/unihan-irg-t.txt \
    $(TEMPUC_PATH)/unihan-irg-v.txt \
    $(TEMPUC_PATH)/nnt-dump.json \
    $(ROOT_PATH)/local/unicode/latest/StandardizedVariants.txt \
    $(TEMPCNS_PATH)/cns-0.txt \
    $(TEMPCNS_PATH)/cns-2.txt \
    $(TEMPCNS_PATH)/cns-15.txt \
    $(TEMPWM_PATH)/gwrelated.txt \
    $(TEMPWM_PATH)/gwalias.txt \
    $(TEMPWM_PATH)/gwothers.txt \
    $(TEMPMJ_PATH)/mjucssvs.txt \
    $(TEMPAD_PATH)/ak-vs.txt \
    $(TEMPAD_PATH)/BabelStoneHan-dump.json \
    ../adobe/ivd-fallback.txt \
    ../unicode/irgn2107r2-uk.tsv \
    ../unicode/irgn2232r-uk.tsv \
    ../unicode/ucsj-heisei.txt \
    ../viet/ca.txt \
    ../jp/jisjp90.txt \
    ../jp/heisei-fallback.txt \
    ../misc/gmap.json
	IVD_VERSION=$(IVD_VERSION) $(PERL) $< > $@
swcf-hanmin-mapping.txt: $(TEMPAD_PATH)/swcf-hanmin-mapping.json gmt.pl
	$(PERL) gmt.pl $< > $@

## License: Public Domain.
