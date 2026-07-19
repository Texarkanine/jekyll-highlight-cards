---
task_id: mutation-testing-slobac-rework
date: 2026-07-19
complexity_level: 2
---

# Reflection: mutation-testing-slobac-rework

## Summary

Post-reflect rework remediated SLOBAC smells in the mutation-coverage specs (renames, strengthens, deletes, image-sizing split) while holding `bundle exec rspec` green at 100% line coverage and `bundle exec mutant run` at 100% kill.

## Requirements vs Outcome

Delivered: 29 of 34 findings fully remediable under the mutant gate; 5 (File.join empty-source + four Net::HTTP spies) retained with in-spec rationale because WebMock/filesystem outcomes cannot distinguish those mutants. Brief allowed explained coverage tradeoffs; we chose retain-kills over smell purity for those five.

## Plan Accuracy

Disposition map and step order held. Surprise: empty-source cwd trap cannot work (`File.join("", "_includes")` → `/_includes`). Mutant drop after spy deletes was expected in the pre-mortem and forced the retain decision. Split used a scripted peel rather than `git mv` — functionally fine, weaker history.

## Build & QA Observations

Renames and vacuous deletes were fast. Most calendar time was the mutant recovery loop (poison-stub Liquid, single-img spaced attrs, then spy restore). QA was clean — no substantive gaps.

## Insights

### Technical
- Under WebMock, `Net::HTTP.start` kwargs (host/port/ssl/timeouts) and `Net::HTTP::Get` path construction are not observable via response stubs; collaborator spies remain the only mutant-kill surface for that wiring.
- `File.join("", "_includes")` produces an absolute `/_includes` path on this Ruby — empty-source skip cannot be proven with a relative trap file.

### Process
- For SLOBAC remediations on a 100%-mutant suite, treat “delete over-specified mock” as provisional until `mutant run` confirms; budget a restore-or-strengthen pass before calling build done.

### Million-Dollar Question

If smell discipline and mutation coverage were joint first-class constraints from the start, ArchiveHelper HTTP options would be a small named builder (or injected client) with outcome-level tests, instead of Net::HTTP spies that SLOBAC correctly flags. That would need a deliberate lib seam — out of scope for this test-only rework, but the right long-term shape.
