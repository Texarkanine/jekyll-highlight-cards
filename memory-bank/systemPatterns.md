# System Patterns

## How This System Works

This gem hooks into Jekyll's build at three points, and the bulk of the non-obvious behavior lives in *when* each runs:

1. **Liquid tags** (`{% linkcard %}`, `{% polaroid %}`) are registered as `Liquid::Tag` subclasses (`lib/jekyll-highlight-cards/linkcard_tag.rb`, `polaroid_tag.rb`) and run during page rendering.
2. **Markdown image sizing** is *not* a tag - it is a pair of `Jekyll::Hooks` (`:documents`, `:pre_render`/`:post_render`) registered at the bottom of `image_sizing_hooks.rb`. The pre-render pass rewrites `![alt](src =WxH)` into `![alt](src)<!-- IMG_SIZE:W:H -->`; the post-render pass finds the rendered `<img>` next to that marker comment and injects `width`/`height` plus optional auto-linking. This two-pass marker dance is load-bearing: dimensions must survive the Markdown→HTML conversion, and a comment marker is how state is carried across it.
3. **SCSS load path injection** happens in a `:site`, `:after_init` hook in `lib/jekyll-highlight-cards.rb`, which appends the gem's `_sass` dir to `site.config["sass"]["load_paths"]`. It guards against double-insertion (watch mode re-inits). This is why consumers can `@use "highlight-cards"` without configuring paths themselves.

The four shared modules (`ExpressionEvaluator`, `DimensionParser`, `ArchiveHelper`, `TemplateRenderer`) are **mixins** included into the tag classes, not standalone services. Their public methods become instance methods on the tags. When modifying a shared module, check every tag that includes it.

## Logging

All logging routes through `ExpressionEvaluator`'s `log_*` helpers, which call `Jekyll.logger.{debug,info,warn,error}` with a `"HighlightCards:"` topic prefix. Don't use `puts`/`warn` directly - use these so output is consistent and respects Jekyll's log level.

## Archive Integration Is Fail-Soft and Cached

`ArchiveHelper` wraps all network I/O (`Net::HTTP` to `web.archive.org` CDX + SavePageNow) in `rescue StandardError => ... nil`. A failed or slow archive lookup must never break a build - it degrades to "no archive link." Results are memoized in a module-level `@archive_cache` hash shared across all tag instances for the lifetime of the build, so each distinct URL is looked up at most once. Archiving is entirely opt-in via `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE` / `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE` env vars.

## Template Override With Path-Traversal Guard

`TemplateRenderer#find_template_path` resolves templates user-first: it checks the consuming site's `_includes/highlight-cards/<name>.html` before falling back to the gem's bundled `_includes/`. Two safety layers apply: `validate_template_name!` rejects any name outside `[A-Za-z0-9_-]+`, and `safe_template_path` re-expands paths and confirms the result stays within the allowed directory. Both must be preserved when touching template resolution.

## SCSS Split: Structure / Colors / Default

Styles are deliberately split into three files in `_sass/`:
- `_highlight-cards-structure.scss` - layout/positioning/sizing only, borders declared without color.
- `_highlight-cards-colors.scss` - colors, borders, shadows, print styles.
- `_highlight-cards.scss` - the default entry point that imports both for a complete out-of-box look.

This lets consumers `@use "highlight-cards-structure"` and supply their own colors without fighting specificity. (See `memory-bank/archive/enhancements/20251220-css-override-investigation.md` for the origin of this split.)

## Output Is HTML-Escaped by Contract

Templates receive both raw and `escaped_*` versions of every text field; rendered markup uses the escaped variants (and `CGI.escapeHTML` in the image hook). Treat all tag input as untrusted - escape on the way into HTML.
