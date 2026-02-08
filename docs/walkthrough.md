# Walkthrough: Markdown Articles Pipeline

## Summary

Implemented a reusable multi-article markdown project with Pandoc builds and
Blogger publishing via GitHub Actions.

---

## Files Created

### Project Root

| File | Purpose |
|------|---------|
| [Makefile](file:///home/frank/documents/articles/markdown/Makefile) | Delegates builds to article subfolders |
| [README.md](file:///home/frank/documents/articles/markdown/README.md) | Project documentation and usage guide |

### Sample Article: `consciousness/`

| File | Purpose |
|------|---------|
| [Makefile](file:///home/frank/documents/articles/markdown/consciousness/Makefile) | Builds HTML and PDF |
| [consciousness.md](file:///home/frank/documents/articles/markdown/consciousness/consciousness.md) | Article content |
| `README.md` | Hard link to main content |
| `files/article.css` | Hard link to shared CSS |
| `files/preamble.tex` | Hard link to shared TeX |
| `images/` | Article images folder |

### GitHub Actions

| File | Purpose |
|------|---------|
| [publish.yml](file:///home/frank/documents/articles/markdown/.github/workflows/publish.yml) | Parameterised workflow for Blogger publishing |

---

## Verification Results

| Test | Result |
|------|--------|
| HTML build (`public/index.html`) | ✅ Passed |
| PDF build (`public/consciousness.pdf`) | ✅ Passed |
| Hard links working | ✅ Verified |

---

## Usage

**Build an article:**

```bash
cd consciousness && make
```

**Publish via GitHub Actions:**

1. Go to **Actions** → **Publish Article**
2. Enter article name (e.g., `consciousness`)
3. Click **Run workflow**

**Required secrets:** `BLOG_ID`, `CLIENT_ID`, `CLIENT_SECRET`, `REFRESH_TOKEN`
