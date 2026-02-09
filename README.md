# Markdown Articles

A reusable project for writing and publishing markdown articles to Blogger.

This project will publish Markdown articles to Blogger using GitHub Actions.

Each sub-directory is its own article, with a Makefile, images and supporting
files:

## Project Structure

```text
markdown/
├── Makefile                  # Top level build rules
├── article.mk                # Template article build rules
├── files/                    # Shared resources
│   ├── article.css           # HTML styling
│   └── preamble.tex          # PDF preamble
├── images/                   # Shared images (if used)
├── docs/                     # Project docs
├── <article>/                # Article subfolder
│   ├── <article>.md          # Main content
│   ├── Makefile              # Article build rules (hard link to article.mk)
│   ├── docs/                 # [OPTIONAL] Supporting documents for article
│   ├── files/                # Hard links to shared files
│   ├── images/               # Article images
│   └── public/               # Build output
└── .github/workflows/
    └── publish.yml           # Blogger publishing pipeline
```

## Creating a New Article

1. Create a new folder with the article name (e.g., `my-article/`)

2. Create a hard link to the article Makefile template:

   ```bash
   ln article.mk my-article/Makefile
   ```

3. Create `<article>.md` with YAML front matter:

   ```markdown
   ---
   title: My Article
   author: "[Your Name](https://www.linkedin.com/in/yourname/)"
   date: 2026-02-08       # note this gets updated automatically on publishing
   labels: article, blog  # update with your own labels
   ---

   *Your content here.*
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

6. [Optional] Add supporting documents to `my-article/docs/`

## Building Locally

Build a specific article (HTML only):

```bash
make consciousness
```

Or build directly in the article folder:

```bash
cd consciousness
# HTML is the default target
make
```

This generates:

- `public/consciousness.html` - Standalone HTML article

To also build a PDF version:

```bash
cd consciousness
make public/consciousness.pdf
```

Clean build artifacts:

```bash
make consciousness-clean
# or
make clean  # Clean all articles' generated public folders
```

## Publishing to Blogger

The GitHub Actions workflow publishes articles to Blogger.

### Trigger the Workflow

1. Go to **Actions** → **publish article**
2. Click **Run workflow**
3. Enter the required inputs:
   - **Article folder name**: (e.g., `consciousness`)
   - **Article title**: The title of the post on Blogger
   - **Comma-separated list of labels**: Labels for the post
4. Click **Run workflow**

### Required Secrets

Configure these in **Settings** → **Secrets and variables** → **Actions**:

| Secret                   | Description                                    |
| ------------------------ | ---------------------------------------------- |
| `BLOGGER_BLOG_ID`        | Your Blogger blog identifier                   |
| `BLOGGER_CLIENT_ID`      | Google OAuth Client ID from Cloud Console      |
| `BLOGGER_CLIENT_SECRET`  | Google OAuth Client Secret                     |
| `BLOGGER_REFRESH_TOKEN`  | Long-term token for non-interactive API access |

See
[Blogger API documentation](https://developers.google.com/blogger/docs/3.0/using)
for setup instructions.

## Dependencies

- [GitHub Actions](https://github.com/features/actions) - Workflow automation
- [GNUMake](https://www.gnu.org/software/make/) - Build tool
- [Pandoc](https://pandoc.org/) - Document conversion
- [XeLaTeX](https://tug.org/xetex/) - PDF generation (via TeX Live)
- [Blogger API](https://developers.google.com/blogger/docs/3.0/using) -
  Publishing platform
