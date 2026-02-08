#!/usr/bin/make

# Markdown Articles - Root Makefile
# Delegates builds to individual article subfolders

.PHONY: help list clean

# Find all article directories (those with a Makefile)
ARTICLES := $(patsubst %/Makefile,%,$(wildcard */Makefile))

help:
	@echo "Markdown Articles Pipeline"
	@echo ""
	@echo "Usage:"
	@echo "  make list              - List available articles"
	@echo "  make <article>         - Build a specific article"
	@echo "  make <article>-clean   - Clean a specific article"
	@echo "  make clean             - Clean all articles"
	@echo ""
	@echo "Available articles:"
	@$(foreach art,$(ARTICLES),echo "  - $(art)";)

list:
	@echo "Available articles:"
	@$(foreach art,$(ARTICLES),echo "  $(art)";)

# Build specific article
%:
	@if [ -d "$@" ] && [ -f "$@/Makefile" ]; then \
		echo "Building article: $@"; \
		$(MAKE) -C $@ update-date; \
		$(MAKE) -C $@; \
	fi

# Clean specific article
%-clean:
	@if [ -d "$*" ] && [ -f "$*/Makefile" ]; then \
		echo "Cleaning article: $*"; \
		$(MAKE) -C $* clean; \
	fi

# Clean all articles
clean:
	@for art in $(ARTICLES); do \
		echo "Cleaning $$art..."; \
		$(MAKE) -C $$art clean; \
	done
