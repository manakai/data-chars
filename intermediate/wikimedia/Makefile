ROOT_PATH = ../..
TEMP_PATH = $(ROOT_PATH)/local/iwm
PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib

WGET = wget
SAVEURL = $(WGET) -O

all: $(TEMP_PATH) variants.json

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/list1.html:
	$(SAVEURL) $@ "https://zh.wikisource.org/w/index.php?title=%E5%B8%B8%E7%94%A8%E5%9C%8B%E5%AD%97%E6%A8%99%E6%BA%96%E5%AD%97%E9%AB%94%E8%A1%A8&action=edit"
$(TEMP_PATH)/list2.html:
	$(SAVEURL) $@ "https://zh.wikisource.org/w/index.php?title=%E6%AC%A1%E5%B8%B8%E7%94%A8%E5%9C%8B%E5%AD%97%E6%A8%99%E6%BA%96%E5%AD%97%E9%AB%94%E8%A1%A8&action=edit"

$(TEMP_PATH)/kredu.html:
	$(SAVEURL) $@ "https://ko.wikipedia.org/wiki/%EB%8C%80%ED%95%9C%EB%AF%BC%EA%B5%AD_%EC%A4%91%EA%B3%A0%EB%93%B1%ED%95%99%EA%B5%90_%EA%B8%B0%EC%B4%88%ED%95%9C%EC%9E%90_%EB%AA%A9%EB%A1%9D?action=edit&veswitched=1"

variants.json: variants.pl \
    $(TEMP_PATH)/list1.html \
    $(TEMP_PATH)/list2.html \
    $(TEMP_PATH)/kredu.html \
    hyougai.txt
	$(PERL) $< > $@

## License: Public Domain.
