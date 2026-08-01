# Active Context

**Current Task:** Configurable noarchive URL skip list
**Phase:** BUILD - COMPLETE
**Complexity:** Level 2

## What Was Done

- `ArchiveHelper#archiveable_url?` / `archive_url_for` take optional `site:`; `highlight_cards.noarchive` regexes match full URL; `RegexpError` propagates; patterns memoized per site
- Tags + freeze `MarkupAnalyzer` / Runner pass site into the gate
- Specs: helper (6), linkcard wiring, analyzer A9, command C4b; README documented
- Full suite: 491 examples, 0 failures; RuboCop clean on touched files

## Files Modified

- `lib/jekyll-highlight-cards/archive_helper.rb`
- `lib/jekyll-highlight-cards/linkcard_tag.rb`
- `lib/jekyll-highlight-cards/polaroid_tag.rb`
- `lib/jekyll-highlight-cards/freeze_archives/markup_analyzer.rb`
- `lib/jekyll-highlight-cards/commands/freeze_archives.rb`
- `spec/jekyll_highlight_cards/archive_helper_spec.rb`
- `spec/jekyll_highlight_cards/linkcard_tag_spec.rb`
- `spec/jekyll_highlight_cards/polaroid_tag_spec.rb`
- `spec/jekyll_highlight_cards/freeze_archives/markup_analyzer_spec.rb`
- `spec/jekyll_highlight_cards/freeze_archives/command_spec.rb`
- `README.md`

## Next Step

QA review
