# Project Brief

## User Story

As a site visitor, I want unlabeled polaroid cards to omit empty title/link elements so that cards without labels take up less vertical space below the image.

## Use-Case(s)

### Use-Case 1
Polaroid card has a title but no link; only the title-related element renders.

### Use-Case 2
Polaroid card has a link but no title; only the link-related element renders.

### Use-Case 3
Polaroid card has neither title nor link; neither title/link element renders and spacing below the image is reduced.

### Use-Case 4
Archive metadata may be present or absent independently; archive DOM should render only when archive data exists.

## Requirements

1. Do not render title DOM when a title is not provided.
2. Do not render link DOM when a link is not provided.
3. Support all combinations of title/link presence and archive presence.
4. Do not render archive DOM when archive data is not available.
5. Reduce extra blank space under images when optional metadata is missing.
6. Provide additional breathing room for archive when archive is the only metadata line, without adding extra spacing when title/link are present.

## Constraints

1. Title, link, and archive DOM elements should each render only when their data is present.
2. Archive behavior should still work for explicit and auto-resolved archive URLs.
3. Existing behavior for labeled cards must remain intact.

## Acceptance Criteria

1. A card with no title does not include the title element in the rendered DOM.
2. A card with no link does not include the link element in the rendered DOM.
3. A card with neither title nor link has less vertical space below the image than before.
4. A card with no archive URL does not include the archive element in the rendered DOM.
5. A card with archive URL includes the archive element and archive link.
6. A card in archive-only state applies additional spacing so archive text is not cramped directly under the image.
7. A card with title/link plus archive does not gain additional archive-only spacing below the preceding text line.
