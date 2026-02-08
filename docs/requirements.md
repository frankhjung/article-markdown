# Markdown Articles

This `markdown` folder is the parent folder for all markdown articles. Each
article is in its own subfolder, and each subfolder contains a
`[article_name].md` file (e.g. `consciousness/consciousness.md`) that contains
the main content of the article.

## Objective

We would like to setup this project so it can be re-used for multiple articles.
The pipeline will build one HTML artifact per article:
`public/[article_name].html`. This will be published to Blogger. The pipeline
should be parameterised by the article name, so that it can be reused for each
article. The pipeline should build the article using the `Makefile` and then
publish it to Blogger. The pipeline need only build and publish one article at a
time, so it can be triggered manually with the article name (`[article_name]`)
as a parameter.

## Reference Projects

For example of the project structure see the folders:

- `consciousness/`
- `the-big-questions/`

## Build

The project uses a root `Makefile` that delegates builds to individual article
subfolders. A common `article.mk` file in the root directory contains the shared
build logic.

### Root Makefile

The root `Makefile` handles listing articles and triggering their specific
builds.

### Article Makefile Template

Each article folder should have its own `Makefile`. It is recommended to use the
following template, which can also be implemented by including the root
`article.mk`:

```Makefile
#!/usr/bin/make

PROJECT := $(notdir $(CURDIR))
PANDOC := pandoc

default: public/$(PROJECT).html

public/$(PROJECT).pdf: $(PROJECT).md

public/%.html: %.md files/article.css
        @echo "Generating $@ from $<"
        @mkdir -p public
        @$(PANDOC) \
          --from=gfm --to html5 \
          --metadata date="$(shell date '+%d %b %Y')" \
          --embed-resources --standalone \
          --css files/article.css \
          --output $@ \
          $<

public/%.pdf: %.md files/article.css files/preamble.tex
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
        @echo "Updating date in $(PROJECT).md"
        @sed -i "s/^date: .*/date: $(shell date +%Y-%m-%d)/" $(PROJECT).md

.PHONY: clean
clean:
        @$(RM) -rf public
```

## Common Files

There are some common files (`files/`) that will be used for each article:

- `files/article.css` - This file contains the CSS styles for the article.
- `files/preamble.tex` - This file contains the TeX preamble for the article.

These can be hard links from the root project folder, `markdown/`.

## Images

There is an image folder (`images/`) for each article, and the images should be
placed in that folder. The images can be referenced in the `README.md` file
using relative paths. There will be at least one image being the article banner,
`images/banner.png`.

## GitHub Pipeline

The project will have one GitHub pipeline (`publish.yml`) that will build the
article and publish it to Blogger.

The pipeline will build one HTML artifact per article:
`public/[article_name].html`. This will be published to Blogger.

The pipeline is triggered manually via `workflow_dispatch` and takes the
following parameters:

- **article_name**: The name of the article subfolder (e.g., `consciousness`).
- **article_title**: The title of the post as it will appear on Blogger.
- **article_labels**: A comma-separated list of labels for the Blogger post.

The pipeline performs the following steps:

1. **Validate Inputs**: Ensures all three parameters are provided.
2. **Build**: Uses a Pandoc Docker image to run `make -B [article_name]` from
   the root, which triggers the article's specific build.
3. **Publish**: Uses a Blogger Docker image to upload the generated HTML to
   Blogger using the provided metadata and secrets.

- **Output:** `[article_name]/public/[article_name].html` - the HTML file that
  is published to Blogger.

## Blogger

To publish to blogger the following secrets need to be set up in GitHub:

| Secret | Description |
| :----- | :---------- |
| `BLOGGER_BLOG_ID` | The unique identifier for your specific destination blog |
| `BLOGGER_CLIENT_ID` | The Google OAuth Client ID derived from the Cloud Console |
| `BLOGGER_CLIENT_SECRET` | The Google OAuth Client Secret used for authorization |
| `BLOGGER_REFRESH_TOKEN` | The secure token that allows for long-term, non-interactive API access |
