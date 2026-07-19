# Task: mutation-testing-slobac-rework

* Task ID: mutation-testing-slobac-rework
* Complexity: Level 2
* Type: PR-feedback test-quality remediation (SLOBAC)

Remediate all 34 findings in `.slobac/2026-07-19T16-26-13/audit.md` for branch-changed specs under `spec/jekyll_highlight_cards`, preserving `bundle exec rspec` green and `bundle exec mutant run` at 100% coverage. Prefer prescribed remediations; prefer delete when a stronger sibling already locks the same contract.

## Finding Disposition Map

| # | File / example | Smell | Disposition |
|---|----------------|-------|-------------|
| 1 | polaroid `raises an error` (template not found) | loose-text-oracle | Strengthen: `raise_error(JekyllHighlightCards::TemplateNotFoundError, /Template not found/)` |
| 2 | polaroid `shows archive anchor when resolve_archive…` | naming-lies | Rename to explicit-archive URL appears in markup |
| 3 | polaroid `handles empty title gracefully` | vacuous-assertion | Delete — duplicate of stronger `renders nbsp in title area when title is empty` (~755) |
| 4 | polaroid `handles empty link gracefully` | vacuous-assertion | Strengthen: assert `polaroid-link` nbsp under `link=""` (no stronger sibling for empty string link) |
| 5 | polaroid `requires the first token…` | naming-lies | Rename to image-only markup sets img src |
| 6 | polaroid `archives the link URL not the image URL` | naming-lies | Strengthen: assert full archive URL embeds link host and excludes `/photo.jpg` (mirror ~678) |
| 7 | polaroid `uses archive_enabled…` | naming-lies | Rename to ENV/auto-lookup without explicit archive param |
| 8–13 | polaroid `#build_template_variables` raw-key examples | naming-lies | Rename to public HTML outcomes (alt/archive/size/target-blank); keep dump example at ~837 for raw locals |
| 14 | `image_sizing_hooks_spec.rb` whole file | monolithic-test-file | Split by capability (see Implementation Plan step 6) |
| 15 | image sizing frozen pre-render | naming-lies | Strengthen: `.freeze` content / lines and assert marker still applied |
| 16 | image sizing whitespace-before-`=` | naming-lies | Strengthen: assert no-whitespace `img.jpg=300x200` left unchanged; keep happy path separate or in same example |
| 17 | image sizing frozen post-render | naming-lies | Strengthen: freeze `output` string and assert dimensions |
| 18–19 | width/height space + insert-after-img | presentation-coupled | Delete — siblings already assert width/height independently; order/position pins add no mutant value |
| 20–21 | linkcard `uses the site from Liquid context registers` | vacuous + naming-lies | Delete — `renders a user-provided site template override` already proves site-from-registers wiring |
| 22 | linkcard template-not-found | loose-text-oracle | Strengthen: typed `TemplateNotFoundError` |
| 23–24 | linkcard nested-brace titles | naming-lies | Rename to Liquid evaluation / consecutive expressions (no nested fixture available without inventing unsupported syntax) |
| 25 | linkcard `returns nil when no title…` | naming-lies | Rename to omits title heading; consider collapsing with existing `does not render a title when none is provided` if identical |
| 26 | template_renderer File.join spy | over-specified-mock | **Retained** — `File.join("", "_includes")` → `/_includes` (not creatable in tests); only mutation-kill for `!source.empty?` |
| 27 | template_renderer TemplateRenderError message | presentation-coupled | Typed error + fragment matchers (template name, path, `Errno::ENOENT`) — not full Errno string equality |
| 28–31 | archive_helper Net::HTTP spies | over-specified-mock | **Retained** — WebMock outcomes identical under host/port/ssl/timeout mutations; spies are the only kill surface (commented in-spec) |
| 32 | expression_evaluator Liquid::Template.parse spy | over-specified-mock | Delete; keep `returns the string as-is` |
| 33 | expression_evaluator debug log exact string | presentation-coupled | `a_string_including` token + error class; keep fallback outcome sibling |
| 34 | linkcard + archive_helper CDX cache | semantic-redundancy | Delete `linkcard_tag_spec` `caches archive lookup results`; keep `archive_helper_spec` canonical |

## Test Plan (TDD)

This rework edits the suite itself. “Behaviors” are post-remediation suite contracts; the regression gate is RSpec + Mutant (not new product tests).

### Behaviors to Verify

