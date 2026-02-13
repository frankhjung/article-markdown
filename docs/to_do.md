# TODO

To implement the build of HTML from R Markdown or Markdown files, we need to:

- [x] update the GitHub pipeline to detect the type of article (R Markdown or Markdown)
- [ ] update Makefile's `new-article` target to create the appropriate files
  - [ ] What else do we need to change in the top level Makefile?
- [ ] update the template `article.mk` for each type of article perhaps:
  - [ ] `article_md.mk` for markdown articles
  - [ ] `article_rmd.mk` for rmarkdown articles
- [ ] update directory `test/` to `test-md/`
- [ ] copy  directory `rmarkdown/test/` as `test-rmd/`
- [ ] update README.md
  - [ ] update descriptions
  - [ ] update workflow diagram
