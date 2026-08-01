# Task: Skip non-archivable URLs in ArchiveHelper (#53)

* Task ID: archive-non-archivable-url-guards-53
* Complexity: Level 2
* Type: bug fix

Stop auto-archive (CDX / SavePageNow) for relative paths, archive.org / web.archive.org hosts, and polaroid self-links (no `link=`), as specified in https://github.com/Texarkanine/jekyll-highlight-cards/issues/53.

## Test Plan (TDD)

### Behaviors to Verify

- **A1 absolute https**: `archive_url_for("https://example.com/page")` → unchanged (CDX / optional SavePageNow still run)
- **A2 bare filename**: `archive_url_for("photo.jpg")` → `nil`, no HTTP
- **A3 relative path**: `archive_url_for("./img/x.png")` → `nil`, no HTTP
- **A4 site-root path**: `archive_url_for("/assets/x.png")` → `nil`, no HTTP
- **A5 non-http scheme**: `archive_url_for("ftp://example.com/a")` → `nil`, no HTTP
- **B1 Wayback host**: `archive_url_for("https://web.archive.org/web/2003/.../http://example.com/")` → `nil`, no HTTP
- **B2 archive.org host**: `archive_url_for("https://archive.org/details/foo")` → `nil`, no HTTP
- **C1 polaroid no link**: polaroid with only image path, archive enabled → no archive badge / no CDX request (even though `link_url` defaults to `image_url`)
- **C2 polaroid with link**: existing behavior — still archives the link URL when `link=` present (regression)

### Edge Cases

- Empty / nil-like URL string → skip (`nil`)
- Host match is exact on parsed URI host (`archive.org`, `web.archive.org`), case-insensitive via downcase
- Explicit `archive="https://..."` on a polaroid without `link=` still uses the explicit archive URL (Guard C only blocks the auto-lookup path)
- Content-side `archive="none"` unchanged

### Test Infrastructure

- Framework: RSpec + WebMock (`bundle exec rspec`)
- Test location: `spec/jekyll_highlight_cards/`
- Conventions: describe/context/it; WebMock stubs for archive.org; helper object includes `ArchiveHelper`; polaroid via `render_tag`
- New test files: none — extend `archive_helper_spec.rb` and `polaroid_tag_spec.rb`

## Implementation Plan

1. **Failing tests for Guards A/B** in `spec/jekyll_highlight_cards/archive_helper_spec.rb`
   - Files: `spec/jekyll_highlight_cards/archive_helper_spec.rb`
   - Changes: under `#archive_url_for`, add examples for relative paths, non-http schemes, and archive.org / web.archive.org hosts asserting `nil` and zero WebMock requests; keep existing happy-path examples green as regression anchors

2. **Failing tests for Guard C** in `spec/jekyll_highlight_cards/polaroid_tag_spec.rb`
   - Files: `spec/jekyll_highlight_cards/polaroid_tag_spec.rb`
   - Changes: in `#resolve_archive` / automatic archive lookup context, add example: no `link=`, archive env enabled, stubbed CDX — expect no `web.archive.org` in output and no CDX request; leave "archives the link URL not the image URL" as C2 regression

3. **Implement `archiveable_url?` + gate `archive_url_for`**
   - Files: `lib/jekyll-highlight-cards/archive_helper.rb`
   - Changes: add documented predicate (absolute `http`/`https` with host; reject `archive.org` / `web.archive.org`); call at top of `archive_url_for` and return `nil` before CDX/cache work when false

4. **Implement polaroid self-link skip**
   - Files: `lib/jekyll-highlight-cards/polaroid_tag.rb`
   - Changes: pass `explicit_link` into `resolve_archive` (or equivalent); on auto-lookup path (`source` empty), return `nil` when `!explicit_link` without calling `archive_url_for`; preserve `archive="none"` and explicit archive URL behavior

5. **Verify suite**
   - Files: n/a
   - Changes: `bundle exec rspec` (full suite); fix any fallout

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing: `URI`, WebMock, RSpec, `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE` / `_SAVE` env flags
- Issue #53 as behavioral source of truth

## Challenges & Mitigations

- **Cache interaction**: `archive_cache[url] ||= ...` does not stick `nil`; early-return before the cache block avoids pointless retries for bad URLs on every tag — mitigate by gating before `||=`
- **Guard C vs explicit archive**: short-circuiting all of `resolve_archive` when `!explicit_link` would drop explicit `archive=` — mitigate by only skipping the auto-lookup branch
- **Host variants** (`www.archive.org`, `archive.is`): issue scopes exact `archive.org` / `web.archive.org` only — do not expand unless cheap follow-up

## Pre-Mortem

- **Plan treated Guard C as "never archive without link" including explicit archive URLs**: tighten step 4 to auto-path only (already in Challenges)
- **Tests only assert return value, still allow SavePageNow under `_SAVE=1` for bad URLs**: assert no WebMock requests (or disable net connect) in A/B examples
- **Wrong layer — only PolaroidTag fixed, LinkCard still archives relative/Wayback URLs**: centralize A/B in `ArchiveHelper` (issue design); LinkCard inherits automatically

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [ ] Preflight
- [ ] Build
- [ ] QA
