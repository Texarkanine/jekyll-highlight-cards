---
task_id: archive-non-archivable-url-guards-53
date: 2026-08-01
complexity_level: 2
---

# Reflection: Skip non-archivable URLs in ArchiveHelper (#53)

## Summary

Shipped Guards A/B/C from issue #53: `ArchiveHelper` skips non-http(s) and archive.org hosts; polaroids without `link=` skip auto-archive. Suite green at 455 examples.

## Requirements vs Outcome

Delivered as specified. Added only an invalid-URI skip (still Guard A). No Wayback unwrapping. Explicit `archive=` without `link=` preserved.

## Plan Accuracy

Plan sequence and file list held. Main surprise was RuboCop preferring `it_behaves_like` over `include_examples` — mechanical, not design.

## Build & QA Observations

TDD red/green was clean. QA only moved `archiveable_url?` to `private` to match other helper internals.

## Insights

### Technical

- Polaroid self-link is a product rule (`!explicit_link`), not something `archiveable_url?` can infer once `link_url` has already defaulted to `image_url`.

### Process

- Nothing notable

### Million-Dollar Question

Eligibility as a private predicate at the single `archive_url_for` entrypoint, plus polaroid's existing `explicit_link` flag on the auto-lookup path — which is what we built.
