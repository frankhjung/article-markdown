#!/usr/bin/make

PROJECT := $(notdir $(CURDIR))
PANDOC := pandoc

default: public/article.html

$(PROJECT).pdf: public/$(PROJECT).pdf

public/%.html: article.md files/article.css images/*.*
	@echo "Generating $@ from $<"
	@mkdir -p public
	@$(PANDOC) \
		--from=gfm --to html5 \
		--metadata date="$(shell date '+%d %b %Y')" \
		--embed-resources --standalone \
		--css files/article.css \
		--output $@ \
		$<

public/%.pdf: article.md files/article.css files/preamble.tex images/*.*
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
	@echo "Updating date for $(PROJECT)"
	@sed -i "s/^date: .*/date: $(shell date +'%d %B %Y')/" article.md

.PHONY: clean
clean:
	@$(RM) -rf public
