ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iwm
TEMPUC_PATH = $(ROOT_PATH)/local/iuc
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
DATA_PATH = $(ROOT_PATH)/local/maps
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: build

build: $(TEMP_PATH) variants.json maps-0.list \
    build-pages 

build-pages: $(TEMP_PATH) \
    $(DATA_PATH)/gwrelated-0.list \
    $(DATA_PATH)/gwaliases-0.list \
    $(DATA_PATH)/gwrelated-0.list \
    $(DATA_PATH)/gwrels-0.list \
    $(TEMP_PATH)/gwreltypes.json

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/list1.html:
	$(SAVEURL) $@ "https://zh.wikisource.org/w/index.php?title=%E5%B8%B8%E7%94%A8%E5%9C%8B%E5%AD%97%E6%A8%99%E6%BA%96%E5%AD%97%E9%AB%94%E8%A1%A8&action=edit"
$(TEMP_PATH)/list2.html:
	$(SAVEURL) $@ "https://zh.wikisource.org/w/index.php?title=%E6%AC%A1%E5%B8%B8%E7%94%A8%E5%9C%8B%E5%AD%97%E6%A8%99%E6%BA%96%E5%AD%97%E9%AB%94%E8%A1%A8&action=edit"

$(TEMP_PATH)/kredu.html:
	$(SAVEURL) $@ "https://ko.wikipedia.org/wiki/%EB%8C%80%ED%95%9C%EB%AF%BC%EA%B5%AD_%EC%A4%91%EA%B3%A0%EB%93%B1%ED%95%99%EA%B5%90_%EA%B8%B0%EC%B4%88%ED%95%9C%EC%9E%90_%EB%AA%A9%EB%A1%9D?action=edit&veswitched=1"

$(TEMP_PATH)/nan-1.html:
	$(SAVEURL) $@ "https://zh.wikipedia.org/wiki/%E8%87%BA%E9%96%A9%E5%AD%97%E5%88%97%E8%A1%A8?action=edit&veswitched=1"

$(TEMP_PATH)/nan-2.html:
	$(SAVEURL) $@ "https://zh.wikipedia.org/wiki/%E8%87%BA%E8%AA%9E%E6%9C%AC%E5%AD%97%E5%88%97%E8%A1%A8?action=edit&veswitched=1"

$(TEMP_PATH)/nan-3.html:
	$(SAVEURL) $@ "https://zh.wikipedia.org/wiki/%E6%AD%8C%E4%BB%94%E5%86%8A%E6%96%87%E5%AD%97?action=edit&veswitched=1"

$(TEMP_PATH)/jaconvert.html:
	$(SAVEURL) $@ "https://ja.wikisource.org/wiki/%E3%83%86%E3%83%B3%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88:%E6%96%B0%E6%97%A7%E5%AD%97%E4%BD%93%E5%A4%89%E6%8F%9B%E7%94%A8%E8%BE%9E%E6%9B%B8?action=edit&veswitched=1"

$(TEMP_PATH)/gb12052.html:
	$(SAVEURL) $@ "https://charset.fandom.com/ko/wiki/GB_12052?action=edit&veswitched=1"
$(TEMP_PATH)/ksx1002.html:
	$(SAVEURL) $@ "https://charset.fandom.com/ko/wiki/KS_X_1002?action=edit&veswitched=1"

$(TEMP_PATH)/jeju.html:
	$(SAVEURL) $@ "https://en.wiktionary.org/wiki/Appendix:Unicode/Private_Use_Area/Jeju_fonts?action=edit&veswitched=1"
$(TEMP_PATH)/hanyang.html:
	$(SAVEURL) $@ "https://en.wiktionary.org/wiki/Appendix:Unicode/Private_Use_Area/Hanyang?action=edit&veswitched=1"

$(TEMP_PATH)/0201-1.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/wakaba/data-chartables/master/generated/jisx0201_latin.tbl
$(TEMP_PATH)/0201-2.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/wakaba/data-chartables/master/generated/jisx0201_katakana.tbl
$(TEMP_PATH)/0201-2-hw.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/wakaba/data-chartables/master/source/jisx0201_katakana_hw.tbr
$(TEMP_PATH)/0212.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/wakaba/data-chartables/master/generated/jisx0212_1990.tbl
$(TEMP_PATH)/0208.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/wakaba/data-chartables/master/generated/jisx0208_1997.tbl
$(TEMP_PATH)/0213.txt:
	$(SAVEURL) $@ https://raw.githubusercontent.com/wakaba/data-chartables/master/source/gl-jisx0213-add.tbr

