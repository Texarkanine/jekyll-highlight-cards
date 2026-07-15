---
task_id: simplecov-1-skip-migration
complexity_level: 2
date: 2026-07-15
status: completed
---

# TASK ARCHIVE: simplecov-1-skip-migration

## SUMMARY

Bumped development dependencies `simplecov` to `~> 1.0` (resolved 1.0.1) and `simplecov-cobertura` to `~> 4.0` (resolved 4.0.0), migrated `SimpleCov.add_filter` → `SimpleCov.skip` in `spec/spec_helper.rb` in the same change set, and added RSpec contract coverage. Opened PR [#48](https://github.com/Texarkanine/jekyll-highlight-cards/pull/48) (Fixes [#47](https://github.com/Texarkanine/jekyll-highlight-cards/issues/47)) and closed Dependabot [#46](https://github.com/Texarkanine/jekyll-highlight-cards/pull/46) as superseded.

## REQUIREMENTS

- Bump `simplecov` ~> 1.0 and `simplecov-cobertura` ~> 4.0 in the gemspec and lockfile
- Replace `add_filter` with `skip` for `/spec/` and `/vendor/` exclusions in `spec/spec_helper.rb`
- Ship both in one PR that Fixes #47 and supersedes Dependabot #46
- Feature branch from up-to-date `main`; TDD + Level 2 Niko workflow

## IMPLEMENTATION

Level 2 TDD sequence: stub/implement `spec/jekyll_highlight_cards/simplecov_config_spec.rb` (gem versions, `skip` DSL source assertions, active filters) → update `jekyll-highlight-cards.gemspec` + `Gemfile.lock` via `bundle update` → migrate `spec/spec_helper.rb` → full suite + RuboCop.

Key files:

- `jekyll-highlight-cards.gemspec` — constraint bumps
- `Gemfile.lock` — simplecov 1.0.1 / simplecov-cobertura 4.0.0
- `spec/spec_helper.rb` — `skip "/spec/"`, `skip "/vendor/"`
- `spec/jekyll_highlight_cards/simplecov_config_spec.rb` — new contract specs
- Persistent memory bank initialized; `systemPatterns.md` notes SimpleCov 1.x `skip` API

## TESTING

- TDD red→green on new SimpleCov config specs
- Full suite: 194 examples, 0 failures under new gems
- RuboCop clean (DescribeClass / MatchWithSimpleRegex fixes on the new spec)
- `/niko-preflight` PASS; `/niko-qa` PASS (no substantive findings)
- PR feedback judge on #48: LlamaPReview “internal API” claim on `filters`/`filter_argument` dismissed (documented public surface in SimpleCov 1.0.1)

## LESSONS LEARNED

- `simplecov-cobertura` 4.0 already requires `simplecov (~> 1.0)`, so a deps-only bump of one without the other (or without the DSL migration) is incomplete
- For a coverage-tooling major, the right unit of work is constraint bump + DSL rename + a small contract spec in one change set
- Plan sequence held; only minor surprise was a wrong relative path (`../../` vs `../`) in the first helper-source assertion draft

## PROCESS IMPROVEMENTS

Nothing notable beyond keeping Dependabot majors that rename public DSLs as human PRs when a one-line migration would otherwise be left as a follow-up.

## TECHNICAL IMPROVEMENTS

Nothing notable — no production architecture changes; coverage config remains solely in `spec/spec_helper.rb`.

## NEXT STEPS

- Merge PR #48 when CI/review are satisfied
- None otherwise
