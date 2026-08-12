# Progress

Fix `ARCHIVE_SAVE` so SavePageNow is only invoked on CDX miss (ensure archive exists), not on every build when a snapshot already exists. Docs + tests updated; ship as breaking change for release-please.

**Complexity:** Level 1

## 2026-08-11 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Intent restated from #59 + operator clarification; approved
    - Classified Level 1 (bug fix, single component: ArchiveHelper)
* Decisions made
    - Breaking change via conventional commit bang / BREAKING CHANGE footer (intentional behavior change)
* Insights
    - Current code and specs explicitly encode “always submit when SAVE=1”; docs match that incorrect contract

## 2026-08-11 - BUILD - COMPLETE

* Work completed
    - Failing specs for CDX-hit / no-SavePageNow; fixed `archive_url_for`; README updated
    - Full suite green (505 / 100% coverage)
* Decisions made
    - Shape: `submit_archive(url) if archive_url.nil? && archive_save_enabled?` (no `|| archive_url` fallback needed on the miss path)
* Insights
    - Old “falls back to CDX when SAVE fails” specs assumed hit+always-submit; replaced with hit-skips-save assertions

## 2026-08-11 - QA - COMPLETE (PASS)

* Work completed
    - Semantically reviewed the committed implementation, behavior specs, documentation, and release metadata against issue #59.
    - Re-ran the full suite: 505 examples, 0 failures, 100% line coverage.
* Decisions made
    - Accepted the CDX-hit guard as the minimal implementation of the new SAVE contract.
* Insights
    - `lookup_archive` normalizes lookup failures to `nil`, so the guard intentionally submits on lookup failure when SAVE is enabled, matching the project brief.
