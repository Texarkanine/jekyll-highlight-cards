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
