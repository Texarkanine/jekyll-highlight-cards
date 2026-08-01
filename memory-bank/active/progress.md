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

## 2026-08-01 - PLAN - COMPLETE

* Work completed
    - Mapped behaviors A/B/C to existing RSpec files
    - Planned `archiveable_url?` gate in `ArchiveHelper#archive_url_for` and polaroid auto-lookup skip for `!explicit_link`
* Decisions made
    - Guard C applies only to auto-lookup; explicit `archive=` without `link=` still honored
    - Host skip is exact `archive.org` / `web.archive.org` (case-insensitive), not other archive hosts
* Insights
    - LinkCard inherits A/B automatically via shared helper — no separate LinkCard change required

## 2026-08-01 - PREFLIGHT - COMPLETE

* Work completed
    - Validated plan against ArchiveHelper / PolaroidTag / LinkCard and RSpec layout
    - Wrote `.preflight-status` PASS
* Decisions made
    - No plan amendments required
* Insights
    - LinkCard already includes ArchiveHelper, so Guards A/B cover both tags without a LinkCard edit
