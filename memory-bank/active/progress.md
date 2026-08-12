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
