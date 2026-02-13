# Markdown Articles

This `markdown` folder is the parent folder for all Markdown and R Markdown
articles. Each article is in its own subfolder, and each subfolder contains an
`article.md` or `article.Rmd` file (e.g., `consciousness/article.md`) that
contains the main content of the article.

## Objective

We would like to set up this project so it can be re-used for multiple articles.
The pipeline will build one HTML artefact per article:
`[article_name]/public/article.html`. This will be published to Blogger. The
pipeline is parameterised by the article folder name, so that it can be reused
for each article. The pipeline should build the article using the appropriate
`Makefile` and then publish it to Blogger. The pipeline builds and publishes one
article at a time, triggered manually with the article folder name as a
parameter.

## Reference Projects

For examples of the project structure, see:

- `consciousness/` (Markdown)
- `base-rate/` (R Markdown)

## Build

The project uses a root `Makefile` that delegates builds to individual article
subfolders. Separate template files in the root `files/` directory contain the
shared build logic for each article type.

### Root Makefile

The root `Makefile` handles listing articles, triggering their specific builds,
creating new articles, and updating links to common files.

### Article Makefile Templates

Each article folder has its own `Makefile`, which is typically a hard link to
either `files/article_md.mk` or `files/article_rmd.mk` depending on the article
type.

#### Markdown Template (`files/article_md.mk`)

Used for articles using `article.md`. It employs Pandoc to generate HTML and
PDF.

#### R Markdown Template (`files/article_rmd.mk`)

Used for articles using `article.Rmd`. It employs R to render the content into
HTML and PDF.

## Common Files

There are some common files (`files/`) that are shared across articles. These
are hard-linked from the root `files/` directory into each article's `files/`
subfolder:

- `files/article.css` — CSS styles for the article.
- `files/article.md` — template Markdown content.
- `files/article.Rmd` — template R Markdown content.
- `files/article_md.mk` — shared build logic for Markdown articles.
- `files/article_rmd.mk` — shared build logic for R Markdown articles.
- `files/make.R` — R script for rendering R Markdown.
- `files/preamble.tex` — TeX preamble for PDF generation.
- `files/puppeteer.json` — Puppeteer configuration for Mermaid CLI.

## Images

There is an image folder (`images/`) for each article. Images are referenced in
the article file using relative paths. Most articles include a banner image
(e.g., `images/banner.jpg`).

## GitHub Pipeline

The project uses a GitHub Actions [workflow](../.github/workflows/publish.yml)
to build and publish articles to Blogger.

The pipeline is triggered manually via `workflow_dispatch` and takes the
following parameters:

- **article_name**: The name of the article subfolder (e.g., `consciousness`).
- **article_title**: The title of the post as it will appear on Blogger.
- **article_labels**: A comma-separated list of labels for the Blogger post.

The pipeline has four sequential jobs:

1. **Validate** (`validate` job): Checks that all inputs are provided. If all
   inputs are empty, the build is skipped successfully. If only some are
   provided, the workflow fails.
2. **Detect** (`detect` job): Identifies if the article is Markdown or R
   Markdown based on the files present in the article folder.
3. **Build** (`build` job):
   - **Checkout**: Performs a shallow checkout of the repository.
   - **Build**: Uses the appropriate Docker image (Pandoc for Markdown, GNUR
     for R Markdown) to build the HTML artefact.
   - **Archive**: Uploads the generated HTML as a workflow artefact.
4. **Publish** (`publish` job):
   - **Download**: Downloads the HTML artefact from the build job.
   - **Publish**: Uses a Blogger Docker image to upload the content to Blogger.

## Blogger

To publish to Blogger, the following secrets need to be configured in GitHub:

| Secret                  | Description                                    |
| ----------------------- | ---------------------------------------------- |
| `BLOGGER_BLOG_ID`       | Unique identifier for your destination blog    |
| `BLOGGER_CLIENT_ID`     | Google OAuth Client ID from Cloud Console      |
| `BLOGGER_CLIENT_SECRET` | Google OAuth Client Secret for authorisation   |
| `BLOGGER_REFRESH_TOKEN` | Token for long-term, non-interactive API access|

## Docker Images

The pipeline uses three Docker images:

### Pandoc (DockerHub)

Used to build HTML articles from Markdown.
`frankhjung/pandoc:3.1.11.1`

### GNUR (GHCR)

Used to build HTML articles from R Markdown.
`ghcr.io/frankhjung/gnur:4.5.2`

### Blogger (GHCR)

Used to publish articles to Blogger.
`ghcr.io/frankhjung/blogger:v1.3`
