# Markdown Articles

This `markdown` folder is the parent folder for all markdown
articles. Each article is in its own subfolder, and each subfolder contains a
`README.md` file that is a hard link to the main content of the article.

## Objective

We would like to setup this project so it can be re-used for multiple articles.
The pipeline will build one HTML artifact per article: `public/index.html`.
This will be published to Blogger. The pipeline should be parameterised by the
article name, so that it can be reused for each article. The pipeline should
build the article using the `Makefile` and then publish it to Blogger. The
pipeline need only build and publish one article at a time, so it can be
triggered manually with the article name (`[article_name]`) as a parameter.

## Reference Projects

For example of the project structure see the folders:

- `consciousness/`
- `magic-triangle/`
- `publish-to-blogspot/`

## Build

Use this `Makefile` as a template for each article:

```Makefile
#!/usr/bin/make

.SUFFIXES:
.SUFFIXES: .html .md .pdf

PROJECT:= [sub_folder_name]
PANDOC := pandoc

default: $(PROJECT).html $(PROJECT).pdf

.md.html:
 @mkdir -p public
 @$(PANDOC) \
  --from=gfm --to html5 \
  --embed-resources --standalone \
  --css files/article.css \
  --output public/$@ \
  $<
 @mv public/$@ public/index.html

.md.pdf:
 @mkdir -p public
 @$(PANDOC) \
  --include-in-header files/preamble.tex \
  --from=markdown --pdf-engine=xelatex \
  --css files/article.css \
  --toc \
  --output public/$@ \
  $<

.PHONY: update-date
update-date:
 sed -i "s/^date: .*/date: $(shell date +%Y-%m-%d)/" $(PROJECT).md

.PHONY: clean
clean:
 @$(RM) -rf public
```

## Common Files

There are some common files (`files/`) that will be used for each article:

- `files/article.css` - This file contains the CSS styles for the article.
- `files/preamble.md` - This file contains the TeX preamble for the article.

These can be hard links from the root project folder, `markdown/`.

## Images

There is an image folder (`images/`) for each article, and the images should be
placed in that folder. The images can be referenced in the `README.md` file
using relative paths. There will be at least one image being the article banner,
`images/banner.png`.

## GitHub Pipeline

The project will have one GitHub pipeline that will build the article and
publish it to Blogger. See `publish-to-blogspot/.github/workflows/pages.yml` as
an example of the pipeline.

The pipeline will build one HTML artifact per article: `public/index.html`. This
will be published to Blogger.

The pipeline should be parameterised by the article name, so that it can be
reused for each article. The pipeline should build the article using the
`Makefile` and then publish it to Blogger. The pipeline need only build and
publish one article at a time, so it can be triggered manually with the article
name (`[article_name]`) as a parameter.

i.e.

parameter: `article_name` - the name of the article to build and publish (e.g.
`consciousness`) output: `public/index.html` - the HTML file that will be
published to Blogger

## Blogger

To publish to blogger the following secrets need to be set up in GitHub:

- `BLOG_ID` - The unique identifier for your specific destination blog
- `CLIENT_ID` - The Google OAuth Client ID derived from the Cloud Console
- `CLIENT_SECRET` - The Google OAuth Client Secret used for authorization
- `REFRESH_TOKEN` - The secure token that allows for long-term, non-interactive API access
