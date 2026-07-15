---
task_id: simplecov-1-skip-migration
complexity_level: 2
date: 2026-07-15
status: completed
---

# TASK ARCHIVE: simplecov-1-skip-migration

## SUMMARY

Bumped development dependencies `simplecov` to `~> 1.0` (resolved 1.0.1) and `simplecov-cobertura` to `~> 4.0` (resolved 4.0.0), and migrated `SimpleCov.add_filter` → `SimpleCov.skip` in `spec/spec_helper.rb` in the same change set. Opened PR [#48](https://github.com/Texarkanine/jekyll-highlight-cards/pull/48) (Fixes [#47](https://github.com/Texarkanine/jekyll-highlight-cards/issues/47)) and closed Dependabot [#46](https://github.com/Texarkanine/jekyll-highlight-cards/pull/46) as superseded.

An RSpec file that unit-tested SimpleCov’s own configuration was added during the build and later removed: testing the unit-test harness config that way was a mistake, not a pattern to keep or recommend.

## REQUIREMENTS

- Bump `simplecov` ~> 1.0 and `simplecov-cobertura` ~> 4.0 in the gemspec and lockfile
- Replace `add_filter` with `skip` for `/spec/` and `/vendor/` exclusions in `spec/spec_helper.rb`
- Ship both in one PR that Fixes #47 and supersedes Dependabot #46
- Feature branch from up-to-date `main`; Level 2 Niko workflow

## IMPLEMENTATION

Updated `jekyll-highlight-cards.gemspec` + `Gemfile.lock` via `bundle update`, then migrated `spec/spec_helper.rb` (`add_filter` → `skip` for `/spec/` and `/vendor/`). Verified with the existing product suite and RuboCop.

Key files (final):

- `jekyll-highlight-cards.gemspec` — constraint bumps
- `Gemfile.lock` — simplecov 1.0.1 / simplecov-cobertura 4.0.0
- `spec/spec_helper.rb` — `skip "/spec/"`, `skip "/vendor/"`
- Persistent memory bank initialized; `systemPatterns.md` notes SimpleCov 1.x `skip` API

Removed after operator feedback: `spec/jekyll_highlight_cards/simplecov_config_spec.rb` (config-introspection / contract specs against SimpleCov itself).

## TESTING

- Full existing RSpec suite under the new gems (initially 194 with the mistaken config specs; after removal, the product suite only)
- RuboCop clean on the remaining change set
- `/niko-preflight` PASS; `/niko-qa` PASS
- Do not treat “specs that assert on SimpleCov filters / gemspec versions / helper source text” as appropriate verification for this kind of change — the product suite passing after the bump + DSL rename is sufficient

## LESSONS LEARNED

- `simplecov-cobertura` 4.0 already requires `simplecov (~> 1.0)`, so a deps-only bump of one without the other (or without the DSL migration) is incomplete
- For a coverage-tooling major, the right unit of work is constraint bump + DSL rename in one change set; unit-testing the unit-test configuration is not
- A config-introspection / source-grep “contract” suite around SimpleCov was a bad idea and was ripped out

## PROCESS IMPROVEMENTS

Nothing notable beyond keeping Dependabot majors that rename public DSLs as human PRs when a one-line migration would otherwise be left as a follow-up.

## TECHNICAL IMPROVEMENTS

Nothing notable — no production architecture changes; coverage config remains solely in `spec/spec_helper.rb`.

## NEXT STEPS

- Merge PR #48 when CI/review are satisfied
- None otherwise
