ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iwm
VGEN_PATH = $(ROOT_PATH)/intermediate/vgen
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib -I$(VGEN_PATH)

WGET = wget
SAVEURL = $(WGET) -O

all: $(TEMP_PATH) variants.json maps.list

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

$(TEMP_PATH)/gb12052.html:
	$(SAVEURL) $@ "https://charset.fandom.com/ko/wiki/GB_12052?action=edit&veswitched=1"
$(TEMP_PATH)/ksx1002.html:
	$(SAVEURL) $@ "https://charset.fandom.com/ko/wiki/KS_X_1002?action=edit&veswitched=1"

variants.json: variants.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/list1.html \
    $(TEMP_PATH)/list2.html \
    $(TEMP_PATH)/kredu.html \
    hyougai.txt
	$(PERL) $< > $@

maps.list: maps.pl $(VGEN_PATH)/chars.pl \
    $(TEMP_PATH)/gb12052.html \
    $(TEMP_PATH)/ksx1002.html \
    $(TEMP_PATH)/nan-1.html \
    $(TEMP_PATH)/nan-2.html \
    $(TEMP_PATH)/nan-3.html \
    doukun.txt \
    gbk.txt
	$(PERL) $< > $@

## License: Public Domain.
