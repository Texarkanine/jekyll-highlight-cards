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

## 2026-08-01 - BUILD - COMPLETE

* Work completed
    - TDD: red tests for A/B/C, then `archiveable_url?` gate + polaroid `explicit_link` skip
    - Full suite 455 examples, 0 failures; RuboCop clean; line coverage 100%
* Decisions made
    - Host deny-list exact match on downcased URI host
    - Invalid URI rescued to non-archiveable
* Insights
    - Vacuous empty `it` stubs were replaced before red run; shared examples use `it_behaves_like` for RuboCop

## 2026-08-01 - QA - COMPLETE

* Work completed
    - Semantic review vs plan: A/B/C complete; moved `archiveable_url?` to `private`
    - Wrote `.qa-validation-status` PASS
* Decisions made
    - No README change required (docs never claimed relative/Wayback URLs are archived)
* Insights
    - Public surface of ArchiveHelper stays env/cache/lookup entrypoints; eligibility is an implementation detail

## 2026-08-01 - REFLECT - COMPLETE

* Work completed
    - Wrote `reflection/reflection-archive-non-archivable-url-guards-53.md`
    - Reconciled persistent files: no updates needed
* Decisions made
    - None beyond shipping skip-only guards as planned
* Insights
    - Guard C must live at PolaroidTag because `link_url` already defaults to `image_url` before ArchiveHelper sees it
