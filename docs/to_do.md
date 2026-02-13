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
   - [x] Finding: README instructs running `make consciousness.pdf` from inside
     an article folder. For Markdown articles, the template exposes `pdf` and
     does not expose `<project>.pdf` as a target.
   - [x] Impact: Local PDF builds fail for most Markdown articles when following
     README exactly.
   - [x] Recommendation: Update README to use `make pdf` when inside an article
     directory, or use `make <article> output=pdf` from root.

### MEDIUM

1. README workflow input requirements do not fully match runtime behaviour
   - [x] Finding: README says all three inputs are required and missing inputs
     cause validation failure. Workflow actually allows all-empty input and
     exits successfully with `build=false` (skip path).
   - [x] Impact: Operator confusion about expected workflow outcome when no
     inputs are supplied.
   - [x] Recommendation: Clarify README: “Inputs are conditionally required;
     all-empty skips, partial input fails.”
2. requirements document is outdated vs current codebase
   - [x] Finding: requirements describes a single shared `article.mk`, md-only
     article assumption, and a 2-job pipeline; current implementation uses
     `article_md.mk` and `article_rmd.mk`, supports both `article.md` and
     `article.Rmd`, and has 4 jobs (validate, detect, build, publish).
   - [x] Impact: Documentation drift increases maintenance risk and onboarding
     friction.
   - [x] Recommendation: Refresh requirements to reflect dual templates and
     4-stage workflow.

### LOW

1. Input “required” semantics are technically valid but ambiguous
   - [x] Finding: Workflow dispatch inputs are marked `required: false` and
     enforced later by validation logic.
   - [x] Impact: Low functional risk, moderate readability/UX confusion for
     maintainers.
   - [x] Recommendation: Add brief comment in workflow and README explaining
     intentional conditional validation.
2. Minor terminology drift between docs and implementation detail
   - [x] Finding: Documentation language around toolchain steps (especially
     Rmd/GNUR wording) is less precise than workflow implementation.
   - [x] Impact: Low; mostly clarity and supportability.
   - [x] Recommendation: Align wording with exact execution path used by
     workflow.

## Remediation plan

### Phase 1 (HIGH) — fix incorrect PDF command guidance

- [x] Update `README.md` local build instructions for article-folder PDF builds:
  - [x] replace `make consciousness.pdf` (inside article folder) with `make pdf`
  - [x] keep root-level alternative `make <article> output=pdf`
- [x] Re-check `README.md` examples for both md and Rmd to ensure commands are
  valid in stated working directory.

### Phase 2 (MEDIUM) — align workflow input semantics in docs

- [x] Update `README.md` workflow section to state conditional validation:
  - [x] all-empty inputs => workflow exits successfully with build skipped
  - [x] partial inputs => validation failure
  - [x] all three inputs provided => build + publish path
- [x] Add one short note explaining why workflow-dispatch inputs are
  `required: false` while runtime validation enforces rules.

### Phase 3 (MEDIUM) — refresh requirements document

- [x] Update `docs/requirements.md` to reflect current architecture:
  - [x] split templates: `files/article_md.mk` and `files/article_rmd.mk`
  - [x] article source types: `article.md` or `article.Rmd`
  - [x] workflow stages: `validate` -> `detect` -> `build` -> `publish`
  - [x] Docker image usage for md and Rmd builds
- [x] Remove references to deprecated single-template model (`article.mk`).

### Phase 4 (LOW) — consistency cleanup

- [x] Standardise terminology across docs for R Markdown build path and image
  naming.
- [x] Run a docs pass for internal consistency of file names and target names.

### Validation and sign-off

- [x] From project root, run:
  - [x] `make test-md`
  - [x] `make test-rmd`
- [x] In article folder, verify:
  - [x] `make` builds `public/article.html`
  - [x] `make pdf` builds `public/<article>.pdf`
- [ ] Trigger workflow manually with:
  - [ ] all inputs empty (expect skip)
  - [ ] partial inputs (expect validation fail)
  - [ ] all inputs present (expect publish path)
