# Markdown Articles

A reusable project for writing and publishing markdown articles to Blogger.

## Project Structure

```text
markdown/
├── files/                    # Shared resources
│   ├── article.css           # HTML styling
│   └── preamble.tex          # PDF preamble
├── images/                   # Shared images (if used)
├── docs/                     # Project docs
├── <article>/                # Article subfolder
│   ├── <article>.md          # Main content
│   ├── Makefile              # Article build rules
│   ├── docs/                 # [OPTIONAL] Supporting documents for article
│   ├── files/                # Hard links to shared files
│   ├── images/               # Article images
│   └── public/               # Build output
└── .github/workflows/
    └── publish.yml           # Blogger publishing pipeline
```

## Creating a New Article

1. Create a new folder with the article name (e.g., `my-article/`)

2. Create the article Makefile:

   ```makefile
   # Use the Makefile from an existing article as a template
   ```

   Copy the full Makefile from an existing article.

3. Create `<article>.md` with YAML front matter:

   ```markdown
   ---
   title: My Article Title
   author: Your Name
   date: 2026-02-08
   ---

   # Introduction

   Your content here...
   ```

4. Create hard links to shared files:

   ```bash
   mkdir -p my-article/files
   ln files/article.css my-article/files/
   ln files/preamble.tex my-article/files/
   ```

5. Create an images folder with a banner:

   ```bash
   mkdir -p my-article/images
   # add images/banner.png
   ```

6. Create the README hard link:

   ```bash
   ln my-article/my-article.md my-article/README.md
   ```

## Building Locally

Build a specific article:

```bash
make consciousness
```

Or build directly in the article folder:

```bash
cd consciousness
make
```

This generates:

- `public/index.html` - Standalone HTML article
- `public/<article>.pdf` - PDF version

Clean build artifacts:

```bash
make consciousness-clean
# or
make clean  # Clean all articles
```

## Publishing to Blogger

The GitHub Actions workflow publishes articles to Blogger.

### Trigger the Workflow

1. Go to **Actions** → **Publish Article**
2. Click **Run workflow**
3. Enter the article name (e.g., `consciousness`)
4. Enter the article title and labels
4. Click **Run workflow**

### Required Secrets

Configure these in **Settings** → **Secrets and variables** → **Actions**:

| Secret           | Description                                    |
| ---------------- | ---------------------------------------------- |
| `BLOGGER_BLOG_ID`        | Your Blogger blog identifier                   |
| `BLOGGER_CLIENT_ID`      | Google OAuth Client ID from Cloud Console      |
| `BLOGGER_CLIENT_SECRET`  | Google OAuth Client Secret                     |
| `BLOGGER_REFRESH_TOKEN`  | Long-term token for non-interactive API access |

See
[Blogger API documentation](https://developers.google.com/blogger/docs/3.0/using)
for setup instructions.

## Dependencies

- [Pandoc](https://pandoc.org/) - Document conversion
- [XeLaTeX](https://tug.org/xetex/) - PDF generation (via TeX Live)

Install on Ubuntu/Debian:

```bash
sudo apt-get install pandoc texlive-xetex texlive-fonts-recommended
```
