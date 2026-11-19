#!/usr/bin/make

SHELL          := /bin/bash
MMDC           := mmdc
PUPPETEER_CFG  := files/puppeteer.json
PROJECT        := $(notdir $(CURDIR))
HTML_OUT       := public/article.html
PDF_OUT        := public/$(PROJECT).pdf
MMD_SRCS       := $(wildcard files/*.mmd)
PNG_OUTS       := $(patsubst files/%.mmd,images/%.png,$(MMD_SRCS))

.PHONY: default article.html pdf mermaid clean

.DEFAULT_GOAL := article.html

# HTML target

default: article.html

article.html: article.Rmd make.R files/article.css
	@mkdir -p public
	@R --quiet --slave --vanilla --file=make.R --args article.Rmd $(HTML_OUT)

# PDF target

pdf: $(PDF_OUT)

$(PDF_OUT): article.Rmd make.R files/preamble.tex
	@mkdir -p public
	@R --quiet --slave --vanilla --file=make.R --args article.Rmd $(PDF_OUT)

$(PROJECT).pdf: $(PDF_OUT)

# Mermaid diagram target

mermaid: $(PNG_OUTS)

images/%.png: files/%.mmd
	@mkdir -p images
	@$(MMDC) -p $(PUPPETEER_CFG) -i $< -o $@

.PHONY: update-date
update-date:
	# null operation as date is set by R not by bash
	@:

.PHONY: clean
clean:
	@$(RM) *.log test.constant test.trend *.random *.zip
	@$(RM) -rf public/
