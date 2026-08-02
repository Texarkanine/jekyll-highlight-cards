# frozen_string_literal: true

module JekyllHighlightCards
  # Liquid tag for creating styled link card components
  #
  # Syntax:
  #   {% linkcard URL [TITLE] [archive:ARCHIVE_URL] %}
  #
  # Parameters:
  #   - URL (required): The URL to link to (can be Liquid expression)
  #   - TITLE (optional): Title text to display (can be Liquid expression)
  #   - archive:URL (optional): Explicit archive URL or "none" to opt out
  #
  # Examples:
  #   {% linkcard https://example.com %}
  #   {% linkcard https://example.com My Link Title %}
  #   {% linkcard {{ page.url }} {{ page.title }} %}
  #   {% linkcard https://example.com Title archive:none %}
  class LinkcardTag < Liquid::Tag
    include ArchiveHelper
    include ExpressionEvaluator
    include TemplateRenderer

    # Initialize the tag
    #
    # @param tag_name [String] the name of the tag
    # @param markup [String] the tag markup containing parameters
    # @param tokens [Array] parse tokens (unused)

    # Render the linkcard tag
    #
    # @param context [Liquid::Context] the Liquid rendering context
    # @return [String] rendered HTML
    def render(context)
      # Parse markup
      parsed = split_markup(@markup)

      # Resolve URL (required)
      url = resolve_url(parsed.fetch(:url), context)
      raise ArgumentError, "linkcard tag requires a URL" if url.nil? || url.empty?

      # Resolve title (optional)
      title = resolve_title(parsed[:title], context)

      # Resolve archive (optional, may auto-lookup)
      archive_url = resolve_archive(parsed[:archive], context, url)

      # Build template variables
      variables = build_template_variables(url, title, archive_url)

      # Get site from context
      site = context.registers[:site]

      # Render template
      render_template(site, "linkcard", variables)
    end

    private

    # Parse the tag markup into URL, title, and archive components
    #
    # @param markup [String] the tag markup
    # @return [Hash] parsed components
    def split_markup(markup)
      LinkcardMarkup.split(markup)
    end

    # Resolve URL from token (may be Liquid expression or literal)
    #
    # @param token [String] the URL token
    # @param context [Liquid::Context] the Liquid context
    # @return [String] resolved URL
    def resolve_url(token, context)
      evaluate_expression(token, context)
    end

    # Resolve title from source (may be Liquid expression or literal)
    #
    # @param source [String, nil] the title source
    # @param context [Liquid::Context] the Liquid context
    # @return [String, nil] resolved title
    def resolve_title(source, context)
      evaluate_expression(source, context)
    end

    # Resolve archive URL (may be explicit, auto-lookup, or opt-out)
    #
    # @param source [String, nil] the archive source
    # @param context [Liquid::Context] the Liquid context
    # @param url [String] the target URL to archive
    # @return [String, nil] resolved archive URL
    def resolve_archive(source, context, url)
      # Check for explicit opt-out
      return nil if source && source.downcase == "none"

      # Check for explicit archive URL
      return evaluate_expression(source, context) if source && !source.empty?

      archive_enabled? && archive_url_for(url, site: context.registers[:site])
    end

    # Build template variables hash for rendering
    #
    # @param url [String] the link URL
    # @param title [String, nil] the title text
    # @param archive_url [String, nil] the archive URL
    # @return [Hash] template variables with raw and escaped versions
    def build_template_variables(url, title, archive_url)
      display_url = strip_protocol(url).delete_suffix("/")

      variables = {
        "title" => title,
        "archive_url" => archive_url,
        "escaped_url" => CGI.escapeHTML(url),
        "escaped_display_url" => CGI.escapeHTML(display_url)
      }
      variables["escaped_title"] = CGI.escapeHTML(title) if title
      variables["escaped_archive_url"] = CGI.escapeHTML(archive_url) if archive_url
      variables
    end

    # Strip protocol from URL for display
    #
    # @param url [String] the URL
    # @return [String] URL without protocol
    def strip_protocol(url)
      url.delete_prefix("https://").delete_prefix("http://")
    end
  end
end

# Register the tag with Liquid
Liquid::Template.register_tag("linkcard", JekyllHighlightCards::LinkcardTag)
