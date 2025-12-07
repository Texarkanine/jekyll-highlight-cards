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

# Require tags and hooks
require_relative "jekyll-highlight-cards/linkcard_tag"
require_relative "jekyll-highlight-cards/polaroid_tag"
require_relative "jekyll-highlight-cards/image_sizing_hooks"

module JekyllHighlightCards
  # Main gem module - provides Liquid tags and hooks for Jekyll
end
