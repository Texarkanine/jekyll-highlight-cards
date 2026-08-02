# Project Brief

## User Story

As a maintainer, I want line coverage restored to 100% after the freeze-archives release so that the suite again fully exercises shipped plugin code, without introducing SLOBAC test smells.

## Use-Case(s)

### Cover freeze-archives CLI action wiring

Exercising Mercenary `c.action` so `process(options)` is reached through the command registration path.

### Cover ENV restore after `--save`

When `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE` was already set before a `--save` run, restore that prior value in the ensure path.

### Cover unsupported tag in archive token insertion

`ArchiveInserter#archive_token` raises `ArgumentError` for an unsupported tag name.

## Requirements

1. SimpleCov line coverage returns to 100% (`bundle exec rspec`).
2. New/updated tests assert observable behaviors, not incidental structure.
3. Follow SLOBAC principles ([llms-full](https://texarkanine.github.io/slobac/llms-full.txt)) — no change-detectors, tautologies, over-mocking, presentation pinning, or other named smells.
4. Prefer extending existing freeze-archives specs over parallel infrastructure.

## Constraints

1. Do not weaken Mutant kill discipline or ignore mutants to chase line coverage.
2. Do not exclude uncovered lines via SimpleCov `skip` to fake 100%.
3. Production code changes only if required for honest testability; prefer behavioral coverage of existing public paths.

## Acceptance Criteria

1. `bundle exec rspec` passes with SimpleCov reporting 100% line coverage.
2. Each of the three previously uncovered lines is exercised by a meaningful behavioral test.
3. New tests would fail if the corresponding behavior were removed or inverted (not mere presence/formatting asserts).
