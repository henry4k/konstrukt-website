DEPLOY_TARGET = henry4k.de:www_konstrukt
GENERATED += style.css

include style/makefile.mk

.PHONY: all deploy clean

.DEFAULT: all

all: $(GENERATED)

deploy: $(GENERATED)
	rsync -vrR --delete-before $(GENERATED) $(DEPLOY_TARGET)/

clean:
	rm -fv $(GENERATED)

style.css: style/main.scss
	sass --style expanded $^ $@
