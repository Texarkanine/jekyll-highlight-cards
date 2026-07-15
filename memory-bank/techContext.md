# Tech Context

Jekyll 4 plugin gem written in Ruby, tested with RSpec, linted with RuboCop. Packaging and versioning via the gemspec + release-please.

## Environment Setup

- Ruby version pinned in `.ruby-version` (gemspec requires `>= 3.3.0`)
- Install with `bundle install` from the repo root (`Gemfile` delegates to the gemspec)

## Build Tools

- Bundler / RubyGems — `jekyll-highlight-cards.gemspec`, `Gemfile`, `Gemfile.lock`
- RuboCop — `.rubocop.yml` (`bundle exec rubocop`)
- GitHub Actions — `.github/workflows/` (`ci.yaml` runs `bundle exec rspec` on PRs)

## Testing Process

- RSpec configured via `.rspec` and `spec/spec_helper.rb`
- Run suite: `bundle exec rspec`
- Coverage: SimpleCov (+ `simplecov-cobertura` when `CI` is set); Codecov upload on release workflow
