---
task_id: archive-non-archivable-url-guards-53
complexity_level: 2
date: 2026-08-01
status: completed
---

# TASK ARCHIVE: Skip non-archivable URLs in ArchiveHelper (#53)

## SUMMARY

Auto-archive no longer CDX-lookups or SavePageNow-submits non-archivable targets: relative/local paths, non-http(s) schemes, `archive.org` / `web.archive.org` hosts, and polaroid self-links (no `link=`). Shipped on branch `archive-guards` as draft PR #54; CodeRabbit test-isolation feedback addressed before archive.

## REQUIREMENTS

From issue #53 / project brief:

1. Guard A — absolute `http`/`https` with a host only
2. Guard B — skip `archive.org` and `web.archive.org`
3. Guard C — polaroid without `link=` skips auto-archive (self-link is not an outbound destination)
4. TDD coverage in `archive_helper_spec.rb` (A/B) and `polaroid_tag_spec.rb` (C)
5. Out of scope: consuming-site content fixes; Wayback URL unwrapping

## IMPLEMENTATION

- `ArchiveHelper#archiveable_url?` (private): `URI::HTTP` + host; deny-list downcased hosts; rescue invalid URI → false. Gated at top of `archive_url_for` before cache/CDX/SavePageNow.
- `PolaroidTag#resolve_archive`: takes `explicit_link:`; on auto-lookup path returns nil when `!explicit_link`. Explicit `archive=` and `archive="none"` unchanged.
- LinkCard inherits A/B via `include ArchiveHelper` with no separate edit.

## TESTING

- TDD: red examples for A/B/C, then green implementation
- Full suite: 455 examples, 0 failures; RuboCop clean; line coverage 100%
- `/niko-qa` PASS (moved `archiveable_url?` to private)
- Post-PR: enable `ARCHIVE_SAVE` on negative paths; Guard C fixture uses absolute https image URL so Guard A cannot mask a missing `explicit_link` check

## LESSONS LEARNED

- Polaroid self-link must be enforced in `PolaroidTag`: by the time `ArchiveHelper` sees the URL, `link_url` has already defaulted to `image_url`.
- Negative-path tests that claim “no SavePageNow” must enable `ARCHIVE_SAVE`, or the `/save/` assertion is vacuous.
- A relative image path makes a “no link=” archive test pass via Guard A alone — use an absolute URL to isolate Guard C.

## PROCESS IMPROVEMENTS

Nothing notable beyond existing Level 2 / TDD flow.

## TECHNICAL IMPROVEMENTS

Optional later: deny other archive hosts (`archive.is`, etc.) if cheap; Wayback unwrapping remains a product decision.

## NEXT STEPS

- Merge PR #54 when ready
- Consuming-site content fixes (e.g. love-letter `archiv=` typo) stay outside this gem
