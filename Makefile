#!/usr/bin/make

# Markdown Articles - Root Makefile
# Delegates builds to individual article subfolders
# Find all article directories (those with a Makefile)
ARTICLES := $(patsubst %/Makefile,%,$(wildcard */Makefile))
ARTICLE_TARGET := $(or $(output),default)
SHELL    := /bin/bash

.PHONY: help list clean $(ARTICLES) $(ARTICLES:%=%-clean)

help:
	@echo "Markdown Articles Pipeline"
	@echo ""
	@echo "Usage:"
	@echo "  make list                             - List available articles"
	@echo "  make <article>                        - Build HTML for a specific article"
	@echo "  make <article> output=pdf             - Build PDF for a specific article"
	@echo "  make <article>-clean                  - Clean a specific article"
	@echo "  make new-article name=<name>          - Create a new article (default: md)"
	@echo "  make new-article name=<name> type=rmd - Create a new Rmd article"
	@echo "  make update-links                     - Re-link shared files for all articles"
	@echo "  make clean                            - Clean all articles"
	@echo ""
	@echo "Available articles:"
	@$(foreach art,$(ARTICLES),echo "  - $(art)";)

list:
	@echo "Available articles:"
	@$(foreach art,$(ARTICLES),echo "  $(art)";)

$(ARTICLES):
	@echo "Building article: $@"
	$(MAKE) -C $@ update-date $(ARTICLE_TARGET)

new-article:
	@if [ -z "$(name)" ]; then \
		echo "ERROR: name is required."; \
		echo "Usage: make new-article name=<name> [type=md|rmd]"; \
		exit 1; \
	fi
	@if [ -d "$(name)" ]; then \
		echo "Article '$(name)' already exists!"; \
		exit 1; \
	fi
	@mkdir -p "$(name)"
	@if [ "$(type)" = "rmd" ]; then \
		cp files/article.Rmd "$(name)/article.Rmd"; \
		ln -f files/article_rmd.mk "$(name)/Makefile"; \
		ln -f files/make.R "$(name)/make.R"; \
	else \
		cp files/article.md "$(name)/article.md"; \
		ln -f files/article_md.mk "$(name)/Makefile"; \
	fi
	@mkdir -p "$(name)/files"
	@ln -f files/article.css "$(name)/files/article.css"
	@ln -f files/preamble.tex "$(name)/files/preamble.tex"
	@mkdir -p "$(name)/images"
	@cp images/banner.jpg "$(name)/images/banner.jpg"
	@echo "Article '$(name)' created successfully:"
	@find "$(name)/" -type f

update-links:
	@for art in $(ARTICLES); do \
		echo "Linking Makefile for $$art..."; \
		if [ -f $$art/article.Rmd ]; then \
			ln -f files/article_rmd.mk $$art/Makefile; \
			ln -f files/make.R $$art/make.R; \
		else \
			ln -f files/article_md.mk $$art/Makefile; \
		fi; \
		echo "Linking files for $$art..."; \
		mkdir -p $$art/files; \
		ln -f files/article.css $$art/files/article.css; \
		ln -f files/preamble.tex $$art/files/preamble.tex; \
	done

# Clean specific article
$(ARTICLES:%=%-clean):
	@echo "Cleaning article: $(@:%-clean=%)"
	$(MAKE) -C $(@:%-clean=%) clean

# Clean all articles
clean:
	@for art in $(ARTICLES); do \
		echo "Cleaning $$art..."; \
		$(MAKE) -C "$$art" clean; \
	done
