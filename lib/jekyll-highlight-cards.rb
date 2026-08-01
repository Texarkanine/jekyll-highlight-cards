# frozen_string_literal: true

require "jekyll"
require "liquid"
require "cgi"
require "net/http"
require "uri"
require "json"

require_relative "jekyll-highlight-cards/version"
require_relative "jekyll-highlight-cards/dimension_parser"
require_relative "jekyll-highlight-cards/expression_evaluator"
require_relative "jekyll-highlight-cards/archive_helper"
require_relative "jekyll-highlight-cards/template_renderer"
require_relative "jekyll-highlight-cards/linkcard_markup"
require_relative "jekyll-highlight-cards/polaroid_markup"

# Require tags and hooks
require_relative "jekyll-highlight-cards/linkcard_tag"
require_relative "jekyll-highlight-cards/polaroid_tag"
require_relative "jekyll-highlight-cards/image_sizing_hooks"
require_relative "jekyll-highlight-cards/freeze_archives/markup_analyzer"
require_relative "jekyll-highlight-cards/freeze_archives/tag_locator"
require_relative "jekyll-highlight-cards/freeze_archives/archive_inserter"

# jekyll-highlight-cards: Styled card components for Jekyll
#
# This gem provides:
# - {LinkcardTag}: `{% linkcard %}` Liquid tag for styled link cards
# - {PolaroidTag}: `{% polaroid %}` Liquid tag for polaroid-style image cards
# - {ImageSizingHooks}: Markdown image sizing syntax `![alt](img.jpg =300x200)`
# - {ArchiveHelper}: Internet Archive integration with caching
#
# @example Basic linkcard usage
#   {% linkcard https://example.com My Title %}
#
# @example Basic polaroid usage
#   {% polaroid /assets/image.jpg size=300x200 title="Photo" %}
#
# @example Markdown image sizing
#   ![Alt text](image.jpg =400x300)
#
# @see README.md Full usage documentation
module JekyllHighlightCards
  # 1. Define the path to SCSS files relative to this Ruby file
  SASS_PATH = File.join(File.dirname(__FILE__), "../_sass")

  # 2. Register a hook to run after Jekyll initializes
  Jekyll::Hooks.register :site, :after_init do |site|
    # Ensure the 'sass' and 'load_paths' config keys exist
    site.config["sass"] ||= {}
    site.config["sass"]["load_paths"] ||= []

    # 3. Append your plugin's path to the load_paths array
    # We check first to avoid adding it multiple times (e.g. in watch mode)
    site.config["sass"]["load_paths"] << SASS_PATH unless site.config["sass"]["load_paths"].include?(SASS_PATH)
  end
end
