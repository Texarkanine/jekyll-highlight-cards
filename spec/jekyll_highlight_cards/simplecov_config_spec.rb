# frozen_string_literal: true

require "spec_helper"

# Verifies SimpleCov 1.x is loaded and configured with `skip` (not deprecated
# `add_filter`) so coverage continues to exclude spec/ and vendor/ paths.
RSpec.describe SimpleCov do
  describe "loaded gem versions" do
    it "uses simplecov 1.x" do
      version = Gem.loaded_specs.fetch("simplecov").version
      expect(version).to be >= Gem::Version.new("1.0.0")
      expect(version).to be < Gem::Version.new("2.0.0")
    end

    it "uses simplecov-cobertura 4.x" do
      version = Gem.loaded_specs.fetch("simplecov-cobertura").version
      expect(version).to be >= Gem::Version.new("4.0.0")
      expect(version).to be < Gem::Version.new("5.0.0")
    end
  end

  describe "spec_helper.rb DSL" do
    subject(:helper_source) { File.read(File.expand_path("../spec_helper.rb", __dir__)) }

    it "configures exclusions with skip for spec and vendor" do
      expect(helper_source).to match(/^\s*skip\s+["'][^"']*spec/)
      expect(helper_source).to match(/^\s*skip\s+["'][^"']*vendor/)
    end

    it "does not use deprecated add_filter" do
      expect(helper_source).not_to include("add_filter")
    end
  end

  describe "active filters" do
    def filter_arguments
      described_class.filters.filter_map do |filter|
        filter.filter_argument if filter.respond_to?(:filter_argument)
      end
    end

    it "excludes paths containing spec/" do
      expect(filter_arguments.join).to include("spec")
    end

    it "excludes paths containing vendor/" do
      expect(filter_arguments.join).to include("vendor")
    end
  end
end
