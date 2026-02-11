# Markdown Articles

This `markdown` folder is the parent folder for all markdown articles. Each
article is in its own subfolder, and each subfolder contains an
`article.md` file (e.g. `consciousness/article.md`) that contains
the main content of the article.

## Objective

We would like to setup this project so it can be re-used for multiple articles.
The pipeline will build one HTML artifact per article:
`[article_name]/public/article.html`. This will be published to Blogger. The pipeline
should be parameterised by the article name, so that it can be reused for each
article. The pipeline should build the article using the `Makefile` and then
publish it to Blogger. The pipeline need only build and publish one article at a
time, so it can be triggered manually with the article name (`article.md`)
as a parameter.

## Reference Projects

For example of the project structure see the folders:

- `consciousness/`
- `the-big-questions/`

## Build

The project uses a root `Makefile` that delegates builds to individual article
subfolders. A common `article.mk` file in the root `files/` directory contains
the shared build logic.

### Root Makefile

The root `Makefile` handles listing articles, triggering their specific
builds, creating new articles, and updating links to common files.

### Article Makefile Template

Each article folder has its own `Makefile`, which is typically a hard link to
`files/article.mk`. The shared logic is as follows:

```Makefile
#!/usr/bin/make

PROJECT := $(notdir $(CURDIR))
PANDOC := pandoc

default: public/article.html

$(PROJECT).pdf: public/$(PROJECT).pdf

public/%.html: article.md files/article.css images/*.*
	@echo "Generating $@ from $<"
	@mkdir -p public
	@$(PANDOC) \
		--from=gfm --to html5 \
		--metadata date="$(shell date '+%d %b %Y')" \
		--embed-resources --standalone \
		--css files/article.css \
		--output $@ \
		$<

public/%.pdf: article.md files/article.css files/preamble.tex images/*.*
	@echo "Generating $@ from $<"
	@mkdir -p public
	@$(PANDOC) \
		--include-in-header files/preamble.tex \
		--from=markdown --pdf-engine=xelatex \
		--css files/article.css \
		--toc \
		--output $@ \
		$<

.PHONY: update-date
update-date:
	@echo "Updating date for $(PROJECT)"
	@sed -i "s/^date: .*/date: $(shell date +'%d %B %Y')/" article.md

.PHONY: clean
clean:
	@$(RM) -rf public

```

## Common Files

There are some common files (`files/`) that are shared across articles. These
are hard-linked from the root `files/` directory into each article's `files/`
subfolder:

- `files/article.css` - This file contains the CSS styles for the article.
- `files/preamble.tex` - This file contains the TeX preamble for the article.
- `files/article.mk` - The shared build logic (linked as `Makefile` in article folders).

## Images

There is an image folder (`images/`) for each article, and the images should be
placed in that folder. Images are referenced in `article.md` using relative
paths. Most articles include a banner image (e.g., `images/banner.jpg` or
`images/banner.png`).

## GitHub Pipeline

The project uses a GitHub pipeline (`publish.yml`) to build and publish articles
to Blogger.

The pipeline is triggered manually via `workflow_dispatch` and takes the
following parameters:

- **article_name**: The name of the article subfolder (e.g., `consciousness`).
- **article_title**: The title of the post as it will appear on Blogger.
- **article_labels**: A comma-separated list of labels for the Blogger post.

The pipeline performs the following steps:

1. **Validate Inputs**: Ensures all parameters are provided if a build is requested.
2. **Build**: Uses a Pandoc Docker image (`frankhjung/pandoc:3.1.11.1`) to run
   `make -B [article_name]` from the root, which triggers the article's
   specific build.
3. **Publish**: Uses a Blogger Docker image (`ghcr.io/frankhjung/blogger:v1.2`)
   to upload the generated HTML (`[article_name]/public/article.html`) to
   Blogger using the provided metadata and secrets.

## Blogger

To publish to blogger the following secrets need to be set up in GitHub:

| Secret | Description |
| :----- | :---------- |
| `BLOGGER_BLOG_ID` | The unique identifier for your specific destination blog |
| `BLOGGER_CLIENT_ID` | The Google OAuth Client ID derived from the Cloud Console |
| `BLOGGER_CLIENT_SECRET` | The Google OAuth Client Secret used for authorization |
| `BLOGGER_REFRESH_TOKEN` | The secure token that allows for long-term, non-interactive API access |
