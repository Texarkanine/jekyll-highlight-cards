---
task_id: freeze-archives-jekyll-subcommand
date: 2026-08-01
complexity_level: 3
---

# Reflection: Freeze archive URLs via Jekyll subcommand

## Summary

Shipped opt-in `jekyll freeze-archives` that freezes IA URLs into eligible `linkcard` / `polaroid` source tags via shared markup analysis and surgical insert. Build and QA passed; one QA fix for relative `Page#path` scanning.

## Requirements vs Outcome

All brief requirements delivered: Jekyll subcommand (not build hook), eligibility/#53 guards, skip existing archive/`none`, dry-run and `--save`, docs for freeze-then-commit and CDX-without-`ARCHIVE=1`. No silent descope. Literal-URL-only freeze was accepted scope with build-time fallback unchanged.

## Plan Accuracy

Step order held: extract-under-green → analyzer → locator → inserter → command → docs → verify. File list and TDD behaviors (A/L/I/C) matched what was built. Challenges that materialized were the ones planned (path enumeration, SAVE env, formatting). Surprise: C1–C6 used posts only, so relative page paths were not exercised until QA.

## Creative Phase Review

- **Source scan & rewrite (B)**: Held up cleanly — shared parsers + surgical insert avoided noisy rebuilds; multiline indent contract (post-preflight amendment) was essential for author-reviewable diffs.
- **CLI/env (B)**: Held up — invoke enables CDX without `ARCHIVE=1`; `--save` / `_SAVE` gate SavePageNow; `--dry-run` as opt-in safety valve matched the intended workflow.

No creative decision needed revision during build.

## Build & QA Observations

Build was smooth under TDD; tag extract stayed green (206 → still green). Command integration against temp sites covered the env/write matrix. QA caught a real completeness bug: `Jekyll::Page#path` is source-relative while `Document#path` is absolute, so pages were silently skipped. Fixed with `site.in_source_dir` + regression test (480 examples).

## Cross-Phase Analysis

Preflight’s explicit TDD ordering prevented freeze features from contaminating the markup extract. Creative B’s “walk pages/docs/posts” was correct but under-specified for Jekyll path shapes — plan challenges mentioned site enumeration, yet fixtures never used a non-collection page. That gap traveled Build → QA rather than Preflight → Build.

## Insights

### Technical

- When scanning a Jekyll site for source files, never assume `page.path` / `doc.path` share the same shape: resolve with `site.in_source_dir` (or absolute-path check) before `File.file?` / prefix filters.
- `ArchiveHelper#archive_url_for` is already ungated by `archive_enabled?`; freeze can call it directly while tags keep the env gate — document the asymmetry rather than weakening the tag path.

### Process

- Integration fixtures that only cover one Jekyll content type (posts) can green-wash path-handling bugs for other types (pages). Prefer at least one page and one collection doc when the plan says “pages/docs/posts.”
