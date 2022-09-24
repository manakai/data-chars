ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iuc
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib

WGET = wget
SAVEURL = $(WGET) -O

all: build-nightly

build-nightly: $(TEMP_PATH) variants.json namesrefs.json

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/unihan13.zip:
	$(SAVEURL) $@ https://www.unicode.org/Public/13.0.0/ucd/Unihan.zip
$(TEMP_PATH)/Unihan13_OtherMappings.txt:: %: $(TEMP_PATH)/unihan13.zip
	mkdir -p $(TEMP_PATH)/temp13
	cd $(TEMP_PATH)/temp13 && unzip ../unihan13.zip Unihan_OtherMappings.txt
	mv $(TEMP_PATH)/temp13/Unihan_OtherMappings.txt $@
	touch $@
$(TEMP_PATH)/unihan13-krname.txt: $(TEMP_PATH)/Unihan13_OtherMappings.txt
	grep -v '^#' $< | grep kKoreanName > $@

$(TEMP_PATH)/unihan.zip:
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
$(TEMP_PATH)/Unihan_Readings.txt \
$(TEMP_PATH)/Unihan_DictionaryLikeData.txt \
$(TEMP_PATH)/Unihan_Variants.txt \
$(TEMP_PATH)/Unihan_OtherMappings.txt:: %: $(TEMP_PATH)/unihan.zip
	cd $(TEMP_PATH) && unzip unihan.zip $(notdir $@)
	touch $@
$(TEMP_PATH)/unihan-tghz2013.txt: $(TEMP_PATH)/Unihan_Readings.txt
	grep -v '^#' $< | grep kTGHZ2013 > $@
$(TEMP_PATH)/unihan-hkg.txt: $(TEMP_PATH)/Unihan_DictionaryLikeData.txt
	grep -v '^#' $< | grep kHKGlyph > $@
$(TEMP_PATH)/unihan-k0.txt: $(TEMP_PATH)/Unihan_OtherMappings.txt
	grep -v '^#' $< | grep kKSC0 > $@
$(TEMP_PATH)/unihan-g1.txt: $(TEMP_PATH)/Unihan_OtherMappings.txt
	grep -v '^#' $< | grep kGB1 > $@
$(TEMP_PATH)/unihan-krname.txt: $(TEMP_PATH)/Unihan_OtherMappings.txt
	grep -v '^#' $< | grep kKoreanName > $@

$(TEMP_PATH)/EquivalentUnifiedIdeograph.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/UNIDATA/EquivalentUnifiedIdeograph.txt
$(ROOT_PATH)/local/unicode/latest/StandardizedVariants.txt:
	cd $(ROOT_PATH) && $(MAKE) local/unicode/latest/StandardizedVariants.txt

IVD_VERSION = 2022-09-13

$(TEMP_PATH)/$(IVD_VERSION):
	mkdir -p $@

$(TEMP_PATH)/$(IVD_VERSION)/IVD_Sequences.txt: $(TEMP_PATH)/$(IVD_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/ivd/data/$(IVD_VERSION)/IVD_Sequences.txt
	touch $@
$(TEMP_PATH)/$(IVD_VERSION)/IVD_Stats.txt: $(TEMP_PATH)/$(IVD_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/ivd/data/$(IVD_VERSION)/IVD_Stats.txt
	touch $@

variants.json: variants.pl \
    $(TEMP_PATH)/Unihan_Variants.txt \
    $(TEMP_PATH)/$(IVD_VERSION)/IVD_Sequences.txt \
    $(TEMP_PATH)/$(IVD_VERSION)/IVD_Stats.txt \
    $(TEMP_PATH)/EquivalentUnifiedIdeograph.txt \
    $(ROOT_PATH)/local/unicode/latest/StandardizedVariants.txt \
    $(TEMP_PATH)/unihan-tghz2013.txt \
    $(TEMP_PATH)/unihan-g1.txt \
    $(TEMP_PATH)/unihan-hkg.txt \
    $(TEMP_PATH)/unihan-k0.txt \
    $(TEMP_PATH)/unihan-krname.txt \
    $(TEMP_PATH)/unihan13-krname.txt
	IVD_VERSION=$(IVD_VERSION) $(PERL) $< > $@

$(ROOT_PATH)/local/unicode/latest/NamesList.txt:
	cd $(ROOT_PATH) && $(MAKE) local/unicode/latest/NamesList.txt

namesrefs.json: namesrefs.pl \
    $(ROOT_PATH)/local/unicode/latest/NamesList.txt
	$(PERL) $< > $@

## License: Public Domain.
