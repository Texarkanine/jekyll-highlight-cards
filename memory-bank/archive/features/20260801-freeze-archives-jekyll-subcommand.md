---
task_id: freeze-archives-jekyll-subcommand
complexity_level: 3
date: 2026-08-01
status: completed
---

# TASK ARCHIVE: Freeze archive URLs via Jekyll subcommand

## SUMMARY

Shipped opt-in `jekyll freeze-archives`: scans site source for archive-eligible `linkcard` / `polaroid` tags lacking `archive=` / `archive:none`, looks up Internet Archive via `ArchiveHelper`, and surgically inserts the archive URL into source for a freeze-then-commit workflow. Not a build hook — build-time env-gated auto-lookup remains the forgetful fallback. Parent authorized skip of archive after first reflect in favor of a noarchive rework; this document was written when that rework archived the shared ephemeral bank.

## REQUIREMENTS

- Ship as a Jekyll subcommand registered by the gem — opt-in by invocation only
- Scan pages/docs/posts for eligible tags without encoded archive; reuse #53 eligibility guards
- On successful lookup, insert archive into source; never invent attributes on miss; never rewrite existing `archive=` / `archive:none`
- Do not hook `jekyll build`; preserve build-time fallback
- Support `--dry-run` and SavePageNow via existing `_SAVE` / `--save`
- Document freeze-then-commit workflow

## IMPLEMENTATION

### Creative decisions (inlined)

**Source scan & rewrite (Option B):** Locator + shared markup analysis + surgical insert — not regex-only rewrite, Liquid AST, or full tag rebuild. Shared parsers stay in lockstep with tags; surgical insert preserves author formatting.

- `TagLocator` finds `{% linkcard … %}` / `{% polaroid … %}` spans (multiline supported)
- `MarkupAnalyzer` answers has-archive / target URL / eligible (skips Liquid-dynamic targets)
- `ArchiveInserter`: linkcard `archive:<url>`; polaroid `archive="…"`; single-line splices before `%}`; multiline inserts a new line before the closer, indent copied from last content line

**CLI/env (Option B):** Invocation enables CDX (no `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE=1` required); SavePageNow stays `_SAVE=1` / `--save`; write by default with `--dry-run` as rehearsal. Document the freeze-vs-build CDX asymmetry.

### Key files

- `lib/jekyll-highlight-cards/commands/freeze_archives.rb`
- `lib/jekyll-highlight-cards/freeze_archives/{tag_locator,markup_analyzer,archive_inserter}.rb` (+ shared markup extract from tags)
- Specs under `spec/jekyll_highlight_cards/freeze_archives/`
- README / CHANGELOG for command workflow

### Post-reflect polish (before rework)

- Hand-run progress logging at info (`Looking up` / `frozen` / miss); ignore site `quiet` unless `--quiet`
- Log format carries semantic payloads (rel path, raw URL, archive URL); presentation-coupled asserts removed (SLOBAC)

## TESTING

- TDD across extract → analyzer → locator → inserter → command; tag extract stayed green
- Full suite: 480 examples, 0 failures after QA page-path fix; RuboCop clean on touched files
- `/niko-preflight` PASS; `/niko-qa` PASS
- QA fix: `Jekyll::Page#path` is source-relative while `Document#path` is absolute — resolve with `site.in_source_dir` + regression test (C1–C6 had used posts only, masking the bug)

## LESSONS LEARNED

- Never assume `page.path` / `doc.path` share the same shape when scanning a Jekyll site; resolve with `site.in_source_dir` (or absolute-path check) before `File.file?` / prefix filters
- Integration fixtures that only cover posts can green-wash path bugs for pages — prefer at least one page and one collection doc when the plan says “pages/docs/posts”
- `ArchiveHelper#archive_url_for` is already ungated by `archive_enabled?`; freeze can call it directly while tags keep the env gate — document the asymmetry rather than weakening the tag path
- Applying inserts reverse-sorted by `range.begin` keeps multi-edit files correct without re-locating
- Multiline insert indent fidelity matters for author-reviewable diffs, not just “surgical” byte inserts

## PROCESS IMPROVEMENTS

- Preflight’s explicit TDD ordering (extract under green before freeze units) prevented contamination of the markup extract
- Creative B’s “walk pages/docs/posts” was correct but under-specified for Jekyll path shapes — that gap traveled Build → QA rather than Preflight → Build

## TECHNICAL IMPROVEMENTS

None required beyond what shipped; optional `--path` / `--limit` deferred as advisory follow-up.

## NEXT STEPS

- Follow-on noarchive config rework archived as `memory-bank/archive/enhancements/20260801-noarchive-config.md`
- Draft PR #56 covers freeze-archives + noarchive on `onetime-archive`