- Typed template-missing failures: tag render with missing template → `TemplateNotFoundError` matching `/Template not found/` (polaroid + linkcard).
- Empty polaroid title/link: `title=""` → `polaroid-title` nbsp (via existing example); `link=""` → `polaroid-link` nbsp.
- Archive target identity: auto-archive HTML contains link host and not image path.
- Freeze-safe image sizing: frozen markdown content still gets IMG_SIZE markers; frozen HTML output still gets width/height.
- Whitespace gate: sized image without space/tab before `=` is left unchanged.
- TemplateRenderer empty source: still returns gem template path without File.join interaction spy.
- TemplateRenderError diagnostics: typed error; message includes template name, path, and `Errno::ENOENT` without pinning full OS wording.
- ExpressionEvaluator syntax failure: still returns literal token; debug log includes token substring + error class (not full interpolated equality).
- ArchiveHelper: CDX/save outcomes still covered via WebMock; no Net::HTTP.start / Get.new timeout/path spies.
- Image sizing suite: same example count power after split; shared `mock_document` in support.
- No semantic-duplicate CDX `.once` cache check in linkcard after delete.

### Edge Cases

- Mutant coverage regression after deletes — re-run `bundle exec mutant run`; if kills drop, restore kill power via strengthen (not re-adding spies).
- Freeze examples must freeze the actual string the SUT reads (`content` / `output`), not a discarded local.
- Empty `link=""` may differ from omitted link — assert the empty-string path explicitly.
- File split must not break `require "spec_helper"` / `let` sharing; extract support carefully.

### Test Infrastructure

- Framework: RSpec (`.rspec`, `spec/spec_helper.rb`)
- Test location: `spec/jekyll_highlight_cards/`
- Conventions: frozen-string-literal; `RSpec.describe` per unit; WebMock for HTTP; tag specs define local `render_tag`; Mutant discipline in `CONTRIBUTING.md` (no SUT stubs)
- New test files: split from `image_sizing_hooks_spec.rb` (names below); shared helper under `spec/support/`
- No new product test files beyond the split; no Nokogiri dependency (attribute-order examples deleted instead)

## Implementation Plan

All steps are **test-suite remediations** (no `lib/` changes planned). For each unit: edit/add/delete the example(s) first → run the affected example(s) → only if a product bug is discovered (unexpected), stop and escalate — do not “fix” smells by changing production code.

1. **Typed template-not-found oracles (findings 1, 22)**
   - TDD: change the two `raise_error` examples → run those examples → expect green (typed oracle only; no lib change)
   - Files: `spec/jekyll_highlight_cards/polaroid_tag_spec.rb`, `linkcard_tag_spec.rb`
   - Changes: `raise_error(JekyllHighlightCards::TemplateNotFoundError, /Template not found/)`

2. **Polaroid naming-lies + vacuous empty fields (findings 2–13)**
   - TDD: apply renames/deletes/strengthens in the examples → run `polaroid_tag_spec.rb` → green before next unit
   - Files: `polaroid_tag_spec.rb`
   - Changes: renames per disposition map; delete empty-title vacuous duplicate; strengthen empty-link and archive link-vs-image; rename raw-key examples to HTML outcomes

3. **Linkcard vacuous / naming / redundancy (findings 20–21, 23–25, 34)**
   - TDD: edit/delete examples → run `linkcard_tag_spec.rb` → green
   - Files: `linkcard_tag_spec.rb`
   - Changes: delete site-registers vacuous example; rename nested-brace examples; rename `#resolve_title` nil example (dedupe if identical to sibling); delete `caches archive lookup results`

4. **TemplateRenderer + ExpressionEvaluator smell cleanup (findings 26–27, 32–33)**
   - TDD: edit/delete examples → run both specs → green
   - Files: `template_renderer_spec.rb`, `expression_evaluator_spec.rb`
   - Changes: delete File.join / Liquid::Template.parse interaction examples; loosen TemplateRenderError + debug-log presentation pins

5. **ArchiveHelper over-specified Net::HTTP spies (findings 28–31)**
   - TDD: delete four spy-only examples → run `archive_helper_spec.rb` → green (WebMock outcome siblings must still pass)
   - Files: `archive_helper_spec.rb`
   - Changes: delete lookup HTTPS/timeouts, CDX Get.new, save Get.new, submit HTTPS/timeouts examples

