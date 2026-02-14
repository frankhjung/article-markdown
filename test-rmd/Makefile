#!/usr/bin/make

SHELL          := /bin/bash
MMDC           := mmdc
PUPPETEER_CFG  := files/puppeteer.json
PROJECT        := $(notdir $(CURDIR))
HTML_OUT       := public/article.html
PDF_OUT        := public/$(PROJECT).pdf
MMD_SRCS       := $(wildcard files/*.mmd)
SVG_OUTS       := $(patsubst files/%.mmd,public/%.svg,$(MMD_SRCS))

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

mermaid: $(SVG_OUTS)

public/%.svg: files/%.mmd
	@mkdir -p public
	@$(MMDC) -p $(PUPPETEER_CFG) -i $< -o $@

.PHONY: update-date
update-date:
	@echo "Updating date for $(PROJECT)"
	@sed -i "s/^date: .*/date: $(shell date +'%d %B %Y')/" article.Rmd

.PHONY: clean
clean:
	@$(RM) *.log
	@$(RM) -rf public/
