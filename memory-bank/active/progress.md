# Progress

Add ArchiveHelper / PolaroidTag guards so auto-archive skips relative paths, archive.org hosts, and polaroid self-links, per issue #53.

**Complexity:** Level 2

## 2026-08-01 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Intent clarified and approved against https://github.com/Texarkanine/jekyll-highlight-cards/issues/53
    - Classified as Level 2 (bug fix across ArchiveHelper + PolaroidTag)
* Decisions made
    - Skip-only behavior; Wayback URL unwrapping remains out of scope
* Insights
    - Observed in consuming-site builds with `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE=1`
