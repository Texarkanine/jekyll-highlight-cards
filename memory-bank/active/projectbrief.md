# Project Brief

## User Story

As a gem maintainer, I want Mutant + `mutant-rspec` wired into jekyll-highlight-cards the same way as jekyll-auto-thumbnails, so that mutation testing enforces intentional behavior at 100% kill coverage.

## Use-Case(s)

### Use-Case 1

A contributor runs `bundle exec mutant test` / `bundle exec mutant run` locally and gets the same discipline (A/B buckets, no ignore cheats, no SUT stubs) documented in CONTRIBUTING.

### Use-Case 2

CI continues to use RSpec/SimpleCov as today; Mutant CI job is out of scope. A draft PR on `feat/mutation-testing` carries the change for human review.

## Requirements

1. Add Mutant using RSpec integration (`mutant-rspec` ~> 0.16), not a minitest migration.
2. Mirror jekyll-auto-thumbnails: `config/mutant.yml`, `spec/support/mutant_setup.rb`, gemspec deps, SimpleCov skip when `defined?(Mutant)`, CONTRIBUTING Mutation Testing section, `memory-bank/techContext.md` Testing Process update.
3. Drive mutation coverage to 100% under hard constraints (no matcher ignores, no `coverage_criteria:` cheats, no `send`/`__send__` for private methods just for Mutant, no stubbing/mocking the SUT).
4. Prefer `def self.` over `module_function` if Mutant invents unused instance subjects.
5. Deliver on branch `feat/mutation-testing` as a draft PR. CI Mutant job intentionally out of scope.

## Constraints

1. Line coverage must stay at the project target (`bundle exec rspec` green with SimpleCov).
2. Work only in jekyll-highlight-cards (read-only reference to jekyll-auto-thumbnails).
3. Conventional commits with `git --no-pager` and `git commit --no-gpg-sign`.
4. Do not run `/niko-archive`; stop after REFLECT COMPLETE.

## Acceptance Criteria

1. `bundle exec rspec` green at project coverage target.
2. `bundle exec mutant run` reports 100% mutation coverage.
3. Discipline docs and config match the auto-thumbnails reference pattern.
4. Draft PR exists on `feat/mutation-testing` for operator review.

## Rework

### Trigger

Post-reflect PR feedback / review: SLOBAC audit of branch-changed specs under `spec/jekyll_highlight_cards` (`.slobac/2026-07-19T16-26-13/audit.md`).

### User Story

As a gem maintainer, I want the mutation-coverage tests added on `feat/mutation-testing` free of the SLOBAC smells identified in that audit, so that the suite asserts real contracts without brittle mocks, vacuous oracles, or misleading names.

### Requirements

1. Address all **34** findings in the audit (or document a reasoned rejection with operator agreement).
2. Prefer the audit's prescribed remediations: rename vs strengthen for naming-lies; typed error oracles for loose-text-oracle; outcome assertions over collaborator spies for over-specified-mock; structural/parsed checks for presentation-coupled; positive empty-field contracts for vacuous-assertion; split `image_sizing_hooks_spec.rb` for monolithic-test-file; delete the redundant linkcard archive-cache example for semantic-redundancy.
3. Preserve mutation-kill power and line coverage — remediations must not trade smell cleanup for weaker oracles that leave mutants alive.
4. Keep changes in the test suite / support unless a product bug is discovered; do not weaken SUT contracts to silence findings.

### Acceptance Criteria

1. Each of the 34 audit findings is remediated or explicitly deferred with rationale.
2. `bundle exec rspec` remains green at the project coverage target.
3. `bundle exec mutant run` remains at 100% mutation coverage (or any coverage drop is explained and approved).
