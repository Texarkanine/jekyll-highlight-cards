# Active Context

**Current Task:** archive-save-only-on-cdx-miss (#59)
**Phase:** BUILD - COMPLETE
**Complexity:** Level 1

## What Was Done

- TDD: specs for SAVE-only-on-CDX-miss (hit skips SavePageNow; miss submits; miss+fail → nil).
- Fixed `archive_url_for` to `submit_archive` only when lookup returns nil.
- Updated README env-var wording.
- Full suite: 505 examples, 0 failures, 100% line coverage.

## Next Step

QA phase (subagent `/niko-qa`).
