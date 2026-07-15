# Progress

Bump SimpleCov / simplecov-cobertura majors and migrate `add_filter` → `skip` in `spec/spec_helper.rb` per [#47](https://github.com/Texarkanine/jekyll-highlight-cards/issues/47), superseding Dependabot PR #46.

**Complexity:** Level 2

## 2026-07-15 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Restated operator intent from issue #47 + hard requirements (approved via explicit operator mandate on this `/niko` run)
    - Initialized persistent memory bank; relocated ephemeral tracking to `memory-bank/active/`
    - Determined Level 2: self-contained enhancement across gemspec/lockfile + spec helper coverage config
* Decisions made
    - Level 2 (not L1): enhancement/update path, not a production bug fix; still single-concern and low risk
* Insights
    - SimpleCov 1.0 documents `add_filter` → `skip` as identical matcher grammar ([SimpleCov README migration table](https://github.com/simplecov-ruby/simplecov))

## 2026-07-15 - PLAN - COMPLETE

* Work completed
    - Wrote Level 2 implementation plan with TDD behaviors B1–B4 and edge case
    - Identified new test file `spec/jekyll_highlight_cards/simplecov_config_spec.rb`
    - Sequenced: failing specs → gemspec/lockfile → skip migration → full suite
* Decisions made
    - Keep `/spec/` and `/vendor/` matcher strings unless clearer forms prove necessary
    - Treat major bumps as tech validation via `bundle update` during Build (no separate PoC)
* Insights
    - Dependabot #46 only bumps constraints; human PR must include DSL migration to avoid deprecation warnings
