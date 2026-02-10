#!/usr/bin/make

PROJECT := $(notdir $(CURDIR))
PANDOC := pandoc

default: public/$(PROJECT).html

public/$(PROJECT).pdf: $(PROJECT).md

public/%.html: %.md files/article.css
	@echo "Generating $@ from $<"
	@mkdir -p public
	@$(PANDOC) \
		--from=gfm --to html5 \
		--metadata date="$(shell date '+%d %b %Y')" \
		--embed-resources --standalone \
		--css files/article.css \
		--output $@ \
		$<

public/%.pdf: %.md files/article.css files/preamble.tex
	@echo "Generating $@ from $<"
	@mkdir -p public
	@$(PANDOC) \
		--include-in-header files/preamble.tex \
		--from=markdown --pdf-engine=xelatex \
		--css files/article.css \
		--toc \
		--output $@ \
		$<

.PHONY: update-date
update-date:
	@echo "Updating date in $(PROJECT).md"
	@sed -i "s/^date: .*/date: $(shell date +'%d %B %Y')/" $(PROJECT).md

.PHONY: clean
clean:
	@$(RM) -rf public
