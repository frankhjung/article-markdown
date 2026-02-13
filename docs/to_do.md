# TODO

To implement the build of HTML from R Markdown or Markdown files, we need to:

- [x] update the GitHub pipeline to detect the type of article (R Markdown or
  Markdown)
- [x] update Makefile's `new-article` target to create the appropriate files
  - [x] What else do we need to change in the top level Makefile?
- [x] update the template `article.mk` for each type of article perhaps:
  - [x] `article_md.mk` for markdown articles
  - [x] `article_rmd.mk` for rmarkdown articles
- [x] update directory `test/` to `test-md/`
- [x] copy directory `rmarkdown/test/` as `test-rmd/`
- [x] update README.md
  - [x] update descriptions
  - [x] update workflow diagram

## Review

Scope This review covers build Makefiles for Markdown and R Markdown articles,
the GitHub Actions workflow, and README consistency with current implementation.

### HIGH

1. Incorrect local PDF build command in README for Markdown article folders
   - Finding: README instructs running `make consciousness.pdf` from inside an
     article folder. For Markdown articles, the template exposes `pdf` and does
     not expose `<project>.pdf` as a target.
   - Impact: Local PDF builds fail for most Markdown articles when following
     README exactly.
   - Evidence:
      - README.md:164-170
      - article_md.mk:28-36
      - article_rmd.mk:28-29
   - Recommendation: Update README to use `make pdf` when inside an article
     directory, or use `make <article> output=pdf` from root.

### MEDIUM

1. README workflow input requirements do not fully match runtime behaviour
   - Finding: README says all three inputs are required and missing inputs cause
     validation failure. Workflow actually allows all-empty input and exits
     successfully with `build=false` (skip path).
   - Impact: Operator confusion about expected workflow outcome when no inputs
     are supplied.
   - Evidence:
      - README.md:203-204
      - publish.yml:34-39
      - publish.yml:42-46
   - Recommendation: Clarify README: “Inputs are conditionally required;
     all-empty skips, partial input fails.”
2. requirements document is outdated vs current codebase
   - Finding: requirements describes a single shared `article.mk`, md-only
     article assumption, and a 2-job pipeline; current implementation uses
     `article_md.mk` and `article_rmd.mk`, supports both `article.md` and
     `article.Rmd`, and has 4 jobs (validate, detect, build, publish).
   - Impact: Documentation drift increases maintenance risk and onboarding
     friction.
   - Evidence:
      - requirements.md:4-5
      - requirements.md:29-40
      - requirements.md:112-121
      - publish.yml:21-116
   - Recommendation: Refresh requirements to reflect dual templates and 4-stage
     workflow.

### LOW

1. Input “required” semantics are technically valid but ambiguous
   - Finding: Workflow dispatch inputs are marked `required: false` and enforced
     later by validation logic.
   - Impact: Low functional risk, moderate readability/UX confusion for
     maintainers.
   - Evidence:
      - publish.yml:9-17
      - publish.yml:34-46
   - Recommendation: Add brief comment in workflow and README explaining
     intentional conditional validation.
2. Minor terminology drift between docs and implementation detail
   - Finding: Documentation language around toolchain steps (especially Rmd/GNUR
     wording) is less precise than workflow implementation.
   - Impact: Low; mostly clarity and supportability.
   - Evidence:
      - README.md:15-18
      - publish.yml:91-96
   - Recommendation: Align wording with exact execution path used by workflow.

### Priority order:

- Fix README PDF command guidance (HIGH).
- Align README input-requirement wording with workflow behaviour (MEDIUM). with
  workflow behaviour (MEDIUM).
- Refresh requirements documentation to match current architecture (MEDIUM).
- Tidy low-severity wording/terminology consistency (LOW).

## Remediation plan

### Phase 1 (HIGH) — fix incorrect PDF command guidance

- [ ] Update `README.md` local build instructions for article-folder PDF builds:
  - [ ] replace `make consciousness.pdf` (inside article folder) with `make pdf`
  - [ ] keep root-level alternative `make <article> output=pdf`
- [ ] Re-check `README.md` examples for both md and Rmd to ensure commands are
  valid in stated working directory.

### Phase 2 (MEDIUM) — align workflow input semantics in docs

- [ ] Update `README.md` workflow section to state conditional validation:
  - [ ] all-empty inputs => workflow exits successfully with build skipped
  - [ ] partial inputs => validation failure
  - [ ] all three inputs provided => build + publish path
- [ ] Add one short note explaining why workflow-dispatch inputs are
  `required: false` while runtime validation enforces rules.

### Phase 3 (MEDIUM) — refresh requirements document

- [ ] Update `docs/requirements.md` to reflect current architecture:
  - [ ] split templates: `files/article_md.mk` and `files/article_rmd.mk`
  - [ ] article source types: `article.md` or `article.Rmd`
  - [ ] workflow stages: `validate` -> `detect` -> `build` -> `publish`
  - [ ] Docker image usage for md and Rmd builds
- [ ] Remove references to deprecated single-template model (`article.mk`).

### Phase 4 (LOW) — consistency cleanup

- [ ] Standardise terminology across docs for R Markdown build path and image
  naming.
- [ ] Run a docs pass for internal consistency of file names and target names.

### Validation and sign-off

- [ ] From project root, run:
  - [ ] `make test-md`
  - [ ] `make test-rmd`
- [ ] In article folder, verify:
  - [ ] `make` builds `public/article.html`
  - [ ] `make pdf` builds `public/<article>.pdf`
- [ ] Trigger workflow manually with:
  - [ ] all inputs empty (expect skip)
  - [ ] partial inputs (expect validation fail)
  - [ ] all inputs present (expect publish path)

