#!/usr/bin/make

# Markdown Articles - Root Makefile
# Delegates builds to individual article subfolders

# Find all article directories (those with a Makefile)
ARTICLES := $(patsubst %/Makefile,%,$(wildcard */Makefile))
SHELL := /bin/bash

.PHONY: help link list clean $(ARTICLES) $(ARTICLES:%=%-clean)

help:
	@echo "Markdown Articles Pipeline"
	@echo ""
	@echo "Usage:"
	@echo "  make list              - List available articles"
	@echo "  make <article>         - Build HTML for a specific article"
	@echo "  make <article>-clean   - Clean a specific article"
	@echo "  make new-article       - Create a new article"
	@echo "  make update-links      - Link files for all articles"
	@echo "  make clean             - Clean all articles"
	@echo ""
	@echo "Available articles:"
	@$(foreach art,$(ARTICLES),echo "  - $(art)";)

list:
	@echo "Available articles:"
	@$(foreach art,$(ARTICLES),echo "  $(art)";)

$(ARTICLES):
	@echo "Building HTML article: $@"
	$(MAKE) -C $@ update-date default

new-article:
	@read -p "Enter new article name: " name; \
	if [ -d "$$name" ]; then \
		echo "Article '$$name' already exists!"; \
	else \
		mkdir -p "$$name"; \
		cp files/article.md "$$name/article.md"; \
		ln -f files/article.mk "$$name/Makefile"; \
		mkdir -p "$$name/files"; \
		ln -f files/article.css "$$name/files/article.css"; \
		ln -f files/preamble.tex "$$name/files/preamble.tex"; \
		mkdir -p "$$name/images"; \
		cp images/banner.jpg "$$name/images/banner.jpg"; \
		echo "Article '$$name' created successfully:"; \
		find "$$name/" -type f; \
	fi

update-links:
	@for art in $(ARTICLES); do \
		echo "Linking Makefile for $$art..."; \
		ln -f files/article.mk $$art/Makefile; \
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
		$(MAKE) -C $$art clean; \
	done
