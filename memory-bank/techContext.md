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
- Coverage via SimpleCov (with `simplecov-cobertura` formatter); output under `coverage/`. SimpleCov is skipped when Mutant is loaded (see `spec/spec_helper.rb`).
- Mutation testing via Mutant + `mutant-rspec`, configured in `config/mutant.yml`. Kill discipline (A/B buckets, no ignore cheats, no SUT stubs) is documented in `CONTRIBUTING.md`. Invoke with `bundle exec mutant test` / `bundle exec mutant run`.