$(TEMP_PATH)/gw.tar.gz:
	$(SAVEURL) $@ https://fonts.suikawiki.org/glyphwiki/dump-2.tar.gz
$(TEMP_PATH)/dump_newest_only.txt: $(TEMP_PATH)/gw.tar.gz
	cd $(TEMP_PATH) && tar zxf gw.tar.gz dump_newest_only.txt
	touch $@
$(TEMP_PATH)/gw-tron.txt: $(TEMP_PATH)/dump_newest_only.txt
	grep tron $< > $@
$(TEMP_PATH)/gw-kana.txt: 
	$(SAVEURL) $@ https://glyphwiki.org/wiki/Group:tsuruki-work-test?action=edit
$(TEMP_PATH)/gw-immi-1.txt: 
	$(SAVEURL) $@ https://glyphwiki.org/wiki/Group:%E5%B9%B3%E6%88%9023%E5%B9%B412%E6%9C%8826%E6%97%A5%E6%B3%95%E5%8B%99%E7%9C%81%E5%91%8A%E7%A4%BA%E7%AC%AC582%E5%8F%B7%E5%88%A5%E8%A1%A8%E7%AC%AC%E4%B8%80?action=edit
$(TEMP_PATH)/gw-immi-pua.txt: 
	$(SAVEURL) $@ https://glyphwiki.org/wiki/Group:kesuuko_sandbox2@6?action=edit

$(TEMP_PATH)/gw-relcp-0.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae?action=edit
$(TEMP_PATH)/gw-relcp-1.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-ExtF?action=edit
$(TEMP_PATH)/gw-relcp-2.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-ExtG?action=edit
$(TEMP_PATH)/gw-relcp-3.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-ExtH?action=edit
$(TEMP_PATH)/gw-relcp-4.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-ExtI?action=edit
$(TEMP_PATH)/gw-relcp-5.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e6%bc%a2%e8%aa%9e%e4%bf%97%e5%ad%97%e5%8f%a2%e8%80%83?action=edit
$(TEMP_PATH)/gw-relcp-6.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e7%96%91%e9%9b%a3%e5%ad%97%e8%80%83%e9%87%8b%e8%88%87%e7%a0%94%e7%a9%b6?action=edit
$(TEMP_PATH)/gw-relcp-7.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e5%8f%af%e6%b4%aa%e9%9f%b3%e7%be%a9%e7%a0%94%e7%a9%b6?action=edit
$(TEMP_PATH)/gw-relcp-8.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-UCS%e4%ba%92%e6%8f%9b?action=edit
$(TEMP_PATH)/gw-relcp-9.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e6%88%b8%e7%b1%8d%e7%95%b0%e4%bd%93?action=edit
$(TEMP_PATH)/gw-relcp-11.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e6%88%b8%e7%b1%8d%e7%95%b0%e4%bd%93-part01?action=edit
$(TEMP_PATH)/gw-relcp-12.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e6%88%b8%e7%b1%8d%e7%95%b0%e4%bd%93-part02?action=edit
$(TEMP_PATH)/gw-relcp-13.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e6%88%b8%e7%b1%8d%e7%95%b0%e4%bd%93-part03?action=edit
$(TEMP_PATH)/gw-relcp-14.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e6%88%b8%e7%b1%8d%e7%95%b0%e4%bd%93-part04?action=edit
$(TEMP_PATH)/gw-relcp-15.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e6%88%b8%e7%b1%8d%e7%95%b0%e4%bd%93-part05?action=edit
$(TEMP_PATH)/gw-relcp-16.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e6%88%b8%e7%b1%8d%e7%95%b0%e4%bd%93-part06?action=edit
$(TEMP_PATH)/gw-relcp-17.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e6%88%b8%e7%b1%8d%e7%95%b0%e4%bd%93-part07?action=edit
$(TEMP_PATH)/gw-relcp-21.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e5%85%a5%e7%ae%a1%e5%88%a5%e8%a1%a8%e7%ac%ac%e5%9b%9b%e3%81%ae%e4%b8%80-%e3%81%9d%e3%81%ae1?action=edit
$(TEMP_PATH)/gw-relcp-22.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e5%85%a5%e7%ae%a1%e5%88%a5%e8%a1%a8%e7%ac%ac%e5%9b%9b%e3%81%ae%e4%b8%80-%e3%81%9d%e3%81%ae2?action=edit
$(TEMP_PATH)/gw-relcp-23.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e5%85%a5%e7%ae%a1%e5%88%a5%e8%a1%a8%e7%ac%ac%e5%9b%9b%e3%81%ae%e4%b8%80-%e3%81%9d%e3%81%ae3?action=edit
$(TEMP_PATH)/gw-relcp-24.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e5%85%a5%e7%ae%a1%e5%88%a5%e8%a1%a8%e7%ac%ac%e5%9b%9b%e3%81%ae%e4%ba%8c-%e3%81%9d%e3%81%ae1?action=edit
$(TEMP_PATH)/gw-relcp-25.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e5%85%a5%e7%ae%a1%e5%88%a5%e8%a1%a8%e7%ac%ac%e5%9b%9b%e3%81%ae%e4%ba%8c-%e3%81%9d%e3%81%ae2?action=edit
$(TEMP_PATH)/gw-relcp-26.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e5%85%a5%e7%ae%a1%e5%88%a5%e8%a1%a8%e7%ac%ac%e5%9b%9b%e3%81%ae%e4%ba%8c-%e3%81%9d%e3%81%ae3?action=edit
$(TEMP_PATH)/gw-relcp-27.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/GlyphWiki:%e9%96%a2%e9%80%a3%e4%bb%98%e3%81%91%e3%82%8b%e3%81%b9%e3%81%8d%e7%ac%a6%e5%8f%b7%e4%bd%8d%e7%bd%ae-%e5%85%a5%e7%ae%a1%e5%88%a5%e8%a1%a8%e7%ac%ac%e5%9b%9b%e3%81%ae%e4%ba%8c-%e3%81%9d%e3%81%ae4?action=edit
$(TEMP_PATH)/gw-cdp-unicode.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/Group:UCS%e3%81%a7%e7%ac%a6%e5%8f%b7%e5%8c%96%e3%81%95%e3%82%8c%e3%81%9fCDP%e5%a4%96%e5%ad%97?action=edit
$(TEMP_PATH)/gw-cdp-all.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/Group:CDP%e5%a4%96%e5%ad%97-ALL?action=edit
$(TEMP_PATH)/gw-cjkeunified.txt:
	$(SAVEURL) $@ https://glyphwiki.org/wiki/Group:ziyang_sandbox@43?action=edit
