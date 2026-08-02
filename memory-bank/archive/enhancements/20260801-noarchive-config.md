---
task_id: noarchive-config
complexity_level: 2
date: 2026-08-01
status: completed
---

# TASK ARCHIVE: Configurable noarchive URL skip list

## SUMMARY

Level 2 rework after freeze-archives: added `highlight_cards.noarchive` (array of regex strings in `_config.yml`) so matching URLs are treated as not archiveable — skip lookup only, never write `archive:none`. Shared gate is `ArchiveHelper#archiveable_url?(…, site:)`, covering build-time tags and `jekyll freeze-archives`. Explicit archive attributes remain untouched.

## REQUIREMENTS

- Config: `highlight_cards.noarchive` list of regex strings; full-URL match; invalid regex raises (`RegexpError`)
- On match: skip CDX / SavePageNow; do not write `archive:none` (so later config changes can reattempt)
- Do not alter tags that already have `archive=` / `archive:none`
- Applies to in-build auto-lookup and freeze-archives; document in README

## IMPLEMENTATION

- Optional `site:` on `archiveable_url?` / `archive_url_for`; after URI/host guards, match full URL against compiled patterns
- Memoized compiled regexps in `ArchiveHelper.noarchive_regexp_cache` keyed by site + raw list
- Wired: both tags (auto-lookup path), freeze `MarkupAnalyzer` + command
- Patterns intentionally **unanchored** (`Regexp.new` + `match?`); authors add `\A` / `\z` when needed — bare `x\.com` can substring-match hosts like `notx.com`
- Key files: `archive_helper.rb`, `linkcard_tag.rb`, `polaroid_tag.rb`, freeze analyzer/command, `README.md`, specs under `spec/jekyll_highlight_cards/`

## TESTING

- Extended `archive_helper_spec`, freeze analyzer/command specs (match-skip, non-match, empty config, multi-pattern, invalid regex, explicit archive untouched, regression of archive.org/local guards)
- Full suite: 491 examples, 0 failures; `/niko-preflight` PASS; `/niko-qa` PASS (no code changes in QA)
- Contract insight validated in QA: eligibility must precede `archive_cache` so noarchive cannot be bypassed by a prior hit for the same URL

## LESSONS LEARNED

- Eligibility checks must run *before* the per-URL archive cache
- Unanchored-by-default is the right authoring default for this gate; anchoring belongs in the pattern, not the helper
- Optional `site:` is the minimal compatible form of “site-aware ArchiveHelper”; if noarchive had been assumed from day one, site would already be required/ambient on the helper

## PROCESS IMPROVEMENTS

- Post-reflect operator Q&A clarified anchoring semantics; folding that into the reflection before archive kept the contract durable
- Preflight advisory (memoize compiled regexps) was cheap to implement inside the first unit and worth taking

## TECHNICAL IMPROVEMENTS

None beyond the memoized regexp cache shipped with the feature.

## NEXT STEPS

- Parent freeze-archives feature archived as `memory-bank/archive/features/20260801-freeze-archives-jekyll-subcommand.md`
- Draft PR #56 review follow-ups continue on `onetime-archive` as needed
