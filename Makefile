#!/usr/bin/make

# Markdown Articles - Root Makefile
# Delegates builds to individual article subfolders

.PHONY: help list clean $(ARTICLES) $(ARTICLES:%=%-clean)

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
$(ARTICLES):
	@echo "Building article: $@"
	$(MAKE) -C $@ update-date default

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
