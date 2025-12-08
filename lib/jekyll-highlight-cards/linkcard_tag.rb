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
    def initialize(tag_name, markup, tokens)
      super
      @markup = markup.strip
    end

    # Render the linkcard tag
    #
    # @param context [Liquid::Context] the Liquid rendering context
    # @return [String] rendered HTML
    def render(context)
      # Parse markup
      parsed = split_markup(@markup)

      # Resolve URL (required)
      url = resolve_url(parsed[:url], context)
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
      # Split by whitespace, keeping quoted strings and Liquid expressions together
      # Handles escaped quotes (\") and backslashes (\\) within quoted strings
      tokens = []
      current = ""
      in_quotes = false
      quote_char = nil
      in_liquid = 0  # Track nested Liquid expressions
      escaped = false  # Track if next character is escaped

      markup.each_char do |char|
        # Handle escape sequences when in quotes
        if escaped
          current += char  # Add the escaped character directly
          escaped = false
          next
        end

        # Check for escape character when in quotes
        if char == "\\" && in_quotes
          escaped = true
          next  # Don't add backslash to output, it's just the escape marker
        end

        # Track Liquid expression boundaries
        if char == "{" && !in_quotes
          in_liquid += 1
          current += char
        elsif char == "}" && !in_quotes && in_liquid > 0
          in_liquid -= 1
          current += char
        # Track quote boundaries
        elsif ['"', "'"].include?(char) && !in_quotes && in_liquid == 0
          in_quotes = true
          quote_char = char
          current += char
        elsif char == quote_char && in_quotes
          in_quotes = false
          current += char
          quote_char = nil
        # Split on whitespace only if not in quotes or Liquid expression
        elsif char.match?(/\s/) && !in_quotes && in_liquid == 0
          tokens << current unless current.empty?
          current = ""
        else
          current += char
        end
      end
      tokens << current unless current.empty?

      # First token is URL, remaining tokens may be title or archive parameter
      result = {
        url: tokens.shift,
        title: nil,
        archive: nil
      }

      # Process remaining tokens
      tokens.each do |token|
        if token.start_with?("archive:")
          result[:archive] = token.sub(/^archive:/, "")
        else
          # Accumulate title tokens
          result[:title] = result[:title].nil? ? token : "#{result[:title]} #{token}"
        end
      end

      result
    end

    # Resolve URL from token (may be Liquid expression or literal)
    #
    # @param token [String] the URL token
    # @param context [Liquid::Context] the Liquid context
    # @return [String] resolved URL
    def resolve_url(token, context)
      return nil if token.nil? || token.empty?

      evaluate_expression(token, context, allow_nil: false)
    end

    # Resolve title from source (may be Liquid expression or literal)
    #
    # @param source [String, nil] the title source
    # @param context [Liquid::Context] the Liquid context
    # @return [String, nil] resolved title
    def resolve_title(source, context)
      return nil if source.nil? || source.empty?

      evaluate_expression(source, context, allow_nil: true)
    end

    # Resolve archive URL (may be explicit, auto-lookup, or opt-out)
    #
    # @param source [String, nil] the archive source
    # @param context [Liquid::Context] the Liquid context
    # @param url [String] the target URL to archive
    # @return [String, nil] resolved archive URL
    def resolve_archive(source, context, url)
      # Check for explicit opt-out
      if source && source.downcase == "none"
        return nil
      end

      # Check for explicit archive URL
      if source && !source.empty?
        return evaluate_expression(source, context, allow_nil: true)
      end

      # Auto-lookup if enabled
      if archive_enabled?
        return archive_url_for(url)
      end

      nil
    end

    # Build template variables hash for rendering
    #
    # @param url [String] the link URL
    # @param title [String, nil] the title text
    # @param archive_url [String, nil] the archive URL
    # @return [Hash] template variables with raw and escaped versions
    def build_template_variables(url, title, archive_url)
      display_url = strip_protocol(url)

      {
        "url" => url,
        "display_url" => display_url,
        "title" => title,
        "archive_url" => archive_url,
        "escaped_url" => CGI.escapeHTML(url),
        "escaped_display_url" => CGI.escapeHTML(display_url),
        "escaped_title" => title ? CGI.escapeHTML(title) : nil,
        "escaped_archive_url" => archive_url ? CGI.escapeHTML(archive_url) : nil
      }
    end

    # Strip protocol from URL for display
    #
    # @param url [String] the URL
    # @return [String] URL without protocol
    def strip_protocol(url)
      url.sub(%r{^https?://}, "")
    end
  end
end

# Register the tag with Liquid
Liquid::Template.register_tag("linkcard", JekyllHighlightCards::LinkcardTag)

