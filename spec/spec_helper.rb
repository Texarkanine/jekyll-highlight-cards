# frozen_string_literal: true

unless defined?(Mutant)
  require "simplecov"
  require "simplecov-cobertura"

  # Configure coverage formatter for CI environments (Codecov)
  SimpleCov.start do
    formatter SimpleCov::Formatter::CoberturaFormatter if ENV["CI"]

    skip "/spec/"
    skip "/vendor/"
  end
end

require "jekyll"
require "liquid"
require "webmock/rspec"
require "jekyll-highlight-cards"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Mock external HTTP requests by default
  WebMock.disable_net_connect!(allow_localhost: true)

  # Isolate archive-related ENV so Mutant parallel workers cannot leak
  # JEKYLL_HIGHLIGHT_CARDS_* values across examples in the same process.
  archive_env_keys = %w[
    JEKYLL_HIGHLIGHT_CARDS_ARCHIVE
    JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE
    JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_UA
    JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_CONTACT
  ].freeze

  config.around do |example|
    saved = archive_env_keys.to_h { |key| [key, ENV[key]] }
    archive_env_keys.each { |key| ENV.delete(key) }
    example.run
  ensure
    archive_env_keys.each do |key|
      if saved[key].nil?
        ENV.delete(key)
      else
        ENV[key] = saved[key]
      end
    end
  end
end
