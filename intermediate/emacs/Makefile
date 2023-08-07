ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iemacs
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build: $(TEMP_PATH) maps-0.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/mule-ucs.tar.gz:
	$(SAVEURL) $@ https://web.archive.org/web/20060513145717if_/http://www.meadowy.org:80/%7Eshirai/elips/mule-ucs.tar.gz
$(TEMP_PATH)/mule-ucs: $(TEMP_PATH)/mule-ucs.tar.gz
	cd $(TEMP_PATH) && tar xf mule-ucs.tar.gz
$(TEMP_PATH)/mule-ucs/lisp/reldata/usisheng.el: $(TEMP_PATH)/mule-ucs
$(TEMP_PATH)/mule-ucs/lisp/reldata/uethiopic.el: $(TEMP_PATH)/mule-ucs
$(TEMP_PATH)/mule-ucs/lisp/reldata/uipa.el: $(TEMP_PATH)/mule-ucs
$(TEMP_PATH)/mule-ucs/lisp/reldata/uiscii.el: $(TEMP_PATH)/mule-ucs
$(TEMP_PATH)/mule-ucs/lisp/reldata/ulao.el: $(TEMP_PATH)/mule-ucs
$(TEMP_PATH)/mule-ucs/lisp/reldata/uviscii.el: $(TEMP_PATH)/mule-ucs

$(TEMP_PATH)/cgreek-2.tar.gz:
	$(WGET) -O $@ http://ring.ix.oita-u.ac.jp/archives/pc/meadow/2.00/packages/cgreek-2-pkg.tar.gz
$(TEMP_PATH)/cgreek-2: $(TEMP_PATH)/cgreek-2.tar.gz
	mkdir -p $@
	cd $@ && tar zxf ../cgreek-2.tar.gz
$(TEMP_PATH)/cgreek-2/site-lisp/cgreek/cgreek.el: $(TEMP_PATH)/cgreek-2
$(TEMP_PATH)/cgreek-2/site-lisp/cgreek/cgreek-util.el: $(TEMP_PATH)/cgreek-2
$(TEMP_PATH)/cgreek-2/site-lisp/cgreek/cgreek-quail.el: $(TEMP_PATH)/cgreek-2

$(TEMP_PATH)/cgreek23.tar.gz:
	$(WGET) -O $@ http://eleutherion.my.coocan.jp/lib/cgreek23.tar.gz
$(TEMP_PATH)/cgreek23: $(TEMP_PATH)/cgreek23.tar.gz
	cd $(TEMP_PATH) && tar zxf cgreek23.tar.gz
$(TEMP_PATH)/cgreek23/cgreek-misc.el: $(TEMP_PATH)/cgreek23
$(TEMP_PATH)/cgreek23/greek.el: $(TEMP_PATH)/cgreek23
$(TEMP_PATH)/cgreek23/latin.el: $(TEMP_PATH)/cgreek23
$(TEMP_PATH)/cgreek23/russian.el: $(TEMP_PATH)/cgreek23

maps-0.list: maps.pl \
    $(TEMP_PATH)/mule-ucs/lisp/reldata/usisheng.el \
    $(TEMP_PATH)/mule-ucs/lisp/reldata/uethiopic.el \
    $(TEMP_PATH)/mule-ucs/lisp/reldata/uipa.el \
    $(TEMP_PATH)/mule-ucs/lisp/reldata/uiscii.el \
    $(TEMP_PATH)/mule-ucs/lisp/reldata/ulao.el \
    $(TEMP_PATH)/mule-ucs/lisp/reldata/uviscii.el \
    $(TEMP_PATH)/cgreek-2/site-lisp/cgreek/cgreek.el \
    $(TEMP_PATH)/cgreek-2/site-lisp/cgreek/cgreek-util.el \
    $(TEMP_PATH)/cgreek-2/site-lisp/cgreek/cgreek-quail.el \
    $(TEMP_PATH)/cgreek23/cgreek-misc.el \
    $(TEMP_PATH)/cgreek23/greek.el \
    $(TEMP_PATH)/cgreek23/latin.el \
    $(TEMP_PATH)/cgreek23/russian.el
	$(PERL) $<

always:

## License: Public Domain.
