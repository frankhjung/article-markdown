#!/usr/bin/make

.SUFFIXES:
.SUFFIXES: .html .md .pdf

PROJECT := consciousness
PANDOC := pandoc

default: $(PROJECT).html $(PROJECT).pdf

.md.html:
	@echo "Generating $@ from $<"
	@mkdir -p public
	@$(PANDOC) \
		--from=gfm --to html5 \
		--metadata date="$(shell date '+%d %b %Y')" \
		--embed-resources --standalone \
		--css files/article.css \
		--output public/$@ \
		$<

.md.pdf:
	@echo "Generating $@ from $<"
	@mkdir -p public
	@$(PANDOC) \
		--include-in-header files/preamble.tex \
		--from=markdown --pdf-engine=xelatex \
		--css files/article.css \
		--toc \
		--output public/$@ \
		$<

.PHONY: update-date
update-date:
	sed -i "s/^date: .*/date: $(shell date +%Y-%m-%d)/" $(PROJECT).md

.PHONY: clean
clean:
	@$(RM) -rf public
