---
task_id: mutation-testing
complexity_level: 3
date: 2026-07-19
status: completed
---

# TASK ARCHIVE: mutation-testing

## SUMMARY

Wired Mutant + `mutant-rspec` into jekyll-highlight-cards (mirroring jekyll-auto-thumbnails), reached 100% mutation coverage (2988 kills / 0 alive), documented kill discipline in CONTRIBUTING, updated `memory-bank/techContext.md`, and opened draft PR #49 on `feat/mutation-testing`. Parent authorized skip of archive after first reflect; this archive was written when the follow-on SLOBAC rework archived the shared ephemeral bank.

## REQUIREMENTS

- Add Mutant via RSpec integration (`mutant-rspec` ~> 0.16)
- Mirror auto-thumbnails: `config/mutant.yml`, `spec/support/mutant_setup.rb`, gemspec deps, SimpleCov skip under Mutant, CONTRIBUTING Mutation Testing section, techContext update
- Drive mutation coverage to 100% under hard constraints (no matcher ignores, no `coverage_criteria:` cheats, no `send`/`__send__` for private methods just for Mutant, no SUT stubs)
- Prefer `def self.` over `module_function` when Mutant invents unused instance subjects
- Draft PR on `feat/mutation-testing`; CI Mutant job out of scope
- Keep line coverage at project target

## IMPLEMENTATION

Scaffold + ENV isolation for Mutant parallel workers (archive specs mutate `ENV`; isolate per example). Kill loop across DimensionParser, ExpressionEvaluator, ArchiveHelper, ImageSizingHooks, LinkcardTag, PolaroidTag, TemplateRenderer. Public observability helpers where needed (`ImageSizingHooks` helpers, `TemplateRenderer#safe_template_path`).

Key files:

- `config/mutant.yml`, `spec/support/mutant_setup.rb`, `jekyll-highlight-cards.gemspec`
- `spec/spec_helper.rb` — SimpleCov skip when `defined?(Mutant)`
- `CONTRIBUTING.md` — Mutation Testing section
- `memory-bank/techContext.md` / `systemPatterns.md` — Mutant notes
- Spec strengthens across `spec/jekyll_highlight_cards/`

## TESTING

- `bundle exec rspec` — 444 examples, 0 failures (~98.7% line coverage at first reflect)
- `bundle exec mutant run` — 2988 kills / 0 alive (100%)
- `bundle exec rubocop` — clean
- `/niko-preflight` PASS; `/niko-qa` PASS; draft PR #49 verified

## LESSONS LEARNED

- Prefer `def self.` over `module_function` when Mutant covers the API — instance subjects from `module_function` are unkillable if production only calls the singleton
- Stubbing public methods on the SUT hides rescue/path subjects; use real tempdirs and collaborator stubs instead
- `File.join("", "_includes")` → `"/_includes"` — empty-source guards need an oracle other than “falls back to gem”
- After a green `mutant test`, inventory survivors once, then batch by structural cause; parallel subject agents with explicit A/B constraints beat linear `--fail-fast` thrash

## PROCESS IMPROVEMENTS

- Preflight TDD-encoding amendment on the kill loop paid off
- Keep optional `rake mutant` wrappers deferred until CLI fidelity to the reference gem is settled
- Skipping creative was correct when the approach is a direct mirror of a sibling gem

## TECHNICAL IMPROVEMENTS

None beyond Mutant wiring itself; CI Mutant job remains intentionally out of scope.

## NEXT STEPS

- Follow-on SLOBAC rework archived separately as `20260719-mutation-testing-slobac-rework.md`
- Merge PR #49 when review is satisfied
