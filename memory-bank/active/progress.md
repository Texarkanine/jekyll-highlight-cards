# Progress

Ship freeze-archives, then rework: add `highlight_cards.noarchive` regex list so build-time and freeze-archives skip archive attempts for matching URLs.

**Complexity:** Level 2

## 2026-08-01 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Intent clarified and approved: Jekyll subcommand (not build lifecycle) freezes missing archive URLs into source
    - Classified as Level 3 (complete feature: command + scan/rewrite + ArchiveHelper reuse)
* Decisions made
    - Packaging shape fixed to Jekyll subcommand per operator
    - Build-time env-gated auto-lookup remains as fallback
* Insights
    - Tags already accept explicit `archive=` / `archive:none`; the gap is an authoring tool that writes that path

## 2026-08-01 - CREATIVE - COMPLETE

* Work completed
    - Architecture: locator + shared markup analysis + surgical insert (`creative-source-scan-rewrite.md`)
    - CLI/env: invoke enables CDX; SAVE via env/`--save`; write default + `--dry-run` (`creative-cli-env-policy.md`)
* Decisions made
    - Skip Liquid-dynamic archive targets (build-time fallback remains)
    - Freeze does not require `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE=1`
* Insights
    - Surgical insert preserves author formatting better than full tag rebuild

## 2026-08-01 - PLAN - COMPLETE

* Work completed
    - Full L3 plan in `tasks.md`: components, TDD behaviors, 7 implementation steps, challenges, pre-mortem
* Decisions made
    - Command: `freeze-archives` with `--dry-run` / `--save`
    - Behavior-preserving markup extract before freeze units
* Insights
    - `archive_url_for` is already ungated by `archive_enabled?` (tags gate separately) — freeze can call it directly

## 2026-08-01 - PREFLIGHT - COMPLETE

* Work completed
    - Validated plan against codebase, creative docs, TDD encoding, gemspec packing
    - Amended implementation steps with explicit test-before-code ordering
    - Wrote `.preflight-status` PASS
* Decisions made
    - Deferred optional `--path`/`--limit` as advisory follow-up
* Insights
    - No existing freeze/command code to conflict with

## 2026-08-01 - PLAN AMENDMENT - COMPLETE

* Work completed
    - Locked multiline ArchiveInserter contract: new line before closer, indent copied from last content line (I4/I5)
* Decisions made
    - Single-line remains end-of-markup splice; multiline must not cram onto URL line or against `%}`
* Insights
    - Author review cost for large freezes depends on indent-faithful diffs, not just “surgical” byte inserts

## 2026-08-01 - BUILD - IN-PROGRESS

* Work completed
    - Prerequisites verified (preflight PASS); creative decisions reviewed
* Decisions made
    - Proceeding with Option B architecture and Option B CLI/env policy as planned
* Insights
    - Step 1 is refactor-under-green via existing tag specs before any freeze units

## 2026-08-01 - BUILD - COMPLETE

* Work completed
    - Shared markup extract; MarkupAnalyzer; TagLocator; ArchiveInserter; FreezeArchives command; README/CHANGELOG; full verify
    - 479 examples, 0 failures; RuboCop clean on touched files
* Decisions made
    - Runner restores `_SAVE` env after `--save`; dry-run increments frozen without writing
* Insights
    - Applying inserts reverse-sorted by range.begin keeps multi-edit files correct without re-locating

## 2026-08-01 - QA - COMPLETE

* Work completed
    - Semantic review against plan + creative docs
    - Fixed page source-path resolution; added regression test; re-verified (480 examples, 0 failures)
    - Wrote `.qa-validation-status` PASS
* Decisions made
    - Treat relative `Page#path` as a QA bugfix (plan already required scanning pages)
* Insights
    - Posts (`Document#path` absolute) masked the page-path bug in C1–C6 fixtures

## 2026-08-01 - REFLECT - COMPLETE

* Work completed
    - Wrote reflection for freeze-archives-jekyll-subcommand
    - Updated systemPatterns + productContext for command / freeze use case
* Decisions made
    - Standalone L3 task → next operator step is `/niko-archive`
* Insights
    - Integration fixtures should cover page + collection doc when both are in scope

## 2026-08-01 - POST-REFLECT POLISH - SAVED

* Work completed
    - Hand-run progress logging at info; ignore site quiet for freeze-archives
    - Relative-path log format; SLOBAC-friendly semantic log assertions
* Decisions made
    - Presentation of log separators is not a unit-test contract
* Insights
    - Already-frozen tags skip silently (no CDX); kill/re-run is safe for written files

## 2026-08-01 - REWORK - INITIATED

* Work completed
    - Operator chose rework (not archive) after REFLECT COMPLETE
    - Scope creep from manual QA: configurable URL skip-list for archive attempts
* Decisions made
    - Config: `highlight_cards.noarchive` — list of regex strings under highlight cards
    - On match: skip archive attempt only; do not write `archive:none` (so changing regex later can reattempt)
    - Tags that already have an archive attribute are left alone
    - Gate lives with existing `archiveable_url?` filters (same place as archive.org / non-http(s) skips)
    - Affects both build-time auto-lookup and `jekyll freeze-archives`
* Insights
    - This is eligibility, not freeze-write policy; shared ArchiveHelper is the choke point

## 2026-08-01 - COMPLEXITY-ANALYSIS - COMPLETE (rework)

* Work completed
    - Classified noarchive config rework as Level 2
* Decisions made
    - L2: enhancement localized to ArchiveHelper eligibility gate + site config plumbing; no new subsystem
* Insights
    - `archiveable_url?` today has no site/config — plan must thread site (or patterns) into the existing gate

## 2026-08-01 - PLAN - COMPLETE (rework)

* Work completed
    - L2 plan: ArchiveHelper site-aware noarchive gate + tag/freeze wiring + README
* Decisions made
    - Optional `site:` on `archiveable_url?` / `archive_url_for`; match full URL string; RegexpError propagates
* Insights
    - Analyzer and `archive_url_for` both must see site so CDX never runs for matches

## 2026-08-01 - PREFLIGHT - COMPLETE (rework)

* Work completed
    - Preflight PASS for noarchive L2 plan
    - Amended plan steps 1–3 with explicit test-before-code ordering
* Decisions made
    - Keep optional `site:` threading approach
* Insights
    - Four lib call sites must all receive site for the feature to work end-to-end

## 2026-08-01 - BUILD - COMPLETE (rework)

* Work completed
    - Implemented highlight_cards.noarchive via archiveable_url?(site:)
    - Wired tags + freeze analyzer/command; README; 491 specs green
* Decisions made
    - Memoize compiled regexps in ArchiveHelper.noarchive_regexp_cache keyed by site+raw list
* Insights
    - Skip-only semantics keep freeze from writing archive:none so config changes can reattempt

## 2026-08-01 - QA - COMPLETE (rework)

* Work completed
    - Semantic QA PASS for noarchive config rework
* Decisions made
    - No code changes required in QA
* Insights
    - archiveable check before cache prevents noarchive from serving stale cached hits for skipped URLs

## 2026-08-01 - REFLECT - COMPLETE (rework)

* Work completed
    - Wrote reflection-noarchive-config.md
    - Persistent MB left unchanged (no factual invalidation)
* Decisions made
    - Standalone L2 rework → next operator step is `/niko-archive`
* Insights
    - Eligibility must precede archive_cache so noarchive cannot be bypassed by a prior hit
