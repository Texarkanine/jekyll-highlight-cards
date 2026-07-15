# Task: simplecov-1-skip-migration

* Task ID: simplecov-1-skip-migration
* Complexity: Level 2
* Type: simple enhancement (dev-dependency major bump + config migration)

Bump `simplecov` ~> 1.0 and `simplecov-cobertura` ~> 4.0, migrate `SimpleCov.add_filter` → `SimpleCov.skip` in `spec/spec_helper.rb` in the same change set, and open a PR that Fixes #47 and supersedes Dependabot PR #46.

## Test Plan (TDD)

### Behaviors to Verify

- [B1 gem versions]: After `bundle install` with updated gemspec constraints → loaded `simplecov` is >= 1.0 and `simplecov-cobertura` is >= 4.0
- [B2 skip DSL]: `spec/spec_helper.rb` configures exclusions via `skip` (not deprecated `add_filter`) for `spec/` and `vendor/` path segments
- [B3 filters active]: With the suite loaded, SimpleCov filters still exclude paths containing `spec/` and `vendor/` (behavior preserved across the rename)
- [B4 suite green]: Full `bundle exec rspec` → all existing examples pass under the new gems
- [Edge: no add_filter]: `spec/spec_helper.rb` must not contain `add_filter` (avoids deprecation warnings on every run under SimpleCov 1.0)

### Test Infrastructure

- Framework: RSpec (`bundle exec rspec`), configured in `.rspec` + `spec/spec_helper.rb`
- Test location: `spec/jekyll_highlight_cards/`
- Conventions: one `*_spec.rb` per concern under `spec/jekyll_highlight_cards/`; `# frozen_string_literal: true`; `RSpec.describe` with expect syntax; WebMock enabled globally in helper
- New test files: `spec/jekyll_highlight_cards/simplecov_config_spec.rb`

## Implementation Plan

1. Stub new coverage-config specs (empty examples) for B1–B3 / edge
   - Files: `spec/jekyll_highlight_cards/simplecov_config_spec.rb`
   - Changes: create suite + empty examples documenting intended behaviors
2. Implement failing specs for B1–B3 / edge
   - Files: `spec/jekyll_highlight_cards/simplecov_config_spec.rb`
   - Changes: assert Gem loaded versions, assert `spec_helper.rb` source uses `skip` and not `add_filter`, assert SimpleCov filters match `spec/` and `vendor/`
3. Bump gemspec constraints and refresh lockfile
   - Files: `jekyll-highlight-cards.gemspec`, `Gemfile.lock`
   - Changes: `simplecov` ~> 1.0, `simplecov-cobertura` ~> 4.0; `bundle update simplecov simplecov-cobertura`
4. Migrate SimpleCov DSL in spec helper
   - Files: `spec/spec_helper.rb`
   - Changes: `add_filter` → `skip` for `/spec/` and `/vendor/` (or clearer `spec/` / `vendor/` forms with identical substring semantics)
5. Run new specs then full suite + RuboCop; fix any fallout
   - Files: as needed
   - Changes: only if lockfile/API incompatibilities surface
6. Open PR via `gh` after QA/reflect (Fixes #47; note #46 superseded)
   - Files: n/a (git/gh)
   - Changes: push branch, create PR body per acceptance criteria

## Technology Validation

Existing dependency major bumps (not brand-new technology). Validate during Build by `bundle update simplecov simplecov-cobertura` and confirming resolved versions meet `~> 1.0` / `~> 4.0`, then running the suite. No separate PoC project required.

## Dependencies

- `simplecov` ~> 1.0 ([migration: add_filter → skip](https://github.com/simplecov-ruby/simplecov))
- `simplecov-cobertura` ~> 4.0 (must remain compatible with SimpleCov 1.x)

## Challenges & Mitigations

- [simplecov-cobertura 4.x may require SimpleCov 1.x]: Update both together as specified; if lock resolution fails, inspect coberture gemspec runtime deps and adjust only within issue scope
- [Filter string form `/spec/` vs `spec/`]: Both are substring matchers under `skip`; keep existing `/spec/` and `/vendor/` forms unless clearer forms are preferred in the issue — either is acceptable
- [Specs that inspect Gem versions depend on lockfile]: Order TDD so version assertions fail until step 3; DSL/source assertions fail until step 4

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [ ] Preflight
- [ ] Build
- [ ] QA
