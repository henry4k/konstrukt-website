DEPLOY_ADDRESS=henry4k.de:www_konstrukt
SASS=sass --style expanded
GENERATED=style.css
FILES=$(GENERATED)

.PHONY: all deploy clean

all: $(FILES)

deploy: $(FILES)
	scp $^ $(DEPLOY_ADDRESS)

clean:
	rm -fv $(GENERATED)

style.css: style.scss
	$(SASS) $^ $@

#%.html: %.md menu.lua template.html
#	./gen-page $^ > $@
