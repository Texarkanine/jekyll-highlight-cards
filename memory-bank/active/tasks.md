# Task: restore-100-line-coverage

* Task ID: restore-100-line-coverage
* Complexity: Level 2
* Type: simple enhancement (test coverage)

Restore SimpleCov line coverage from 99.48% (576/579) to 100% by adding SLOBAC-compliant behavioral specs for three freeze-archives edges left uncovered by the 2.2.0 release. No production behavior change expected.

## Test Plan (TDD)

### Behaviors to Verify

- B1 (CLI action wiring): register `freeze-archives` via `.init_with_program`, then invoke the Mercenary command's `execute` with a temp site + options → same observable freeze outcome as `process` (source rewritten / summary counts); covers `c.action` → `process(options)` at `commands/freeze_archives.rb:30`
- B2 (ENV restore): with `JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE` pre-set to a non-nil sentinel, run `process(..., "save" => true)` → after return, ENV equals the sentinel again; covers `restore_save_env` else-branch at `commands/freeze_archives.rb:71` (C5 already covers the nil/delete branch)
- B3 (unsupported tag): call public `ArchiveInserter#insert` with a span whose `:tag` is neither `linkcard` nor `polaroid` → raises `ArgumentError` mentioning unsupported tag; covers `archive_token` else at `archive_inserter.rb:67`
- Edge: B2 must not leak ENV across examples (ensure/after cleanup); B3 must go through `#insert`, not `send(:archive_token)`
- Regression: existing freeze-archives / inserter examples remain green; full suite stays at 100% lines

### Test Infrastructure

- Framework: RSpec (`bundle exec rspec`), SimpleCov in `spec/spec_helper.rb`
- Test location: `spec/jekyll_highlight_cards/freeze_archives/`
- Conventions: outcome oracles (file contents, summary hashes, ENV, raised errors); WebMock for IA; temp sites via helpers in `command_spec.rb`; semantic log asserts only (no presentation pins)
- New test files: none — extend `command_spec.rb` and `archive_inserter_spec.rb`

### SLOBAC Guardrails for These Specs

- Prefer outcome asserts over "was `process` called" spies for B1
- Do not pin Mercenary option text, syntax strings, or log punctuation
- Do not cover lines by SimpleCov `skip` / filters
- Do not weaken Mutant config to chase line coverage
- Avoid private-method unit tests when the public path can exercise the branch (B3)

## Implementation Plan

1. **B2 — ENV restore after `--save` (RED → GREEN)**
   - Files: `spec/jekyll_highlight_cards/freeze_archives/command_spec.rb`
   - Changes: add example beside C5 that sets `ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"]` to a sentinel, calls `described_class.process(site_options(dir).merge("save" => true))` (reuse existing CDX stubs / temp site), asserts ENV restored to sentinel; ensure cleanup deletes or restores ENV if the example fails mid-flight

2. **B3 — unsupported tag via `#insert` (RED → GREEN)**
   - Files: `spec/jekyll_highlight_cards/freeze_archives/archive_inserter_spec.rb`
   - Changes: add example under `#insert` with fabricated content + span (`tag: "notacard"`, valid `:range`); `expect { inserter.insert(...) }.to raise_error(ArgumentError, /unsupported tag/i)`

3. **B1 — Mercenary action → process (RED → GREEN)**
   - Files: `spec/jekyll_highlight_cards/freeze_archives/command_spec.rb`
   - Changes: extend `.init_with_program` context — after register, `program.commands[:"freeze-archives"].execute([], site_options(dir))` (or equivalent) against a temp site with CDX stub; assert freeze outcome via **file side effects** (archive token in post). `execute` discards `process`'s return value (`c.action` does not return the summary), so do not use the summary hash as oracle. Do not stub `process` solely to prove the call.

4. **Verify coverage gate**
   - Files: none (verification)
   - Changes: `bundle exec rspec` — 0 failures; SimpleCov `576+n / same` → **100%** line coverage; RuboCop clean on touched specs

5. **Docs**
   - Files: none expected
   - Changes: no README/user-doc updates (test-only restoration of an existing quality bar)

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing RSpec / WebMock / Mercenary (already used by `command_spec.rb`)
- Uncovered lines remain present on current `back-to-full-cov` tree (post-2.2.0 freeze-archives)

## Challenges & Mitigations

- **Mercenary `execute` option shape**: Jekyll/Mercenary may expect string keys and merged defaults (`quiet`, `source`). Mitigation: reuse `site_options(dir)` already proven with `process`; if `execute` alone is insufficient, invoke registered `actions` with the same hash — still through the registered action block, not a direct `process` call.
- **B3 span fabrication vs locator**: TagLocator will never emit unknown tags. Mitigation: fabricate span for the public `#insert` contract (documented as accepting locator spans); assert on error class/message content that names the failure mode, not on private method identity.
- **SLOBAC temptation to spy `process`**: Mitigation: plan explicitly forbids call-count spies as the sole oracle for B1; outcome oracle required.
- **ENV leakage across examples**: Mitigation: wrap B2 in `ensure` / RSpec `around` that clears the variable; mirror C5's post-condition hygiene.

## Pre-Mortem

- **Coverage "fixed" with a smell (spy-only / `send` private / filter skip)**: Plan names SLOBAC guardrails and public-path oracles; preflight/QA must reject spy-only B1 or SimpleCov skip cheats.
- **B1 still misses line 30 because tests call `process` directly**: Implementation step 3 requires going through `execute`/registered actions; coverage report is the gate, not "example exists".
- **B2 false green if sentinel equals what `--save` sets (`"1"`)**: Use a distinct sentinel (e.g. `"preexisting"`) so restore is distinguishable from leave-as-save-value.
- **Task secretly needs production refactor for testability**: Unlikely — all three branches are reachable today; if Mercenary wiring proves untouchable without invasive hooks, STOP and re-level/discuss rather than add production seams for coverage alone.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight
- [ ] Build
- [ ] QA

## Preflight Findings

- PASS: TDD ordering is per-step (test additions before any production change); no change-detector docs tests scheduled
- PASS: Extends existing freeze-archives specs; conventions match `systemPatterns.md`
- PASS: Completeness — B1/B2/B3 map to the three uncovered lines and brief ACs
- ADVISORY (incorporated): Mercenary `execute` discards `process` return value — B1 oracle must be file side effects
