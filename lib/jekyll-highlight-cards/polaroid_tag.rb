# frozen_string_literal: true

module JekyllHighlightCards
  # Liquid tag for creating styled polaroid photo components
  #
  # Syntax:
  #   {% polaroid IMAGE_URL [size=WxH] [alt="..."] [title="..."] [link="..."] [archive="..."] %}
  #
  # Parameters:
  #   - IMAGE_URL (required): Path or URL to the image (can be Liquid expression)
  #   - size=WxH (optional): Image dimensions (e.g., size=300x200, size=400x, size=x300)
  #   - alt="..." (optional): Alt text for the image (can be Liquid expression)
  #   - title="..." (optional): Title text to display (can be Liquid expression, also used as alt fallback)
  #   - link="..." (optional): URL to link to (can be Liquid expression)
  #   - archive="..." (optional): Archive URL or "none" to opt out
  #
  # Note: Alt text priority: alt parameter > title parameter > empty string
  #       This allows setting alt text without a visible title for accessibility
  #
  # Examples:
  #   {% polaroid /assets/img/photo.jpg %}
  #   {% polaroid /img/photo.jpg size=300x200 title="My Photo" %}
  #   {% polaroid /img/photo.jpg alt="Screen reader description" %}
  #   {% polaroid /img/photo.jpg alt="Detailed alt" title="Short Title" %}
  #   {% polaroid {{ page.image }} size=x400 title={{ page.title }} %}
  #   {% polaroid /img.jpg link="https://example.com" archive="none" %}
  class PolaroidTag < Liquid::Tag
    include ArchiveHelper
    include DimensionParser
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

    # Render the polaroid tag
    #
    # @param context [Liquid::Context] the Liquid rendering context
    # @return [String] rendered HTML
    def render(context)
      # Parse markup
      params = parse_markup(@markup, context)

      # Validate required image_url
      raise ArgumentError, "polaroid tag requires an image URL" if params[:image_url].nil? || params[:image_url].empty?

      # Parse size parameter if present
      width, height = parse_dimensions(params[:size]) if params[:size]

      # Determine link URL (defaults to image URL)
      # Track if link was explicitly provided
      explicit_link = !params[:link].nil? && !params[:link].empty?
      link_url = params[:link] || params[:image_url]

      # Resolve archive URL (archives the link URL, not the image)
      archive_url = resolve_archive(params[:archive], context, link_url)

      # Build template variables
      variables = build_template_variables(
        params[:image_url],
        width,
        height,
        params[:title],
        params[:alt],
        link_url,
        explicit_link,
        archive_url
      )

      # Get site from context
      site = context.registers[:site]

      # Render template
      render_template(site, "polaroid", variables)
    end

    private

    # Parse the tag markup into image_url and named parameters
    #
    # @param markup [String] the tag markup
    # @param context [Liquid::Context] the Liquid context
    # @return [Hash] parsed parameters
    def parse_markup(markup, context)
      # Split by whitespace, keeping quoted strings and Liquid expressions together
      tokens = []
      current = ""
      in_quotes = false
      quote_char = nil
      in_liquid = 0

      markup.each_char do |char|
        # Track Liquid expression boundaries
        if char == "{" && !in_quotes
          in_liquid += 1
          current += char
        elsif char == "}" && !in_quotes && in_liquid.positive?
          in_liquid -= 1
          current += char
        # Track quote boundaries
        elsif ['"', "'"].include?(char) && !in_quotes && in_liquid.zero?
          in_quotes = true
          quote_char = char
          current += char
        elsif char == quote_char && in_quotes
          in_quotes = false
          current += char
          quote_char = nil
        # Split on whitespace only if not in quotes or Liquid expression
        elsif char.match?(/\s/) && !in_quotes && in_liquid.zero?
          tokens << current unless current.empty?
          current = ""
        else
          current += char
        end
      end
      tokens << current unless current.empty?

      # First token is image URL (required)
      image_url_token = tokens.shift
      image_url = evaluate_expression(image_url_token, context, allow_nil: false)

      # Parse remaining tokens as key=value pairs
      result = { image_url: image_url }
      tokens.each do |token|
        next unless token =~ /^(\w+)=(.+)$/

        key = Regexp.last_match(1).to_sym
        value_token = Regexp.last_match(2)

        # Evaluate value as Liquid expression
        result[key] = evaluate_expression(value_token, context, allow_nil: true)
      end

      result
    end

    # Resolve archive URL (may be explicit, auto-lookup, or opt-out)
    #
    # @param source [String, nil] the archive source
    # @param context [Liquid::Context] the Liquid context (unused but kept for consistency)
    # @param url [String] the target URL to archive
    # @return [String, nil] resolved archive URL
    def resolve_archive(source, context, url)
      # Check for explicit opt-out
      return nil if source&.downcase == "none"

      # Check for explicit archive URL
      return evaluate_expression(source, context, allow_nil: true) if source && !source.empty?

      # Auto-lookup if enabled (archives the link URL, not the image)
      return archive_url_for(url) if archive_enabled?

      nil
    end

    # Build template variables hash for rendering
    #
    # @param image_url [String] the image URL
    # @param width [String, nil] the image width
    # @param height [String, nil] the image height
    # @param title [String, nil] the title text
    # @param alt [String, nil] the alt text for the image
    # @param link_url [String] the link URL
    # @param explicit_link [Boolean] whether link was explicitly provided
    # @param archive_url [String, nil] the archive URL
    # @return [Hash] template variables with raw and escaped versions
    def build_template_variables(image_url, width, height, title, alt, link_url, explicit_link, archive_url)
      # Only set link_display if link was explicitly provided (not defaulted to image)
      link_display = explicit_link && link_url ? strip_protocol(link_url) : nil

      {
        "image_url" => image_url,
        "link_url" => link_url,
        "title" => title,
        "alt" => alt,
        "link_display" => link_display,
        "archive_url" => archive_url,
        "width" => width,
        "height" => height,
        "escaped_image_url" => CGI.escapeHTML(image_url),
        "escaped_link_url" => link_url ? CGI.escapeHTML(link_url) : nil,
        "escaped_title" => title && !title.empty? ? CGI.escapeHTML(title) : "&nbsp;",
        "escaped_alt" => alt && !alt.empty? ? CGI.escapeHTML(alt) : "",
        "escaped_link_display" => link_display && !link_display.empty? ? CGI.escapeHTML(link_display) : "&nbsp;",
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
Liquid::Template.register_tag("polaroid", JekyllHighlightCards::PolaroidTag)
