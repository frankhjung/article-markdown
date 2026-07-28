#!/usr/bin/env R

# Render R markdown (Rmd) to HTML or PDF.
#
# Usage:
#   R --quiet --slave --vanilla --file=make.R \
#     --args <source.Rmd> <output.(html|pdf)>

# load packages
require(rmarkdown)

ensure_output_dir <- function(path) {
  out_dir <- dirname(path)
  if (!dir.exists(out_dir) && out_dir != ".") {
    dir.create(out_dir, recursive = TRUE)
  }
}

# require parameters: source file and output file
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop("Usage: make.R <source.Rmd> <output.(html|pdf)>", call. = FALSE)
}

source_file <- args[1]
output_file <- args[2]
ensure_output_dir(output_file)

if (endsWith(output_file, ".html")) {
  render(source_file,
    html_document(
      css = "files/article.css",
      theme = NULL,
      highlight = NULL,
      self_contained = TRUE
    ),
    output_file = output_file
  )
} else if (endsWith(output_file, ".pdf")) {
  # Use standard LaTeX PDF rendering to honour preamble.tex
  render(source_file, pdf_document(
    toc = TRUE,
    toc_depth = 3,
    includes = includes(in_header = "files/preamble.tex")
  ), output_file = output_file)
} else {
  stop("ERROR: output must end with .html or .pdf", call. = FALSE)
}
