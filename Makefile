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
	@echo "  make <article>         - Build a specific article"
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

# Build specific article
$(ARTICLES):
	@echo "Building article: $@"
	$(MAKE) -C $@ update-date default

new-article:
	@read -p "Enter new article name: " name; \
	if [ -d "$$name" ]; then \
		echo "Article '$$name' already exists!"; \
	else \
		mkdir -p "$$name"; \
		cp article.mk "$$name/Makefile"; \
		mkdir -p "$$name/images"; \
		mkdir -p "$$name/files"; \
		ln -f files/article.css "$$name/files/article.css"; \
		ln -f files/preamble.tex "$$name/files/preamble.tex"; \
		touch "$$name.md"; \
		echo "Article '$$name' created successfully!"; \
	fi

update-links:
	@for art in $(ARTICLES); do \
		echo "Linking files for $$art..."; \
		mkdir -p $$art/images; \
		mkdir -p $$art/files; \
		ln -f files/article.css $$art/files/article.css; \
		ln -f files/preamble.tex $$art/files/preamble.tex; \
		echo "Linking Makefile for $$art..."; \
		ln -f article.mk $$art/Makefile; \
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
