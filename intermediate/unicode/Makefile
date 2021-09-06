ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iuc
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib

WGET = wget
SAVEURL = $(WGET) -O

all: $(TEMP_PATH) variants.json

$(TEMP_PATH):
	mkdir -p $@

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

$(TEMP_PATH)/IVD_Sequences.txt:
	$(SAVEURL) $@ https://www.unicode.org/ivd/data/2020-11-06/IVD_Sequences.txt
$(TEMP_PATH)/IVD_Stats.txt:
	$(SAVEURL) $@ https://www.unicode.org/ivd/data/2020-11-06/IVD_Stats.txt

variants.json: variants.pl \
    $(TEMP_PATH)/Unihan_Variants.txt \
    $(TEMP_PATH)/IVD_Sequences.txt \
    $(TEMP_PATH)/IVD_Stats.txt \
    $(TEMP_PATH)/EquivalentUnifiedIdeograph.txt \
    $(ROOT_PATH)/local/unicode/latest/StandardizedVariants.txt \
    $(TEMP_PATH)/unihan-tghz2013.txt \
    $(TEMP_PATH)/unihan-g1.txt \
    $(TEMP_PATH)/unihan-hkg.txt \
    $(TEMP_PATH)/unihan-k0.txt \
    $(TEMP_PATH)/unihan-krname.txt
	$(PERL) $< > $@

## License: Public Domain.
