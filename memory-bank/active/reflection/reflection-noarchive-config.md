---
task_id: freeze-archives-jekyll-subcommand (rework: noarchive-config)
date: 2026-08-01
complexity_level: 2
---

# Reflection: Configurable noarchive URL skip list

## Summary

Added `highlight_cards.noarchive` regex list that skips archive attempts via the existing `archiveable_url?` gate for both build-time tags and `jekyll freeze-archives`. Delivered as planned; QA clean.

## Requirements vs Outcome

All rework requirements met: skip-only (no `archive:none` write), explicit archives untouched, full-URL match, invalid regex raises, docs in README. No scope additions beyond the memoized regexp cache noted in preflight advisory.

## Plan Accuracy

Plan sequence and file list held. Main design call (optional `site:` on the gate) was right; freeze Runner creates the analyzer after site is known. No reordering needed.

## Build & QA Observations

TDD cycles were straightforward. Only mechanical friction was RuboCop ExampleLength on the command integration example. QA found no substantive issues.

## Insights

### Technical

- Eligibility checks must run *before* the per-URL archive cache so a later noarchive match cannot be bypassed by a prior hit for the same URL string.
- `noarchive` patterns are intentionally **unanchored** (`Regexp.new` + `match?` on the full URL). Authors opt into anchors (`\A` / `\z`) when they need them. Tradeoff: bare `x\.com` also matches substring hosts like `notx.com` — tighten the pattern if that matters.

### Process

- Post-reflect operator Q&A clarified anchoring semantics; folded into this reflection so archive docs carry the contract.

### Million-Dollar Question

If noarchive had been assumed from day one, site would already be a required (or ambient) argument on ArchiveHelper rather than an optional kwarg threaded through tags and freeze. What we shipped is the minimal compatible form of that: one gate, optional site, same call-site shape as the archive.org/local filters. Unanchored-by-default matching is the right authoring default for that gate; anchoring stays in the pattern, not in the helper.