6. **Image sizing smell fixes then monolithic split (findings 14–19)**
   - TDD (smell fixes first, while still one file): strengthen freeze + whitespace examples; delete presentation-coupled examples → run file → green
   - TDD (split): extract support → `git mv` monolith to first split file → peel remaining describes into new files → run each new file after creation → delete empty leftover if any
   - Files: `image_sizing_hooks_spec.rb` →
     - `spec/support/image_sizing_document.rb` — shared `mock_document` helper / shared context
     - `image_sizing_pre_render_spec.rb` — `.process_pre_render`
     - `image_sizing_post_render_spec.rb` — `.process_post_render`
     - `image_sizing_helpers_spec.rb` — helper-method describes
     - `image_sizing_integration_spec.rb` — integration describe
     - `image_sizing_hooks_registration_spec.rb` — Jekyll hook registration describe
   - Prefer `git mv` for history; example count preserved minus deleted 18–19
   - Load shared helper via `require_relative "../support/image_sizing_document"` in each split file (`.rspec` does not auto-require `spec/support/**`; do not add a blanket support glob — `mutant_setup.rb` must stay Mutant-only)

7. **Regression gates**
   - TDD/regression: full `bundle exec rspec` → `bundle exec mutant run` (must stay 100%; if not, strengthen outcome examples only — no spy revival) → `bundle exec rubocop` on touched specs/support
   - Mutant config (`config/mutant.yml`) currently lists support as `mutant_setup.rb` only — no per-spec subject paths to update after split

8. **Memory bank close-out during build/QA**
   - Update `tasks.md` checklist statuses; no CONTRIBUTING/doc changes expected

### Preflight Amendments

- Explicit per-step TDD ordering for test-only remediations (edit example → run → no lib/ unless product bug).
- Confirmed `link=""` ⇒ `explicit_link == false` ⇒ `polaroid-link` nbsp (strengthen oracle is valid).
- Shared support must use `require_relative`, not a `spec/support` Dir glob.
- Prefer `git mv` when splitting the monolith.

## Technology Validation

No new technology - validation not required. (Nokogiri not added; presentation pins removed instead.)

## Dependencies

- Existing: RSpec, WebMock, Mutant, RuboCop
- Audit artifact (read-only): `.slobac/2026-07-19T16-26-13/audit.md`
- Sibling contracts in the same specs (nbsp title, archive URL embedding, template override, WebMock CDX)

## Challenges & Mitigations

- **Mutant coverage drop after deleting spy/presentation examples**: Mitigation — run mutant after each batch of deletes; if a subject goes under 100%, strengthen an outcome sibling for that subject rather than restoring the smell.
- **Freeze examples that still don’t freeze the SUT input**: Mitigation — freeze the string returned from `content` / `output` doubles (`and_return(str.freeze)` or freeze before stub).
- **Split breaks shared lets / ordering assumptions**: Mitigation — extract support first; move one describe group per file; run that file before next move.
- **Empty `link=""` behavior differs from omitted link**: Mitigation — inspect render once under `link=""` before writing oracle; match actual product contract (nbsp vs empty div).
- **Duplicate `#resolve_title` / “does not render a title” examples**: Mitigation — delete one after rename if bodies are identical.

## Pre-Mortem

- **Plan failed because deletes gutted unique mutant kills and we “fixed” smells by weakening the suite**: Response — Step 7 mutant gate is mandatory and blocking; disposition prefers strengthen over delete when sibling coverage is unclear (only delete when a stronger sibling is named in the map).
- **Plan failed because the file split was treated as mechanical cut-paste and left broken requires / duplicate top-level describes**: Response — Step 6 sequences support extract → move groups → delete monolith; verify per file.
- **Plan failed because we chased “raw template key” strengthen via private `send` for Mutant**: Response — disposition explicitly renames to public HTML outcomes; dump example already covers raw locals — do not add `send`/`__send__`.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight
- [x] Build
- [ ] QA

## Build Notes

- Implemented steps 1–7; `bundle exec rspec` 443/0 @ 100% line coverage; `bundle exec mutant run` 2988/0 (100%); RuboCop clean on touched files.
- Deviations: retained findings 26 & 28–31 (mutant-required spies); restored File.join empty-source check after cwd trap proved impossible (`File.join("", "_includes")` → `/_includes`); ExpressionEvaluator poison-stub outcome test (no `have_received(:parse)`); image-sizing freeze via `String.new(...).freeze` for RuboCop; split used script delete rather than `git mv`.
- Image sizing: 5 capability specs + `spec/support/image_sizing_document.rb`; monolith removed.
