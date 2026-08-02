# System Patterns

## How This System Works

This is a Jekyll plugin gem: runtime code lives under `lib/jekyll-highlight-cards/`, ships Liquid tags, a Markdown image-sizing hook, and an opt-in `jekyll freeze-archives` command (`Jekyll::Command`), and registers SCSS via a relative path from the gem entrypoint. Templates live in `_includes/` and styles in `_sass/` so consuming sites can override them with Jekyll’s usual cascade. Tag markup parsing is shared (`LinkcardMarkup` / `PolaroidMarkup`) so render and freeze-archives stay in lockstep. Internet Archive behavior is centralized in `ArchiveHelper` (HTTP + caching) and consumed by tags and the freeze command. Tests are RSpec under `spec/`; SimpleCov is started from `spec/spec_helper.rb` before the gem loads so coverage includes plugin code and excludes `spec/` / `vendor/`.

## Gemspec Owns Dev Dependencies

Development gems (RSpec, RuboCop, SimpleCov, WebMock, etc.) are declared in `jekyll-highlight-cards.gemspec` via `add_development_dependency`. The root `Gemfile` is only `gemspec`. Constraint bumps must update the gemspec and regenerate `Gemfile.lock`.

## Coverage Config Lives in Spec Helper

SimpleCov (and the Cobertura formatter under `CI`) is configured only in `spec/spec_helper.rb` using SimpleCov 1.x `skip` (not deprecated `add_filter`). Skip paths there are load-bearing for Codecov cleanliness; changing the SimpleCov DSL without keeping equivalent exclusions will pollute coverage reports. SimpleCov is skipped when Mutant is loaded. Mutation testing is configured in `config/mutant.yml` (`mutant` / `mutant-rspec`); kill discipline lives in `CONTRIBUTING.md`.
