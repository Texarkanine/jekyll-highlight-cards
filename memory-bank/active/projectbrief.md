# Project Brief

## User Story

As a Jekyll site author using highlight cards with auto-archive enabled, I want non-archivable URLs (relative paths, archive.org hosts, and polaroid self-links) skipped so SavePageNow / CDX are not wasted on useless or harmful targets.

## Requirements

Implement [jekyll-highlight-cards#53](https://github.com/Texarkanine/jekyll-highlight-cards/issues/53):

1. **Guard A** — `ArchiveHelper#archive_url_for` rejects anything that is not a parseable absolute `http`/`https` URI with a host (return `nil`, no CDX / SavePageNow).
2. **Guard B** — Skip when host is `web.archive.org` or `archive.org`.
3. **Guard C** — In `PolaroidTag`, when there is no explicit `link=`, do not call `archive_url_for` (self-link-to-image is not an archive target).

Prefer an `archiveable_url?` (or similar) predicate used at the top of `archive_url_for`. RSpec coverage for A/B in `archive_helper_spec.rb` and C in `polaroid_tag_spec.rb` via TDD.

## Out of Scope

- Content fixes in consuming sites
- Unwrapping Wayback URLs to archive the original URL