$(TEMP_PATH)/gw-jouyoukoseki.txt: 
	$(SAVEURL) $@ https://glyphwiki.org/wiki/Group:ziyang_sandbox@77?action=edit
$(TEMP_PATH)/gw-jouyouoldmj.txt: 
	$(SAVEURL) $@ https://glyphwiki.org/wiki/Group:%e5%b8%b8%e7%94%a8%e6%bc%a2%e5%ad%97%e3%81%ae%e6%97%a7%e5%ad%97%e4%bd%93-%e5%ad%97%e5%bd%a2?action=edit
$(TEMP_PATH)/gw-jinmeikoseki.txt: 
	$(SAVEURL) $@ https://glyphwiki.org/wiki/Group:%e4%ba%ba%e5%90%8d%e7%94%a8%e6%bc%a2%e5%ad%97-%e5%ad%97%e5%bd%a2?action=edit

../jp/jouyouh22-table.json:
	cd ../jp && $(MAKE) jouyouh22-table.json

../misc/gmap.json:
	cd ../misc && $(MAKE) gmap.json

$(TEMPUC_PATH)/unihan3.txt:
	cd ../unicode && $(MAKE) $(TEMPUC_PATH)/unihan3.txt

variants.json: variants.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/list1.html \
    $(TEMP_PATH)/list2.html \
    $(TEMP_PATH)/kredu.html \
    hyougai.txt
	$(PERL) $< > $@

