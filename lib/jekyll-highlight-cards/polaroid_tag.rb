# frozen_string_literal: true

module JekyllHighlightCards
  # Liquid tag for creating styled polaroid photo components
  #
  # Syntax:
  #   {% polaroid IMAGE_URL [size=WxH] [alt="..."] [title="..."] [link="..."] [image_link="..."] [archive="..."] %}
  #
  # Parameters:
  #   - IMAGE_URL (required): Path or URL to the image (can be Liquid expression)
  #   - size=WxH (optional): Image dimensions (e.g., size=300x200, size=400x, size=x300)
  #   - alt="..." (optional): Alt text for the image (can be Liquid expression)
  #   - title="..." (optional): Title text to display (can be Liquid expression, also used as alt fallback)
  #   - link="..." (optional): URL to link to (can be Liquid expression)
  #   - image_link="..." (optional): URL for the image to link to, overrides default behavior (can be Liquid expression)
  #   - archive="..." (optional): Archive URL or "none" to opt out
  #
  # Note: Alt text priority: alt parameter > title parameter > empty string
  #       This allows setting alt text without a visible title for accessibility
  #
  # Note: Image link behavior:
  #       - No link or image_link: image links to itself
  #       - link only: image links to link URL
  #       - image_link: image links to image_link URL (overrides default)
  #
  # Examples:
  #   {% polaroid /assets/img/photo.jpg %}
  #   {% polaroid /img/photo.jpg size=300x200 title="My Photo" %}
  #   {% polaroid /img/photo.jpg alt="Screen reader description" %}
  #   {% polaroid /img/photo.jpg alt="Detailed alt" title="Short Title" %}
  #   {% polaroid {{ page.image }} size=x400 title={{ page.title }} %}
  #   {% polaroid /img.jpg link="https://example.com" archive="none" %}
  #   {% polaroid /img.jpg link="https://example.com" image_link="https://other.com" %}
  class PolaroidTag < Liquid::Tag
    include ArchiveHelper
    include ExpressionEvaluator
    include TemplateRenderer

    # Render the polaroid tag
    #
    # @param context [Liquid::Context] the Liquid rendering context
    # @return [String] rendered HTML
    def render(context)
      params = parse_markup(@markup, context)

      raise ArgumentError, "polaroid tag requires an image URL" if params.fetch(:image_url).empty?

      width, height = DimensionParser.parse_dimensions(params[:size])

      explicit_link = !params[:link].to_s.empty?
      link_url = if params[:link].to_s.empty?
                   params.fetch(:image_url)
                 else
                   params.fetch(:link)
                 end
      image_link_url = if params[:image_link].to_s.empty?
                         link_url
                       else
                         params.fetch(:image_link)
                       end
      archive_url = resolve_archive(params[:archive], link_url)

      variables = build_template_variables(
        params.fetch(:image_url),
        width,
        height,
        params[:title],
        params[:alt],
        link_url,
        image_link_url,
        explicit_link,
        archive_url
      )

      render_template(context.registers[:site], "polaroid", variables)
    end

    private

    # Parse the tag markup into image_url and named parameters
    #
    # @param markup [String] the tag markup
    # @param context [Liquid::Context] the Liquid context
    # @return [Hash] parsed parameters
    def parse_markup(markup, context)
      tokens = []
      current = ""
      in_quotes = false
      quote_char = nil
      in_liquid = 0
      escaped = false

      # Trailing space flushes the final token through the whitespace branch
      (markup + " ").each_char do |char|
        if escaped
          current += char
          escaped = false
          next
        end

        if char == "\\" && in_quotes
          escaped = true
          next
        end

        if char == "{" && !in_quotes
          in_liquid += 1
          current += char
        elsif char == "}" && in_liquid.positive?
          in_liquid -= 1
          current += char
        elsif ['"', "'"].include?(char) && !in_quotes
          in_quotes = true
          quote_char = char
          current += char
        elsif char == quote_char
          in_quotes = false
          current += char
          quote_char = nil
        elsif char.match?(/\s/) && !in_quotes && in_liquid.zero?
          tokens << current
          current = ""
        else
          current += char
        end
      end

      image_url_token = tokens.shift
      image_url = evaluate_expression(image_url_token, context)

      result = { image_url: image_url }
      tokens.each do |token|
        next unless token =~ /\A(\w+)=(.+)\z/

        key = Regexp.last_match(1).to_sym
        value_token = Regexp.last_match(2)
        result[key] = evaluate_expression(value_token, context)
      end

      result
    end

    # Resolve archive URL (may be explicit, auto-lookup, or opt-out).
    # Named archive params are already Liquid-evaluated in parse_markup.
    #
    # @param source [String, nil] the archive source
    # @param url [String] the target URL to archive
    # @return [String, nil] resolved archive URL
    def resolve_archive(source, url)
      return nil if source && source.downcase == "none"
      return source unless source.to_s.empty?

      archive_enabled? && archive_url_for(url)
    end

    # Build template variables hash for rendering
    #
    # @param image_url [String] the image URL
    # @param width [String, nil] the image width
    # @param height [String, nil] the image height
    # @param title [String, nil] the title text
    # @param alt [String, nil] the alt text for the image
    # @param link_url [String] the link URL (for display)
    # @param image_link_url [String] the URL the image links to
    # @param explicit_link [Boolean] whether link was explicitly provided
    # @param archive_url [String, nil] the archive URL
    # @return [Hash] template variables with raw and escaped versions
    def build_template_variables(
      image_url,
      width,
      height,
      title,
      alt,
      link_url,
      image_link_url,
      explicit_link,
      archive_url
    )
      link_display = strip_protocol(link_url) if explicit_link
      escaped_title = CGI.escapeHTML(title.to_s)
      escaped_title = "&nbsp;" if escaped_title.empty?

      {
        "image_url" => image_url,
        "image_link_url" => image_link_url,
        "title" => title,
        "alt" => alt,
        "link_display" => link_display,
        "archive_url" => archive_url,
        "width" => width,
        "height" => height,
        "escaped_image_url" => CGI.escapeHTML(image_url),
        "escaped_link_url" => CGI.escapeHTML(link_url),
        "escaped_image_link_url" => CGI.escapeHTML(image_link_url),
        "escaped_title" => escaped_title,
        "escaped_alt" => CGI.escapeHTML(alt.to_s),
        "escaped_link_display" => link_display && CGI.escapeHTML(link_display),
        "escaped_archive_url" => archive_url && CGI.escapeHTML(archive_url)
      }
    end

    # Strip protocol from URL for display
    #
    # @param url [String] the URL
    # @return [String] URL without protocol
    def strip_protocol(url)
      url.sub(%r{\Ahttps?://}, "")
    end
  end
end

# Register the tag with Liquid
Liquid::Template.register_tag("polaroid", JekyllHighlightCards::PolaroidTag)
