# frozen_string_literal: true

require_relative "lib/jekyll-highlight-cards/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-highlight-cards"
  spec.version       = JekyllHighlightCards::VERSION
  spec.authors       = ["Texarkanine"]
  spec.email         = ["texarkanine@protonmail.com"]

  spec.summary       = "Jekyll plugin providing linkcard and polaroid Liquid tags with archive integration"
  spec.description   = "A Jekyll plugin that provides two Liquid tags (linkcard and polaroid) for creating " \
                       "styled card components with integrated Internet Archive functionality and image sizing. " \
                       "Also extends Markdown support to allow specifying image dimensions."
  spec.homepage      = "https://github.com/texarkanine/jekyll-highlight-cards"
  spec.license       = "AGPL-3.0-or-later"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features|planning|examples|\.cursor|memory-bank)/})
    end
  end

  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "jekyll", ">= 4.0", "< 5.0"
  spec.add_dependency "liquid", ">= 4.0", "< 5.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 3.8"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-cobertura", "~> 3.1"
  spec.add_development_dependency "webmock", "~> 3.18"
end
