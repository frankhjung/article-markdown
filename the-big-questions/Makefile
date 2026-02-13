#!/usr/bin/make

SHELL := /bin/bash
PANDOC := pandoc
PROJECT := $(notdir $(CURDIR))
HTML_OUT := public/article.html
PDF_OUT := public/$(PROJECT).pdf

.PHONY: default article.html pdf clean

.DEFAULT_GOAL := article.html

# HTML target

default: article.html

article.html: article.md
	@mkdir -p public
	@$(PANDOC) \
		--from=gfm --to html5 \
		--metadata date="$(shell date '+%d %b %Y')" \
		--embed-resources --standalone \
		--css files/article.css \
		--output $(HTML_OUT) \
		article.md

# PDF target

pdf: $(PDF_OUT)

$(PDF_OUT): article.md
	@mkdir -p public
	@$(PANDOC) \
		--include-in-header files/preamble.tex \
		--from=markdown --pdf-engine=xelatex \
		--css files/article.css \
		--toc \
		--output $(PDF_OUT) \
		article.md

.PHONY: update-date
update-date:
	@echo "Updating date for $(PROJECT)"
	@sed -i "s/^date: .*/date: $(shell date +'%d %B %Y')/" article.md

.PHONY: clean
clean:
	@$(RM) -rf public
