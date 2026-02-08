# Walkthrough: Markdown Articles Pipeline (Implemented)

## Summary

Implemented a reusable multi-article markdown project with Pandoc builds and
Blogger publishing via GitHub Actions.

---

## Files Created

### Project Root

| File | Purpose |
|------|---------|
| [Makefile](Makefile) | Delegates builds to article subfolders |
| [article.mk](article.mk) | Shared build logic for all articles |
| [README.md](README.md) | Project documentation and usage guide |

### Sample Article: `consciousness/`

| File | Purpose |
|------|---------|
| [Makefile](consciousness/Makefile) | Builds HTML and PDF |
| [consciousness.md](consciousness/consciousness.md) | Article content |
| `files/article.css` | Hard link to shared CSS |
| `files/preamble.tex` | Hard link to shared TeX |
| `images/` | Article images folder |

### GitHub Actions

| File | Purpose |
|------|---------|
| [publish.yml](.github/workflows/publish.yml) | Parameterised workflow for Blogger publishing |

---

## Verification Results

| Test | Result |
|------|--------|
| HTML build (`public/[article_name].html`) | ✅ Passed |
| PDF build (`public/[article_name].pdf`) | ✅ Passed |
| Hard links working | ✅ Verified |

---

## Usage

**Build an article locally:**

```bash
make consciousness
```

**Publish via GitHub Actions:**

1. Go to **Actions** → **publish article**
2. Click **Run workflow**
3. Enter:
   - **Article folder name**: (e.g., `consciousness`)
   - **Article title**: (e.g., `My Thoughts on Consciousness`)
   - **Comma-separated list of labels**: (e.g., `philosophy, science`)
4. Click **Run workflow**

**Required secrets:** `BLOGGER_BLOG_ID`, `BLOGGER_CLIENT_ID`, `BLOGGER_CLIENT_SECRET`, `BLOGGER_REFRESH_TOKEN`
