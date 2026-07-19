---
task_id: mutation-testing-slobac-rework
complexity_level: 2
date: 2026-07-19
status: completed
---

# TASK ARCHIVE: mutation-testing-slobac-rework

## SUMMARY

Post-reflect Level 2 rework on `feat/mutation-testing` remediated SLOBAC smells in mutation-coverage specs (renames, strengthens, deletes, image-sizing split), then addressed CodeRabbit PR #49 feedback: stop committing `.mutant/results` (local-only; no machine paths), fix `img_link_prefix` character offsets, single-escape auto-link hrefs, and nil-safe linkcard `:site` register. Held `bundle exec rspec` green at 100% line coverage and `bundle exec mutant run` at 100% kill (final: 445 examples / 2996 kills).

## REQUIREMENTS

- Address all 34 findings in `.slobac/2026-07-19T16-26-13/audit.md` (or document reasoned retention)
- Prefer audit remediations while preserving mutant-kill power and line coverage
- Keep changes in the test suite unless a product bug is discovered
- Post-rework CodeRabbit items: remove committed Mutant result JSON; fix byteslice/char-offset; fix double-escaped auto-link hrefs; align linkcard site lookup with polaroid

## IMPLEMENTATION

Disposition map drove rename / strengthen / delete across polaroid, linkcard, template_renderer, expression_evaluator, archive_helper, and image sizing. Split `image_sizing_hooks_spec.rb` into five capability specs + `spec/support/image_sizing_document.rb`. Retained findings 26 and 28–31 (File.join empty-source + Net::HTTP spies) with in-spec rationale — WebMock/filesystem cannot distinguish those mutants.

PR #49 follow-ups:

- Removed tracked `.mutant/results/*.json`; kept `/.mutant/` ignored (matches auto-thumbnails; never commit local Mutant output)
- `img_link_prefix` → character slice; multibyte prefix example
- Auto-link href: `CGI.escapeHTML(CGI.unescapeHTML(src))` + single-escape oracle
- `LinkcardTag#render`: `registers[:site]`; absent-site fallback example

Deferred (not done): `safe_template_path` directory-boundary hardening; ArchiveHelper `http_get` extract.

## TESTING

- SLOBAC build: `bundle exec rspec` 443/0 @ 100% lines; `bundle exec mutant run` 2988/0; RuboCop clean
- After CodeRabbit fixes: `bundle exec rspec` 445/0 @ 100%; `bundle exec mutant run` 2996/0; RuboCop clean on touched files
- `/niko-preflight` PASS; `/niko-qa` PASS (rework); PR review triage + doc clarification

## LESSONS LEARNED

- Under WebMock, `Net::HTTP.start` kwargs and `Net::HTTP::Get` path construction are not observable via response stubs; collaborator spies remain the only mutant-kill surface for that wiring
- `File.join("", "_includes")` → `/_includes` — empty-source skip cannot be proven with a relative cwd trap
- For SLOBAC remediations on a 100%-mutant suite, treat “delete over-specified mock” as provisional until `mutant run` confirms
- Committing Mutant session JSON fights `/.mutant/` ignore and leaks machine paths; local-only is the reference pattern

## PROCESS IMPROVEMENTS

- Budget a restore-or-strengthen pass after spy deletes before calling build done
- Prefer outcome oracles and strengthen over delete when sibling coverage is unclear

## TECHNICAL IMPROVEMENTS

If smell discipline and mutation coverage are joint first-class constraints, ArchiveHelper HTTP options should be a small named builder (or injected client) with outcome-level tests instead of Net::HTTP spies.

## NEXT STEPS

- Merge PR #49 when review/CI are satisfied
- Optional follow-ups: `safe_template_path` separator-boundary check; extract ArchiveHelper `http_get` as part of a deliberate HTTP seam
