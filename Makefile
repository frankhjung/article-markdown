#!/usr/bin/make

# Markdown Articles - Root Makefile
# Delegates builds to individual article subfolders
# Find all article directories (those with a Makefile)
ARTICLES := $(patsubst %/Makefile,%,$(wildcard */Makefile))
ARTICLE_TARGET := $(or $(output),default)
SHELL    := /bin/bash

.PHONY: help list clean image-annotate $(ARTICLES) $(ARTICLES:%=%-clean)

help: ## Show this help message
	@echo Markdown Articles Pipeline
	@echo ""
	@echo Available targets:
	@awk 'match($$0, /^([^[:space:]#].*):[[:space:]]*##[[:space:]]*(.*)$$/, m) {printf "  %-30s %s\n", m[1], m[2]}' $(MAKEFILE_LIST)
	@echo ""
	@echo Available articles:
	@$(foreach art,$(ARTICLES),echo "  - $(art)";)

list: ## List available articles
	@echo "Available articles:"
	@$(foreach art,$(ARTICLES),echo "  $(art)";)

$(ARTICLES): ## Build a specific article (default: HTML)
	@echo "Building article: $@"
	$(MAKE) -C $@ update-date $(ARTICLE_TARGET)

new-article: ## Create a new article with boilerplate (requires name)
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
	@ln -f files/puppeteer.json "$(name)/files/puppeteer.json"
	@mkdir -p "$(name)/images"
	@cp images/banner.jpg "$(name)/images/banner.jpg"
	@echo "Article '$(name)' created successfully:"
	@find "$(name)/" -type f

image-annotate: ## Convert image to JPG (1600px wide) and set copyright metadata (usage: make image-annotate image=path/to/banner.png)
	@if [[ -z "$(image)" ]]; then \
		echo "ERROR: image is required."; \
		echo "Usage: make image-annotate image=<path/to/image.png>"; \
		exit 1; \
	fi
	@if [[ ! -f "$(image)" ]]; then \
		echo "ERROR: file not found: $(image)"; \
		exit 1; \
	fi
	@input="$(image)"; \
	output="$${input%.*}.jpg"; \
	YEAR=$$(date +%Y); \
	magick "$$input" -resize 1600x "$$output"; \
	exiftool -overwrite_original -Copyright="© Frank H Jung $$YEAR" -Artist="Frank H Jung" "$$output"; \
	echo "Created and annotated: $$output"

update-links: ## Re-link shared files for all articles (useful if files are updated)
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
		ln -f files/puppeteer.json $$art/files/puppeteer.json; \
	done

$(ARTICLES:%=%-clean): ## Clean a specific article
	@echo "Cleaning article: $(@:%-clean=%)"
	$(MAKE) -C $(@:%-clean=%) clean

clean: ## Clean all articles
	@for art in $(ARTICLES); do \
		echo "Cleaning $$art..."; \
		$(MAKE) -C "$$art" clean; \
	done
