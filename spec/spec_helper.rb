# frozen_string_literal: true

require "simplecov"
require "simplecov-cobertura"

# Configure coverage formatter for CI environments (Codecov)
SimpleCov.start do
  if ENV["CI"]
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
  
  add_filter "/spec/"
  add_filter "/vendor/"
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
end
