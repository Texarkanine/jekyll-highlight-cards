# Tech Context

A Ruby gem that is also a Jekyll plugin. Ruby implements the Liquid tags and Jekyll hooks; SCSS (in `_sass/`) and HTML (in `_includes/highlight-cards/`) ship as bundled assets. Runtime dependencies are Jekyll 4.x and Liquid 4.x (pinned in `jekyll-highlight-cards.gemspec`).

## Environment Setup

- Ruby version is pinned in `.ruby-version`; the minimum is enforced by `required_ruby_version` in `jekyll-highlight-cards.gemspec` and `TargetRubyVersion` in `.rubocop.yml`. (Note: `CONTRIBUTING.md` states an older minimum and is out of date relative to the gemspec.)
- Install dependencies with `bundle install` (Bundler; deps locked in `Gemfile.lock`).

## Build Tools

- Gem is built from `jekyll-highlight-cards.gemspec` (`gem build`); `spec.files` there controls what ships.
- Releases are automated via release-please (`release-please-config.json`, `.release-please-manifest.json`), so the version in `lib/jekyll-highlight-cards/version.rb` and `CHANGELOG.md` are release-managed - do not hand-edit version/changelog outside that flow.

## Testing Process

- Tests run under RSpec, configured by `.rspec` and `spec/spec_helper.rb`, invoked with `bundle exec rspec`.
- External HTTP is blocked in tests by WebMock (`spec_helper.rb`); any new network code must be stubbed in specs.
- Coverage is collected by SimpleCov (Cobertura format under `CI`, reported to Codecov).
- Linting is RuboCop (+`rubocop-rake`, +`rubocop-rspec`) configured in `.rubocop.yml`; run `bundle exec rubocop`.

## Design System

The visual style authority for the rendered cards is the SCSS in `_sass/` (`_highlight-cards-structure.scss`, `_highlight-cards-colors.scss`, `_highlight-cards.scss`). Default HTML structure lives in `_includes/highlight-cards/`. There is no external design-token system, Figma, or Storybook - these files are the source of truth, and consumers override them as documented in `README.md`.
