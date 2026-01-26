ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iuc
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl -I$(ROOT_PATH)/bin/modules/json-ps/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build-nightly: build

build: $(TEMP_PATH) \
    variants.json \
    maps-0.list maps2.list

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/unihan3.txt: 
	mkdir -p $(TEMP_PATH)
	$(SAVEURL) $@ https://www.unicode.org/Public/3.0-Update/Unihan-3.txt

$(TEMP_PATH)/unihan13.zip:
	mkdir -p $(TEMP_PATH)
	$(SAVEURL) $@ https://www.unicode.org/Public/13.0.0/ucd/Unihan.zip
$(TEMP_PATH)/Unihan13_OtherMappings.txt:: %: $(TEMP_PATH)/unihan13.zip
	mkdir -p $(TEMP_PATH)/temp13
	cd $(TEMP_PATH)/temp13 && unzip ../unihan13.zip Unihan_OtherMappings.txt
	mv $(TEMP_PATH)/temp13/Unihan_OtherMappings.txt $@
	touch $@
$(TEMP_PATH)/unihan13-krname.txt: $(TEMP_PATH)/Unihan13_OtherMappings.txt
	grep -v '^#' $< | grep kKoreanName > $@

$(TEMP_PATH)/USourceData.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/USourceData.txt

$(TEMP_PATH)/15/unihan.zip:
	mkdir -p $(TEMP_PATH)/15
	$(SAVEURL) $@ https://www.unicode.org/Public/15.0.0/ucd/Unihan.zip
$(TEMP_PATH)/unihan.zip:
	$(SAVEURL) $@ https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
$(TEMP_PATH)/15/Unihan_DictionaryIndices.txt \
$(TEMP_PATH)/15/Unihan_IRGSources.txt \
$(TEMP_PATH)/15/Unihan_OtherMappings.txt:: %: $(TEMP_PATH)/15/unihan.zip
	cd $(TEMP_PATH)/15 && unzip unihan.zip $(notdir $@)
	touch $@
$(TEMP_PATH)/Unihan_Readings.txt \
$(TEMP_PATH)/Unihan_RadicalStrokeCounts.txt \
$(TEMP_PATH)/Unihan_DictionaryLikeData.txt \
$(TEMP_PATH)/Unihan_DictionaryIndices.txt \
$(TEMP_PATH)/Unihan_Variants.txt \
$(TEMP_PATH)/Unihan_IRGSources.txt \
$(TEMP_PATH)/Unihan_OtherMappings.txt:: %: $(TEMP_PATH)/unihan.zip
	cd $(TEMP_PATH) && unzip unihan.zip $(notdir $@)
	touch $@
$(TEMP_PATH)/unihan-tghz2013.txt: $(TEMP_PATH)/Unihan_Readings.txt
	grep -v '^#' $< | grep kTGHZ2013 > $@
$(TEMP_PATH)/unihan-hkg.txt: $(TEMP_PATH)/Unihan_DictionaryLikeData.txt
	grep -v '^#' $< | grep kHKGlyph > $@
$(TEMP_PATH)/unihan-k0.txt: $(TEMP_PATH)/15/Unihan_OtherMappings.txt
	grep -v '^#' $< | grep kKSC0 > $@
$(TEMP_PATH)/unihan-k1.txt: $(TEMP_PATH)/15/Unihan_OtherMappings.txt
	grep -v '^#' $< | grep kKSC1 > $@
$(TEMP_PATH)/unihan-g1.txt: $(TEMP_PATH)/Unihan_OtherMappings.txt
	grep -v '^#' $< | grep kGB1 > $@
$(TEMP_PATH)/unihan-krname.txt: $(TEMP_PATH)/Unihan_OtherMappings.txt
	grep -v '^#' $< | grep kKoreanName > $@
$(TEMP_PATH)/unihan-ibmjapan.txt: $(TEMP_PATH)/Unihan_OtherMappings.txt
	grep -v '^#' $< | grep kIBMJapan > $@
$(TEMP_PATH)/unihan-joyo.txt: $(TEMP_PATH)/Unihan_OtherMappings.txt
	grep -v '^#' $< | grep kJoyoKanji > $@
$(TEMP_PATH)/unihan-jinmei.txt: $(TEMP_PATH)/Unihan_OtherMappings.txt
	grep -v '^#' $< | grep kJinmei > $@
