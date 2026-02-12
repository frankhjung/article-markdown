# Markdown Articles

This `markdown` folder is the parent folder for all markdown articles. Each
article is in its own subfolder, and each subfolder contains an
`article.md` file (e.g. `consciousness/article.md`) that contains
the main content of the article.

## Objective

We would like to set up this project so it can be re-used for
multiple articles. The pipeline will build one HTML artefact per
article: `[article_name]/public/article.html`. This will be
published to Blogger. The pipeline should be parameterised by the
article folder name, so that it can be reused for each article.
The pipeline should build the article using the `Makefile` and
then publish it to Blogger. The pipeline need only build and
publish one article at a time, so it can be triggered manually
with the article folder name (e.g., `consciousness`) as a
parameter.

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

There are some common files (`files/`) that are shared across
articles. These are hard-linked from the root `files/` directory
into each article's `files/` subfolder:

- `files/article.css` — CSS styles for the article.
- `files/article.md` — template article content with YAML front
  matter.
- `files/article.mk` — shared build logic (linked as `Makefile`
  in article folders).
- `files/preamble.tex` — TeX preamble for PDF generation.

## Images

There is an image folder (`images/`) for each article, and the
images should be placed in that folder. Images are referenced in
`article.md` using relative paths. Most articles include a banner
image (e.g., `images/banner.jpg` or `images/banner.png`).

## GitHub Pipeline

The project uses a GitHub Actions
[workflow](../.github/workflows/publish.yml) to build and publish
articles to Blogger.

The pipeline is triggered manually via `workflow_dispatch` and
takes the following parameters:

- **article_name**: The name of the article subfolder (e.g.,
  `consciousness`).
- **article_title**: The title of the post as it will appear on
  Blogger.
- **article_labels**: A comma-separated list of labels for the
  Blogger post.

All three parameters are required. The pipeline has two jobs:

1. **Validate** (`validate` job): Checks that all three inputs
   are provided. If all inputs are empty, the build is skipped.
   If only some inputs are provided, the workflow fails with an
   error.
2. **Build and Publish** (`build` job, runs only if validation
   passes):
   - **Checkout**: Performs a shallow checkout of the repository.
   - **Build**: Uses a Pandoc Docker image
     (`frankhjung/pandoc:3.1.11.1` from DockerHub) to run
     `make -B [article_name]` from the root, which triggers
     the article's specific build.
   - **Publish**: Uses a Blogger Docker image
     (`ghcr.io/frankhjung/blogger:v1.3` from GHCR) to upload
     the generated HTML
     (`[article_name]/public/article.html`) to Blogger using
     the provided metadata and secrets.

## Docs

Record project documentation in `docs/`. This is a top level folder
that will not be duplicated in each article folder. This file is
`requirements.md`. Other files may be added to this folder as needed.

## Blogger

To publish to Blogger the following secrets need to be set up in
GitHub:

| Secret                  | Description                                    |
| ----------------------- | ---------------------------------------------- |
| `BLOGGER_BLOG_ID`       | Unique identifier for your destination blog    |
| `BLOGGER_CLIENT_ID`     | Google OAuth Client ID from Cloud Console      |
| `BLOGGER_CLIENT_SECRET` | Google OAuth Client Secret for authorisation   |
| `BLOGGER_REFRESH_TOKEN` | Token for long-term, non-interactive API access|

See
[Blogger API documentation](https://developers.google.com/blogger/docs/3.0/using)
for setup instructions.

## Docker Images

The pipeline uses two Docker images that can also be run locally:

### Pandoc (DockerHub)

Used to build HTML articles from Markdown.

```bash
# Pull image
docker pull frankhjung/pandoc:3.1.11.1

# Build an article (run from project root)
docker run --rm -v "$(pwd)":/workspace -w /workspace \
  frankhjung/pandoc:3.1.11.1 \
  make -B consciousness
```

### Blogger (GHCR)

Used to publish articles to Blogger.

```bash
# Pull image
docker pull ghcr.io/frankhjung/blogger:v1.3

# Publish an article
docker run --rm -v "$(pwd)":/workspace -w /workspace \
  ghcr.io/frankhjung/blogger:v1.3 \
  --source-file "consciousness/public/article.html" \
  --title "My Article Title" \
  --labels "label1, label2" \
  --blog-id "YOUR_BLOG_ID" \
  --client-id "YOUR_CLIENT_ID" \
  --client-secret "YOUR_CLIENT_SECRET" \
  --refresh-token "YOUR_REFRESH_TOKEN"
```
