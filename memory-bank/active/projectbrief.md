# Project Brief

## User Story

As a maintainer of jekyll-highlight-cards, I want to bump SimpleCov to 1.x (and simplecov-cobertura to 4.x) and migrate `add_filter` → `skip` in the same change set so the suite runs without SimpleCov 1.0 deprecation warnings and Dependabot PR #46 can be closed as superseded.

## Use-Case(s)

### Use-Case 1

Developer runs `bundle exec rspec` after the bump; coverage still excludes `spec/` and `vendor/`, and no `add_filter` deprecation warnings appear.

### Use-Case 2

Open human PR for #47 that obviates Dependabot PR #46 (deps-only bump without the DSL migration).

## Requirements

1. Bump `simplecov` to `~> 1.0` and `simplecov-cobertura` to `~> 4.0` in `jekyll-highlight-cards.gemspec`, and update `Gemfile.lock` accordingly.
2. In `spec/spec_helper.rb`, replace `add_filter` with `skip` for the `spec/` and `vendor/` exclusions (same matcher semantics).
3. Ship both changes in one PR that Fixes #47 and notes that #46 is superseded/can be closed.
4. Work on a feature branch cut from up-to-date `main`; open the PR with `gh` when Niko phases for the assigned level are complete.

## Constraints

1. Follow Niko workflow and TDD for the assigned complexity level.
2. Use `git --no-pager` and `git commit --no-gpg-sign`; conventional commits referencing `#47`.
3. Do not force-push; do not amend unless amend rules are met.

## Acceptance Criteria

1. Gemspec and lockfile resolve `simplecov` ~> 1.0 and `simplecov-cobertura` ~> 4.0.
2. `spec/spec_helper.rb` uses `skip` (not `add_filter`) for the prior filters.
3. Full RSpec suite passes under the new gems.
4. PR opened with body stating Fixes #47 and that Dependabot PR #46 is superseded/can be closed.