$(TEMP_PATH)/unihan-irg-g.txt: $(TEMP_PATH)/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_G > $@
$(TEMP_PATH)/unihan-irg-k.txt: $(TEMP_PATH)/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_KS > $@
$(TEMP_PATH)/unihan-irg-kp.txt: $(TEMP_PATH)/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_KP > $@
$(TEMP_PATH)/unihan15-irg-kp.txt: $(TEMP_PATH)/15/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_KP > $@
$(TEMP_PATH)/unihan-irg-uk.txt: $(TEMP_PATH)/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_UK > $@
$(TEMP_PATH)/unihan-irg-j.txt: $(TEMP_PATH)/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_J > $@
$(TEMP_PATH)/unihan-irg-h.txt: $(TEMP_PATH)/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_H > $@
$(TEMP_PATH)/unihan-irg-m.txt: $(TEMP_PATH)/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_M > $@
$(TEMP_PATH)/unihan-irg-t.txt: $(TEMP_PATH)/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_T > $@
$(TEMP_PATH)/unihan-irg-s.txt: $(TEMP_PATH)/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_S > $@
$(TEMP_PATH)/unihan-irg-v.txt: $(TEMP_PATH)/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_V > $@
$(TEMP_PATH)/unihan15-irg-v.txt: $(TEMP_PATH)/15/Unihan_IRGSources.txt
	grep -v '^#' $< | grep kIRG_V > $@
$(TEMP_PATH)/unihan-kangxi.txt: $(TEMP_PATH)/Unihan_DictionaryIndices.txt
	grep -v '^#' $< | grep KangXi > $@
$(TEMP_PATH)/unihan-morohashi.txt: \
    $(TEMP_PATH)/Unihan_DictionaryIndices.txt
	grep -v '^#' $< | grep Morohashi > $@
$(TEMP_PATH)/unihan15-morohashi.txt: \
    $(TEMP_PATH)/15/Unihan_DictionaryIndices.txt
	grep -v '^#' $< | grep Morohashi > $@
$(TEMP_PATH)/unihan15-irg-daikanwa.txt: \
    $(TEMP_PATH)/15/Unihan_DictionaryIndices.txt
	grep -v '^#' $< | grep IRGDaiKanwa > $@
$(TEMP_PATH)/unihan-aj.txt: \
    $(TEMP_PATH)/Unihan_RadicalStrokeCounts.txt
	grep -v '^#' $< | grep Adobe_Japan > $@

$(TEMP_PATH)/EquivalentUnifiedIdeograph.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/UNIDATA/EquivalentUnifiedIdeograph.txt
$(ROOT_PATH)/local/unicode/latest/StandardizedVariants.txt:
	cd $(ROOT_PATH) && $(MAKE) local/unicode/latest/StandardizedVariants.txt

$(TEMP_PATH)/JIS0212.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/MAPPINGS/OBSOLETE/EASTASIA/JIS/JIS0212.TXT
$(TEMP_PATH)/KPS9566.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/MAPPINGS/VENDORS/MISC/KPS9566.TXT
$(TEMP_PATH)/CHINSIMP.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/CHINSIMP.TXT
$(TEMP_PATH)/CHINTRAD.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/CHINTRAD.TXT
$(TEMP_PATH)/KOREAN.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/KOREAN.TXT
$(TEMP_PATH)/KOREAN-old.txt:
	$(SAVEURL) $@ https://web.archive.org/web/20010709133943if_/http://www.unicode.org:80/Public/MAPPINGS/VENDORS/APPLE/KOREAN.TXT
$(TEMP_PATH)/JAPANESE.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/JAPANESE.TXT
$(TEMP_PATH)/bestfit932.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/bestfit932.txt
$(TEMP_PATH)/bestfit936.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/bestfit936.txt
$(TEMP_PATH)/bestfit949.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/bestfit949.txt
$(TEMP_PATH)/bestfit950.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/bestfit950.txt

IVD_VERSION = 2022-09-13

$(TEMP_PATH)/$(IVD_VERSION):
	mkdir -p $@

