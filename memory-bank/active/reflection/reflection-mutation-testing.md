---
task_id: mutation-testing
date: 2026-07-19
complexity_level: 3
---

# Reflection: mutation-testing

## Summary

Wired Mutant + `mutant-rspec` into jekyll-highlight-cards (auto-thumbnails pattern), reached 100% mutation coverage (2988 kills), and opened draft PR #49 on `feat/mutation-testing`.

## Requirements vs Outcome

All Level 3 requirements delivered: RSpec integration (`~> 0.16`), config/docs/discipline mirror, 100% kill under hard constraints, draft PR, CI Mutant out of scope. No requirements dropped. Line coverage remains above the project >95% guidance (~98.7%).

## Plan Accuracy

Plan sequence (scaffold → ENV isolation → inventory → kill loop → PR) held. The dominant surprise matched auto-thumbnails lessons: describe-prefix selection and equivalent/unobservable branches, not tooling install. TemplateRenderer was the last subject; SUT stubs in its old specs had to be removed before Mutant could make progress.

## Creative Phase Review

None — open questions were resolved in planning (keep RSpec; Mutant 0.16 CLI). That was the right call.

## Build & QA Observations

- PoC `mutant test` failed until archive ENV was isolated per example (parallel forks).
- Parallel subject-scoped kill agents worked well for ArchiveHelper / ImageSizingHooks / LinkcardTag / PolaroidTag once constraints were explicit.
- QA was clean after RuboCop remediation; no substantive semantic gaps vs the brief.

## Cross-Phase Analysis

Preflight TDD-encoding amendment on the kill loop paid off. Skipping creative was correct. Calendar time concentrated in the kill loop (as premortem predicted), not scaffold.

## Insights

### Technical
- Prefer `def self.` over `module_function` when Mutant covers the API — instance subjects from `module_function` are unkillable if production only calls the singleton.
- Stubbing public methods on the SUT (e.g. `find_template_path`) hides rescue/path subjects; use real tempdirs and collaborator stubs instead.
- `File.join("", "_includes")` becomes `"/_includes"` — empty-source guards need an oracle other than “falls back to gem” (e.g. expect `File.join` not called with `""`).

### Process
- After a green `mutant test`, inventory all survivors once, then batch by structural cause; parallel subject agents with explicit A/B constraints beat linear `--fail-fast` thrash.
- Keep optional `rake mutant` wrappers deferred until CLI fidelity to the reference gem is settled.
