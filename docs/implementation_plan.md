# Markdown Articles Pipeline - Implementation Plan (Implemented)

Setup a reusable multi-article markdown project that builds HTML/PDF via Pandoc
and publishes to Blogger through a parameterised GitHub Actions workflow.

## Blogger API Integration

The pipeline requires 4 GitHub secrets for Blogger API access:

- `BLOGGER_BLOG_ID`
- `BLOGGER_CLIENT_ID`
- `BLOGGER_CLIENT_SECRET`
- `BLOGGER_REFRESH_TOKEN`

---

## Implemented Changes

### Project Root Structure

#### [Makefile](Makefile)

Root Makefile that provides:

- Help target listing available articles
- Delegates build to article subfolders
- Clean target for all articles

#### [article.mk](article.mk)

Common Makefile included or used as a template by article subfolders.

#### [README.md](README.md)

Project documentation covering project overview, creation of new articles,
local build instructions, and pipeline usage.

---

### Article Structure (e.g., `consciousness/`)

#### [consciousness/Makefile](consciousness/Makefile)

Article-specific Makefile:

- Builds `[article_name].md` → `public/[article_name].html`
- Builds `[article_name].md` → `public/[article_name].pdf`
- Uses hard-linked `files/` resources

#### [consciousness/consciousness.md](consciousness/consciousness.md)

Main article content.

#### [consciousness/files/](consciousness/files/)

Directory containing hard links to:

- `article.css` → `../../files/article.css`
- `preamble.tex` → `../../files/preamble.tex`

#### [consciousness/images/](consciousness/images/)

Images directory for the article.

---

### GitHub Actions Pipeline

#### [.github/workflows/publish.yml](.github/workflows/publish.yml)

Parameterised workflow that:

- Triggers manually with `article_name`, `article_title`, and `article_labels`
- Uses Pandoc Docker image to build the article.
- Uses Blogger Docker image to publish the generated HTML.

---

## Verification

### Local Build Test

```bash
make consciousness
ls -la consciousness/public/
# Should show: consciousness.html, consciousness.pdf
```

### Manual Verification

1. Open `consciousness/public/consciousness.html` in a browser to verify rendering.
2. Open `consciousness/public/consciousness.pdf` to verify PDF generation.
3. Check that CSS styling is applied correctly.
4. Verify hard links:

   ```bash
   ls -li consciousness/files/article.css files/article.css
   # Inode numbers should match
   ```
