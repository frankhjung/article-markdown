# Project Tasks: Markdown Articles Pipeline

## Overview

Setup a reusable multi-article markdown project with Pandoc build and Blogger
publishing.

---

## Phase 1: Project Structure Setup

- [x] Create root `Makefile` that delegates to article subfolders
- [x] Create article template structure (for new articles)
  - [x] Template `Makefile` per article
  - [x] Template `README.md` with frontmatter
  - [x] Template `images/` folder with placeholder `banner.png`
- [x] Ensure `files/article.css` is linkable from article subfolders
- [x] Ensure `files/preamble.tex` is linkable from article subfolders

---

## Phase 2: Sample Article Creation

- [x] Create first sample article (e.g., `consciousness/`)
  - [x] Create `consciousness/Makefile`
  - [x] Create `consciousness/consciousness.md` main content
  - [x] Create `consciousness/README.md` hard link
  - [x] Create `consciousness/images/` folder
  - [x] Link `files/article.css` into article
  - [x] Link `files/preamble.tex` into article

---

## Phase 3: GitHub Actions Pipeline

- [x] Create `.github/workflows/publish.yml`
  - [x] Parameterise with `article_name` input
  - [x] Setup Pandoc in workflow
  - [x] Build article using `make` in article subfolder
  - [x] Publish `public/index.html` to Blogger API
  - [x] Document required secrets:
    - `BLOG_ID`
    - `CLIENT_ID`
    - `CLIENT_SECRET`
    - `REFRESH_TOKEN`

---

## Phase 4: Documentation

- [x] Create/update root `README.md` with:
  - [x] Project overview
  - [x] How to create a new article
  - [x] How to build locally
  - [x] How to trigger the publish pipeline
  - [x] Secrets setup instructions

---

## Verification

- [x] Verify local build works: `make` in article folder produces
      `public/index.html`
- [x] Verify PDF generation works: `make` produces `public/[article].pdf`
- [x] Verify GitHub Actions workflow syntax is valid
