# frozen_string_literal: true

require "spec_helper"

# Observes the site :after_init hook registered in lib/jekyll-highlight-cards.rb
# that appends the gem's _sass path to site.config["sass"]["load_paths"].
RSpec.describe "JekyllHighlightCards Sass load path hook" do
  describe "site after_init registration" do
    it "appends the gem SASS_PATH to an empty sass load_paths list" do
      site = instance_double(Jekyll::Site, config: {})

      Jekyll::Hooks.trigger :site, :after_init, site

      expect(site.config["sass"]).to be_a(Hash)
      expect(site.config["sass"]["load_paths"]).to include(JekyllHighlightCards::SASS_PATH)
    end

    it "does not duplicate SASS_PATH when after_init runs again" do
      site = instance_double(
        Jekyll::Site,
        config: { "sass" => { "load_paths" => [JekyllHighlightCards::SASS_PATH] } }
      )

      Jekyll::Hooks.trigger :site, :after_init, site

      expect(site.config["sass"]["load_paths"]).to eq([JekyllHighlightCards::SASS_PATH])
    end
  end
end
