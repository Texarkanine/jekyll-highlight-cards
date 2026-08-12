# Tasks

## archive-save-only-on-cdx-miss (#59)

### What broke
With `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE=1`, `ArchiveHelper#archive_url_for` always called SavePageNow after CDX lookup — even when a snapshot already existed — turning every production build into a full re-archive pass.

### Why
`submit_archive(url) || archive_url if archive_save_enabled?` ran unconditionally when SAVE was on. Docs and specs encoded that contract.

### What changed
- Submit only when `lookup_archive` returns nil and SAVE is enabled.
- Specs assert CDX hit → no SavePageNow; CDX miss → SavePageNow; miss+fail → nil.
- README env-var row updated to match.

### Files
- `lib/jekyll-highlight-cards/archive_helper.rb`
- `spec/jekyll_highlight_cards/archive_helper_spec.rb`
- `README.md`
