# TODO

To implement the build of HTML from R Markdown or Markdown files, we need to:

- [x] update the GitHub pipeline to detect the type of article (R Markdown or Markdown)
- [x] update Makefile's `new-article` target to create the appropriate files
  - [x] What else do we need to change in the top level Makefile?
- [x] update the template `article.mk` for each type of article perhaps:
  - [x] `article_md.mk` for markdown articles
  - [x] `article_rmd.mk` for rmarkdown articles
- [x] update directory `test/` to `test-md/`
- [x] copy  directory `rmarkdown/test/` as `test-rmd/`
- [x] update README.md
  - [x] update descriptions
  - [x] update workflow diagram
