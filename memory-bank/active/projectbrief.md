# Project Brief

## Task

Fix `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE` so SavePageNow runs only when CDX finds no snapshot — as described in https://github.com/Texarkanine/jekyll-highlight-cards/issues/59.

## Requirements

- With `ARCHIVE_SAVE=1`: CDX lookup first; on hit use the snapshot and do not call SavePageNow; on miss (or lookup failure treated as miss) call SavePageNow.
- Update README / env-var docs so they no longer say SAVE runs even when CDX already found a snapshot.
- Ship as a deliberate breaking behavior change (`fix!:` / `BREAKING CHANGE` footer) so release-please can bump major correctly.

## Out of Scope

- Extra CI progress logging (noted in #59 as separable).
- Changes to freeze-archives CLI beyond whatever falls out of shared `archive_url_for` behavior.
