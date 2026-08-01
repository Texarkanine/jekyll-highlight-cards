# Active Context

**Current Task:** Skip non-archivable URLs in ArchiveHelper (#53)
**Phase:** BUILD - COMPLETE
**Complexity:** Level 2

## Files Modified

- `/home/mobaxterm/git/jekyll-highlight-cards/lib/jekyll-highlight-cards/archive_helper.rb` — `archiveable_url?` + gate in `archive_url_for`
- `/home/mobaxterm/git/jekyll-highlight-cards/lib/jekyll-highlight-cards/polaroid_tag.rb` — `resolve_archive(..., explicit_link:)` skips auto-lookup when `!explicit_link`
- `/home/mobaxterm/git/jekyll-highlight-cards/spec/jekyll_highlight_cards/archive_helper_spec.rb` — Guard A/B examples
- `/home/mobaxterm/git/jekyll-highlight-cards/spec/jekyll_highlight_cards/polaroid_tag_spec.rb` — Guard C examples

## Key Decisions

- `URI::HTTP` (includes HTTPS) + host present; reject `archive.org` / `web.archive.org` (downcase)
- Guard C only on auto-lookup path; explicit `archive=` without `link=` still works

## Deviations

- Added invalid-URI case (`http://[`) for rescue-branch coverage — still within Guard A

## Next Step

QA phase
