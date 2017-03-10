DEPLOY_ADDRESS = henry4k.de:www_konstrukt
GENERATED += style.css

include tex-gyre-schola/makefile.mk

.PHONY: all deploy clean

all: $(FILES)

deploy: $(GENERATED)
	mkdir tmp
	cp index.html tmp/
	cp style.css tmp/
	mkdir tmp/tex-gyre-schola
	cp tex-gyre-schola/*.woff tmp/tex-gyre-schola/
	rsync -vr --delete-before tmp/* $(DEPLOY_ADDRESS)
	rm -rf tmp

clean:
	rm -fv $(GENERATED)

%.css: %.scss
	sass --style expanded $^ $@

%.woff: %.otf valid-chars.txt
	pyftsubset $< --output-file=$@ --text-file=valid-chars.txt

#%.html: %.md menu.lua template.html
#	./gen-page $^ > $@

