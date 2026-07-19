# frozen_string_literal: true

module JekyllHighlightCards
  # Jekyll hooks for Markdown image sizing syntax
  #
  # Extends standard Markdown image syntax with dimension specifiers:
  # `![alt](image.jpg =300x200)`
  #
  # Automatically wraps sized images in links to themselves and applies
  # width/height attributes. Skips images in code blocks.
  #
  # @example Basic sizing
  #   ![Photo](image.jpg =300x200)
  #
  # @example Width only
  #   ![Photo](image.jpg =400x)
  #
  # @example Height only
  #   ![Photo](image.jpg =x300)
  #
  # @note Images inside code fences and inline code are not processed
  # @note Sized images are automatically wrapped in <a> tags (if not already)
  module ImageSizingHooks
    # Process document content before rendering
    # Converts ![alt](src =WxH) to ![alt](src)<!-- IMG_SIZE:W:H -->
    #
    # @param document [Jekyll::Document] the document being processed
    SIZED_MARKDOWN_PATTERN = /!\[([^\]]*)\]\(([^)]+)[ \t]+=([^)]+)\)/
    SIZED_IMG_HTML_PATTERN = /(\s*)(<img[ \t]+[^>]*>)\s*<!--\s*IMG_SIZE:([^:]*):([^:]*)\s*-->/

    # @param prefix [String] HTML preceding an image tag
    # @return [Integer] unclosed anchor tags in +prefix+
    def self.unclosed_anchor_count(prefix)
      prefix.scan("<a ").length + prefix.scan("<a\t").length - prefix.scan("</a>").length
    end

    def self.markdown_inline_check_position(full_match)
      full_match.begin(0)
    end

    def self.img_link_prefix(output, match)
      output[0, match.begin(2)]
    end

    def self.process_pre_render(document)
      content = document.content
      return unless content

      lines = content.lines
      result = []

      lines.each_with_index do |line, idx|
        # Skip lines in code fences
        if in_code_fence?(lines, idx)
          result << line
          next
        end

        # Process the line to convert sized images
        processed_line = line

        # Match ![alt](src =dimensions) pattern
        # Use gsub with block to check each match
        processed_line.gsub!(SIZED_MARKDOWN_PATTERN) do |match|
          full_match = Regexp.last_match
          match_start = markdown_inline_check_position(full_match)

          # Skip if inside inline code
          if in_inline_code?(line, match_start)
            match
          else
            alt = full_match[1]
            src = full_match[2].strip
            size = full_match[3].strip

            # Parse dimensions using DimensionParser
            width, height = DimensionParser.parse_dimensions(size)

            # Build marker comment
            "![#{alt}](#{src})<!-- IMG_SIZE:#{width}:#{height} -->"
          end
        end

        result << processed_line
      end

      document.content = result.join
    end

    # Process document content after rendering
    # Applies width/height attributes and auto-links sized images
    #
    # @param document [Jekyll::Document] the document being processed
    def self.process_post_render(document)
      output = document.output
      return unless output

      # Duplicate to avoid frozen string errors
      output = output.dup

      # Match <img><!-- IMG_SIZE:W:H --> patterns
      output.gsub!(SIZED_IMG_HTML_PATTERN) do
        match = Regexp.last_match
        img_tag = match[2]
        width = match[3].strip
        height = match[4].strip

        attrs = []
        attrs << %(width="#{width}") unless width.empty?
        attrs << %(height="#{height}") unless height.empty?

        modified_img = if attrs.any?
                         img_tag.sub("<img", "<img #{attrs.join(" ")}")
                       else
                         img_tag
                       end

        src = img_tag[/src=["']([^"']+)["']/, 1]
        next modified_img if src.nil?

        prefix = img_link_prefix(output, match)

        already_linked = unclosed_anchor_count(prefix).positive?

        # Auto-link if not already linked
        if already_linked
          modified_img
        else
          %(<a href="#{CGI.escapeHTML(CGI.unescapeHTML(src))}">#{modified_img}</a>)
        end
      end

      document.output = output
    end

    def self.fence_count_before(lines, line_idx)
      lines.first(line_idx).count { |line| line.start_with?("```", "~~~") }
    end

    # Check if a line is inside a code fence
    #
    # @param lines [Array<String>] all lines in the document
    # @param line_idx [Integer] the current line index
    # @return [Boolean] true if inside code fence
    def self.in_code_fence?(lines, line_idx)
      return true if fence_count_before(lines, line_idx).odd?
      return false unless line_idx.positive?

      lines.slice(line_idx).start_with?("    ", "\t")
    end

    # Count backtick characters before a position in a line
    #
    # @param line [String] the line of text
    # @param position [Integer] the position in the line
    # @return [Integer] number of backticks before +position+
    def self.backtick_count_before(line, position)
      line[0, position].count("`")
    end

    # Check if text position is inside inline code
    #
    # @param line [String] the line of text
    # @param position [Integer] the position in the line
    # @return [Boolean] true if inside inline code
    def self.in_inline_code?(line, position)
      backtick_count_before(line, position).odd?
    end
  end
end

# Register Jekyll hooks
Jekyll::Hooks.register :documents, :pre_render do |document|
  JekyllHighlightCards::ImageSizingHooks.process_pre_render(document)
end

Jekyll::Hooks.register :documents, :post_render do |document|
  JekyllHighlightCards::ImageSizingHooks.process_post_render(document)
end
