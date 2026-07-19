# Active Context

## Current Task: mutation-testing-slobac-rework
**Phase:** BUILD - COMPLETE

## What Was Done
- Remediated SLOBAC findings across polaroid/linkcard/template_renderer/expression_evaluator/archive_helper/image_sizing specs
- Split `image_sizing_hooks_spec.rb` into 5 capability files + shared support context
- Gates: rspec 443/0 (100% lines), mutant 2988 kills / 0 alive, RuboCop clean
- Deviations: retained Net::HTTP + empty-source File.join spies (mutant-only kill surfaces; documented in-spec)

## Files Modified
- `spec/jekyll_highlight_cards/polaroid_tag_spec.rb`
- `spec/jekyll_highlight_cards/linkcard_tag_spec.rb`
- `spec/jekyll_highlight_cards/template_renderer_spec.rb`
- `spec/jekyll_highlight_cards/expression_evaluator_spec.rb`
- `spec/jekyll_highlight_cards/archive_helper_spec.rb`
- `spec/jekyll_highlight_cards/image_sizing_{pre_render,post_render,helpers,integration,hooks_registration}_spec.rb` (new)
- `spec/support/image_sizing_document.rb` (new)
- Deleted: `spec/jekyll_highlight_cards/image_sizing_hooks_spec.rb`

## Next Step
- QA phase (autonomous for Level 2)
