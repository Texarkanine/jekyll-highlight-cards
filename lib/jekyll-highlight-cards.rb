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
  # Main gem module - provides Liquid tags and hooks for Jekyll
end
