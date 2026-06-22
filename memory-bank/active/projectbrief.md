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
Archive metadata may be present or absent independently; archive space behavior remains unchanged.

## Requirements

1. Do not render title DOM when a title is not provided.
2. Do not render link DOM when a link is not provided.
3. Support all combinations of title/link presence and archive presence.
4. Preserve archive layout space behavior.
5. Reduce extra blank space under images when title/link are missing.

## Constraints

1. The archive area's reserved space must remain as-is.
2. Only title and link DOM elements should be conditionally removed.
3. Existing behavior for labeled cards must remain intact.

## Acceptance Criteria

1. A card with no title does not include the title element in the rendered DOM.
2. A card with no link does not include the link element in the rendered DOM.
3. A card with neither title nor link has less vertical space below the image than before.
4. A card with archive data still preserves archive area behavior regardless of title/link presence.