$(TEMP_PATH)/$(IVD_VERSION)/IVD_Sequences.txt: $(TEMP_PATH)/$(IVD_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/ivd/data/$(IVD_VERSION)/IVD_Sequences.txt
	touch $@
$(TEMP_PATH)/$(IVD_VERSION)/IVD_Stats.txt: $(TEMP_PATH)/$(IVD_VERSION)
	$(SAVEURL) $@ https://www.unicode.org/ivd/data/$(IVD_VERSION)/IVD_Stats.txt
	touch $@

$(TEMP_PATH)/iso-ir-165.ucm:
	$(SAVEURL) $@ https://raw.githubusercontent.com/unicode-org/icu/main/icu4c/source/data/mappings/iso-ir-165.ucm

$(TEMP_PATH)/kVariants.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/hfhchan/irg/master/kVariants.txt

$(TEMP_PATH)/MathClassExt.txt:
	$(SAVEURL) $@ https://www.unicode.org/Public/math/revision-15/MathClassEx-15.txt

$(TEMP_PATH)/cjk-symbols-map.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/unicode-org/cjk-symbols/6c005bd8bf808bca65b9d87b770f40e2b71a9a03/map.txt

variants.json: variants.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/unihan-tghz2013.txt \
    $(TEMP_PATH)/unihan-g1.txt \
    $(TEMP_PATH)/unihan-hkg.txt \
    $(TEMP_PATH)/unihan-k0.txt \
    $(TEMP_PATH)/unihan-krname.txt \
    $(TEMP_PATH)/unihan13-krname.txt
	$(PERL) $< > $@

$(ROOT_PATH)/local/unicode/latest/NamesList.txt:
	cd $(ROOT_PATH) && $(MAKE) local/unicode/latest/NamesList.txt
$(ROOT_PATH)/data/maps.json:
	cd $(ROOT_PATH) && $(MAKE) data/maps.json

../jp/jouyouh22-table.json:
	cd ../jp && $(MAKE) jouyouh22-table.json

maps-0.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/unihan3.txt \
    $(TEMP_PATH)/unihan-irg-g.txt \
    $(TEMP_PATH)/unihan-irg-t.txt \
    $(TEMP_PATH)/unihan-irg-s.txt \
    $(TEMP_PATH)/unihan-irg-v.txt \
    $(TEMP_PATH)/unihan15-irg-v.txt \
    $(TEMP_PATH)/unihan-irg-k.txt \
    $(TEMP_PATH)/unihan-irg-kp.txt \
    $(TEMP_PATH)/unihan15-irg-kp.txt \
    $(TEMP_PATH)/unihan-irg-h.txt \
    $(TEMP_PATH)/unihan-irg-m.txt \
    $(TEMP_PATH)/unihan-irg-uk.txt \
    $(TEMP_PATH)/unihan-irg-j.txt \
    $(TEMP_PATH)/unihan-ibmjapan.txt \
    $(TEMP_PATH)/unihan-kangxi.txt \
    $(TEMP_PATH)/unihan15-morohashi.txt \
    $(TEMP_PATH)/unihan-morohashi.txt \
    $(TEMP_PATH)/unihan15-irg-daikanwa.txt \
    $(TEMP_PATH)/kVariants.txt \
    $(TEMP_PATH)/MathClassExt.txt \
    irgn2107r2-uk.tsv irgn2232r-uk.tsv \
    $(TEMP_PATH)/USourceData.txt \
    $(TEMP_PATH)/Unihan_Variants.txt \
    $(TEMP_PATH)/$(IVD_VERSION)/IVD_Sequences.txt \
    $(TEMP_PATH)/$(IVD_VERSION)/IVD_Stats.txt \
    $(TEMP_PATH)/EquivalentUnifiedIdeograph.txt \
    $(ROOT_PATH)/local/unicode/latest/NamesList.txt \
    $(ROOT_PATH)/local/unicode/latest/StandardizedVariants.txt \
    $(ROOT_PATH)/data/maps.json \
    $(TEMP_PATH)/unihan-k1.txt \
    $(TEMP_PATH)/unihan-joyo.txt \
    $(TEMP_PATH)/unihan-jinmei.txt \
    ../jp/jouyouh22-table.json \
    ucsj-heisei.txt \
    $(TEMP_PATH)/cjk-symbols-map.txt
	IVD_VERSION=$(IVD_VERSION) $(PERL) $<
maps-*.list: maps-0.list

maps2.list: maps2.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/bestfit932.txt \
    $(TEMP_PATH)/bestfit936.txt \
    $(TEMP_PATH)/bestfit949.txt \
    $(TEMP_PATH)/bestfit950.txt \
    $(TEMP_PATH)/KPS9566.txt \
    $(TEMP_PATH)/CHINSIMP.txt \
    $(TEMP_PATH)/CHINTRAD.txt \
    $(TEMP_PATH)/KOREAN.txt \
    $(TEMP_PATH)/KOREAN-old.txt \
    $(TEMP_PATH)/JAPANESE.txt \
    $(TEMP_PATH)/iso-ir-165.ucm
	$(PERL) $< > $@
#    $(TEMP_PATH)/JIS0212.txt 

always:

## License: Public Domain.
