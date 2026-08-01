# Task: Freeze archive URLs via Jekyll subcommand

* Task ID: freeze-archives-jekyll-subcommand
* Complexity: Level 3
* Type: feature

Opt-in Jekyll subcommand that freezes Internet Archive URLs into source for archive-eligible `linkcard` / `polaroid` tags that lack `archive=` / `archive:none`.

## Component Analysis

### Affected Components

- **Gem entrypoint** (`lib/jekyll-highlight-cards.rb`): loads tags/hooks today → must require/register the new `Jekyll::Command` subclass so `bundle exec jekyll <cmd>` sees it when the gem is a plugin
- **New: FreezeArchives command** (`lib/jekyll-highlight-cards/commands/freeze_archives.rb` or similar): no current responsibility → implement `Jekyll::Command` that loads the site, drives scan/rewrite, reports results
- **New: Source scanner/rewriter** (name TBD by creative): none today → find candidate tags in source files, decide eligibility, insert archive markup in-place
- **ArchiveHelper** (`lib/jekyll-highlight-cards/archive_helper.rb`): CDX lookup, optional SavePageNow, eligibility (`archiveable_url?`), env gates, build cache → reused for lookups; may need a freeze-oriented entry (env policy TBD by creative)
- **LinkcardTag / PolaroidTag**: parse markup + `resolve_archive` at render time → freeze tool must understand the same archive syntax (`archive:` vs `archive=`) and skip rules; ideally reuse markup parsing rather than duplicate
- **README / CHANGELOG**: document command + freeze-then-commit workflow

### Cross-Module Dependencies

- Command → Site content enumeration → Scanner/rewriter → (shared or extracted) tag markup parsers → ArchiveHelper lookup → file write
- Tags continue to call ArchiveHelper at build time for unfrozen tags (unchanged contract)

### Boundary Changes

- New public authoring surface: a Jekyll subcommand (not a Generator)
- No change to Liquid tag render contracts when `archive=` / `archive:` already present
- Possible extraction of markup-parse helpers from tag classes for shared use (internal refactor)

### Invariants & Constraints

- Must not run as part of `jekyll build` / render lifecycle
- Must not rewrite tags that already have `archive=` / `archive:none` / `archive:…`
- Must preserve #53 eligibility: absolute http(s) only; skip archive.org hosts; polaroid without `link=` is not a freeze candidate
- Must leave failed lookups without inventing archive attributes
- Source files are the write target; tool does not commit
- Build-time env-gated auto-lookup remains available as fallback

## Open Questions

- [x] **Source scan & rewrite architecture** → Resolved: Locator + shared markup analysis (extract/reuse tag parsers) + surgical archive-token insert; skip Liquid dynamic targets (see `memory-bank/active/creative/creative-source-scan-rewrite.md`)
- [x] **CLI / env policy** → Resolved: Command name `freeze-archives`; invocation enables CDX (no `ARCHIVE=1`); SavePageNow via `_SAVE=1` or `--save`; write by default with `--dry-run` (see `memory-bank/active/creative/creative-cli-env-policy.md`)

## Status

- [x] Component analysis complete
- [x] Open questions resolved
- [ ] Test planning complete (TDD)
- [ ] Implementation plan complete
- [ ] Technology validation complete
- [ ] Pre-Mortem complete
- [ ] Preflight
- [ ] Build
- [ ] QA
