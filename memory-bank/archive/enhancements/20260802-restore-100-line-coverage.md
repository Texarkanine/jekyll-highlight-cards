---
task_id: restore-100-line-coverage
complexity_level: 2
date: 2026-08-02
status: completed
---

# TASK ARCHIVE: Restore 100% freeze-archives line coverage

## SUMMARY

Restored SimpleCov line coverage from 99.48% (576/579) to 100% (579/579) after the freeze-archives 2.2.0 release left three edges uncovered. Added three SLOBAC-aligned behavioral specs; no production code changes. Draft PR [#57](https://github.com/Texarkanine/jekyll-highlight-cards/pull/57) on `back-to-full-cov`.

## REQUIREMENTS

- Return SimpleCov line coverage to 100% via `bundle exec rspec`
- Cover: Mercenary `c.action` → `process`, ENV restore after `--save` when a prior value was set, unsupported-tag `ArgumentError` in `ArchiveInserter#archive_token`
- Assert observable behaviors (SLOBAC) — no spies-as-sole-oracle, private-method unit tests, SimpleCov skips, or Mutant weakening
- Prefer extending existing freeze-archives specs

## IMPLEMENTATION

Test-only. Extended existing specs:

- `spec/jekyll_highlight_cards/freeze_archives/command_spec.rb` — B2: sentinel ENV restore after `process(..., "save" => true)`; B1: registered Mercenary `execute` freezes source (file side-effect oracle; action discards summary return)
- `spec/jekyll_highlight_cards/freeze_archives/archive_inserter_spec.rb` — B3: public `#insert` with fabricated unsupported `tag` raises `ArgumentError`

Follow-up during PR review: ENV example cleanup captures/restores prior `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE` instead of always deleting.

## TESTING

- Full suite: 504 examples, 0 failures; SimpleCov 100% lines; RuboCop clean on touched specs
- `/niko-preflight` PASS (advisory: B1 must use file oracle — incorporated)
- `/niko-qa` PASS — outcome oracles, no `process` spy, no private `send` for B3

## LESSONS LEARNED

- Mercenary `Command#execute` covers Jekyll `c.action` wiring without stubbing `process`; assert source side effects because the action discards the return value
- The `--save` ENV ensure has two branches (delete vs restore); covering only the nil/delete path leaves a silent coverage hole after shipping `--save`
- Covering the three edges through existing public paths (`process`, `#insert`, Mercenary `execute`) is what you would do if 100% coverage had been a release gate from the start

## PROCESS IMPROVEMENTS

Nothing notable for this task.

## TECHNICAL IMPROVEMENTS

Nothing notable — no production architecture changes.

## NEXT STEPS

- Merge PR #57 when CI/review are satisfied
