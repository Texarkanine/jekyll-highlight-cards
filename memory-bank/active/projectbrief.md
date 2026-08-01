# Project Brief

## User Story

As a Jekyll site author using highlight cards with Internet Archive integration, I want an opt-in Jekyll subcommand that finds archive-eligible `linkcard` / `polaroid` tags without an archive URL in source, looks up the archive, and writes the result into the source document so I can commit a frozen archive link once and avoid re-lookup on every build.

## Use-Case(s)

### Freeze missing archives

Author runs the subcommand against their site. Tags that can take an archive but lack `archive=` / `archive:none` get a successful lookup written into the source file. Author reviews the diff and commits.

### Leave build-time fallback alone

Tags the author never froze still use the existing env-gated build-time auto-lookup. The subcommand is not part of `jekyll build`.

## Requirements

1. Ship as a **Jekyll subcommand** (e.g. `jekyll freeze-archives` or equivalent name decided in design/plan) registered by the gem — opt-in by invocation only.
2. Scan site source for `linkcard` and `polaroid` tags that are archive-eligible but do not already encode an archive (`archive=` / `archive:none`).
3. For each candidate, look up Internet Archive (reuse `ArchiveHelper` / existing eligibility rules) and, when a result is found, **insert the archive URL into the source document**.
4. Do **not** hook into the normal Jekyll build/render lifecycle (no Generator / auto-mutating hook on `jekyll build`).
5. Preserve existing build-time auto-lookup behavior as the forgetful fallback.
6. Document how to run the command and the intended freeze-then-commit workflow.

## Constraints

1. Ruby gem for Jekyll 4.x; command must work when the gem is loaded as a site plugin.
2. Must not rewrite tags that already specify `archive=` or `archive:none`.
3. Must respect non-archivable URL guards (absolute http(s) only; skip archive.org hosts; polaroid self-links without `link=` are not archive targets).
4. Source edits are the deliverable — authors commit them; the tool does not commit.

## Acceptance Criteria

1. Invoking the subcommand on a site with eligible tags lacking archive URLs inserts archive URLs into those source files when lookup succeeds.
2. Tags with existing `archive=` / `archive:none` are left unchanged.
3. Running `jekyll build` alone does not rewrite source for this feature.
4. Failed / empty lookups do not invent archive attributes.
5. Tests cover command behavior (scan, skip, insert) and docs describe the opt-in workflow.