maps-0.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/gb12052.html \
    $(TEMP_PATH)/ksx1002.html \
    $(TEMP_PATH)/nan-1.html \
    $(TEMP_PATH)/nan-2.html \
    $(TEMP_PATH)/nan-3.html \
    $(TEMP_PATH)/hanyang.html \
    $(TEMP_PATH)/jeju.html \
    $(TEMP_PATH)/0201-1.txt \
    $(TEMP_PATH)/0201-2.txt \
    $(TEMP_PATH)/0201-2-hw.txt \
    $(TEMP_PATH)/0212.txt \
    $(TEMP_PATH)/0208.txt \
    $(TEMP_PATH)/0213.txt \
    $(TEMP_PATH)/gw-tron.txt \
    $(TEMP_PATH)/gw-kana.txt \
    $(TEMP_PATH)/gw-immi-1.txt \
    $(TEMP_PATH)/gw-immi-pua.txt \
    $(TEMP_PATH)/gw-relcp-0.txt \
    $(TEMP_PATH)/gw-relcp-1.txt \
    $(TEMP_PATH)/gw-relcp-2.txt \
    $(TEMP_PATH)/gw-relcp-3.txt \
    $(TEMP_PATH)/gw-relcp-4.txt \
    $(TEMP_PATH)/gw-relcp-5.txt \
    $(TEMP_PATH)/gw-relcp-6.txt \
    $(TEMP_PATH)/gw-relcp-7.txt \
    $(TEMP_PATH)/gw-relcp-8.txt \
    $(TEMP_PATH)/gw-relcp-9.txt \
    $(TEMP_PATH)/gw-relcp-11.txt \
    $(TEMP_PATH)/gw-relcp-12.txt \
    $(TEMP_PATH)/gw-relcp-13.txt \
    $(TEMP_PATH)/gw-relcp-14.txt \
    $(TEMP_PATH)/gw-relcp-15.txt \
    $(TEMP_PATH)/gw-relcp-16.txt \
    $(TEMP_PATH)/gw-relcp-17.txt \
    $(TEMP_PATH)/gw-relcp-21.txt \
    $(TEMP_PATH)/gw-relcp-22.txt \
    $(TEMP_PATH)/gw-relcp-23.txt \
    $(TEMP_PATH)/gw-relcp-24.txt \
    $(TEMP_PATH)/gw-relcp-25.txt \
    $(TEMP_PATH)/gw-relcp-26.txt \
    $(TEMP_PATH)/gw-relcp-27.txt \
    $(TEMP_PATH)/gw-cdp-all.txt \
    $(TEMP_PATH)/gw-cdp-unicode.txt \
    $(TEMP_PATH)/gw-cjkeunified.txt \
    $(TEMP_PATH)/gw-jouyoukoseki.txt \
    $(TEMP_PATH)/gw-jouyouoldmj.txt \
    $(TEMP_PATH)/gw-jinmeikoseki.txt \
    $(TEMP_PATH)/jaconvert.html \
    doukun.txt \
    gbk.txt \
    manyou.txt \
    ../jp/jouyouh22-table.json \
    ../misc/gmap.json \
    ../misc/kana-gmap.json \
    $(TEMPUC_PATH)/unihan3.txt
	$(PERL) $<
maps-*.list: maps-0.list
$(TEMP_PATH)/gwreltypes.json: maps-0.list

$(ROOT_PATH)/local/generated/charrels/glyphs/gwglyphs/index.json: \
    split-gwdump.pl \
    $(TEMP_PATH)/dump_newest_only.txt
	$(PERL) $<
$(TEMP_PATH)/gwrelated.txt: \
    $(ROOT_PATH)/local/generated/charrels/glyphs/gwglyphs/index.json
$(TEMP_PATH)/gwalias.txt: \
    $(ROOT_PATH)/local/generated/charrels/glyphs/gwglyphs/index.json
$(TEMP_PATH)/gwothers.txt: \
    $(ROOT_PATH)/local/generated/charrels/glyphs/gwglyphs/index.json
$(TEMP_PATH)/gwcontains.txt: \
    $(ROOT_PATH)/local/generated/charrels/glyphs/gwglyphs/index.json

$(DATA_PATH)/gwrelated-0.list: \
    gwmaps.pl \
    $(TEMP_PATH)/gwrelated.txt \
    $(TEMP_PATH)/gwalias.txt \
    $(TEMP_PATH)/gwcontains.txt \
    $(TEMP_PATH)/gwothers.txt
	$(PERL) $<
$(DATA_PATH)/gwaliases-0.list: $(DATA_PATH)/gwrelated-0.list
$(DATA_PATH)/gwcontains-0.list: $(DATA_PATH)/gwrelated-0.list
$(DATA_PATH)/gwrels-0.list: $(DATA_PATH)/gwrelated-0.list

## License: Public Domain.
