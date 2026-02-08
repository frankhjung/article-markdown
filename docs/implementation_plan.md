# Markdown Articles Pipeline - Implementation Plan

Setup a reusable multi-article markdown project that builds HTML/PDF via Pandoc
and publishes to Blogger through a parameterised GitHub Actions workflow.

## User Review Required

> [!IMPORTANT]
> **Blogger API Integration**: The pipeline will require 4 GitHub secrets for
> Blogger API access. You'll need to set these up in your GitHub repository
> settings before the publish step will work.

> [!NOTE]
> **Reference Projects**: The requirements mention reference projects
> (`consciousness/`, `magic-triangle/`, `publish-to-blogspot/`) which don't
> exist in the current workspace. I'll create a sample article structure based
> on the requirements specification.

---

## Proposed Changes

### Project Root Structure

#### [NEW] [Makefile](file:///home/frank/documents/articles/markdown/Makefile)

Root Makefile that provides:

- Help target listing available articles
- Delegates build to article subfolders
- Clean target for all articles

#### [NEW] [README.md](file:///home/frank/documents/articles/markdown/README.md)

Project documentation covering:

- Project overview and structure
- How to create a new article
- Local build instructions
- GitHub Actions pipeline usage
- Blogger secrets setup

---

### Sample Article: `consciousness/`

#### [NEW] [consciousness/Makefile](file:///home/frank/documents/articles/markdown/consciousness/Makefile)

Article-specific Makefile using the template from requirements:

- Builds `consciousness.md` → `public/index.html`
- Builds `consciousness.md` → `public/consciousness.pdf`
- Uses hard-linked `files/` resources

#### [NEW] [consciousness/consciousness.md](file:///home/frank/documents/articles/markdown/consciousness/consciousness.md)

Sample article content with YAML frontmatter (title, author, date).

#### [NEW] [consciousness/README.md](file:///home/frank/documents/articles/markdown/consciousness/README.md)

Hard link to `consciousness.md` for GitHub display.

#### [NEW] [consciousness/files/](file:///home/frank/documents/articles/markdown/consciousness/files/)

Directory containing hard links to:

- `article.css` → `../../files/article.css`
- `preamble.tex` → `../../files/preamble.tex`

#### [NEW] [consciousness/images/](file:///home/frank/documents/articles/markdown/consciousness/images/)

Images directory with placeholder banner.

---

### GitHub Actions Pipeline

#### [NEW] [.github/workflows/publish.yml](file:///home/frank/documents/articles/markdown/.github/workflows/publish.yml)

Parameterised workflow that:

- Triggers manually with `article_name` input
- Installs Pandoc and XeLaTeX
- Runs `make` in the article subfolder
- Publishes `public/index.html` to Blogger API using secrets

---

## Verification Plan

### Local Build Test

```bash
cd /home/frank/documents/articles/markdown/consciousness
make clean
make
ls -la public/
# Should show: index.html, consciousness.pdf
```

### GitHub Actions Syntax Validation

```bash
# Requires actionlint: https://github.com/rhysd/actionlint
actionlint .github/workflows/publish.yml
```

### Manual Verification

1. Open `public/index.html` in a browser to verify HTML rendering
2. Open `public/consciousness.pdf` to verify PDF generation
3. Check that CSS styling is applied correctly
4. Verify hard links are working:

   ```bash
   ls -li consciousness/files/article.css files/article.css
   # Inode numbers should match
   ```
