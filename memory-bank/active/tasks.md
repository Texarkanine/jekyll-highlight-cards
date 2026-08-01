# Task: Configurable noarchive URL skip list

* Task ID: freeze-archives-jekyll-subcommand (rework: noarchive-config)
* Complexity: Level 2
* Type: simple enhancement

Add `highlight_cards.noarchive` (array of regex strings in `_config.yml`) so URLs matching any pattern are treated as not archiveable — same gate as `ArchiveHelper#archiveable_url?` (http(s)+host, skip archive.org hosts). Skip lookup only; never write `archive:none`. Explicit archive attributes remain untouched. Applies to build-time tag lookup and `jekyll freeze-archives`.

## Test Plan (TDD)

### Behaviors to Verify

- Match skip: URL matching a configured pattern → `archiveable_url?` / `archive_url_for` returns false/nil with no HTTP
- Non-match: URL not matching any pattern → eligibility unchanged (still subject to existing guards)
- Empty/missing config: `highlight_cards` absent or `noarchive: []` → no extra skips
- Multiple patterns: any one match is enough to skip
- Full-URL match: pattern is applied to the full URL string (e.g. `x\.com` / `https://x\.com/` as author chooses)
- Invalid regex: compiling a bad pattern raises loudly (does not silently ignore)
- Explicit archive untouched: tag/source with existing `archive=` / `archive:none` is not rewritten by freeze; resolve path still honors explicit archive even if URL would match noarchive
- Freeze path: freeze-archives with noarchive config does not CDX-lookup matching candidates (analyzer rejects or lookup short-circuits)
- Build path: tag auto-lookup with site config does not CDX for matching URLs
- Regression: existing archive.org / relative / invalid-URI guards still reject

### Test Infrastructure

- Framework: RSpec (`bundle exec rspec`)
- Test location: `spec/jekyll_highlight_cards/`
- Conventions: describe/context/it; WebMock for HTTP; helper object that `include`s `ArchiveHelper`
- New test files: none required (extend existing)
- Primary file: `spec/jekyll_highlight_cards/archive_helper_spec.rb`
- Also extend: `spec/jekyll_highlight_cards/freeze_archives/markup_analyzer_spec.rb`, `spec/jekyll_highlight_cards/freeze_archives/command_spec.rb`
- Optional thin coverage: one example in `linkcard_tag_spec` / `polaroid_tag_spec` if site-config wiring is not fully exercised by helper + freeze specs

## Implementation Plan

1. **Gate + config read (ArchiveHelper)**
   - Files: `lib/jekyll-highlight-cards/archive_helper.rb`, `spec/jekyll_highlight_cards/archive_helper_spec.rb`
   - Changes: Thread optional `site:` into `archiveable_url?` / `archive_url_for`. After existing URI/host guards, if any compiled `highlight_cards.noarchive` pattern matches the full URL string, return false/nil. Compile via `Regexp.new`; let `RegexpError` propagate. Missing/empty list → no-op.
2. **Wire tags (build-time path)**
   - Files: `lib/jekyll-highlight-cards/linkcard_tag.rb`, `polaroid_tag.rb` (+ specs only if needed)
   - Changes: Pass `site:` from `context.registers[:site]` into `archive_url_for` on the auto-lookup path (explicit archive / `none` unchanged).
3. **Wire freeze-archives**
   - Files: `lib/jekyll-highlight-cards/freeze_archives/markup_analyzer.rb`, `commands/freeze_archives.rb`, related specs
   - Changes: Construct analyzer with site (or pass site into `analyze` / `archiveable_url?`); call `archive_url_for(target, site: site)` so CDX never runs for noarchive matches. Matching URLs count as skipped candidates (no miss lookup).
4. **Docs**
   - Files: `README.md` (Internet Archive section)
   - Changes: Document `highlight_cards.noarchive` with a short YAML example (e.g. skip `x\.com`); note skip-only semantics (no `archive:none` write).

## Technology Validation

No new technology - validation not required (stdlib `Regexp` + existing Jekyll `site.config`).

## Dependencies

- Existing `ArchiveHelper#archiveable_url?` as shared eligibility choke point
- Jekyll `site.config` for `highlight_cards.noarchive`
- Freeze `MarkupAnalyzer` + tags already call into ArchiveHelper

## Challenges & Mitigations

- **No site on current gate API**: Optional `site:` kwarg on `archiveable_url?` / `archive_url_for`; default `nil` preserves current behavior for callers/tests that omit it.
- **Invalid regex authorship**: Fail loud on `RegexpError` at first compile/use so bad `_config.yml` is obvious; do not swallow.
- **Double gate (analyzer + archive_url_for)**: Prefer checking in `archiveable_url?` so both paths stay consistent; analyzer continues to call that method with site available.
- **Pattern semantics (host vs full URL)**: Document full-URL match; authors write patterns accordingly (`x\.com`, `\Ahttps://x\.com/`, etc.).

## Pre-Mortem

- **Patterns never applied because site not threaded on one call path**: Plan steps 2–3 explicitly wire tags and freeze; preflight should verify every `archive_url_for` / `archiveable_url?` call site.
- **Someone "helps" by writing `archive:none` on skip**: Acceptance forbids it; tests assert freeze leaves source without archive attr for matches.
- **Config key typo / wrong nesting undocumented**: README example locks the `highlight_cards.noarchive` shape.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [ ] Preflight
- [ ] Build
- [ ] QA
