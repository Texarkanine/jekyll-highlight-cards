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
    extend DimensionParser

    # Process document content before rendering
    # Converts ![alt](src =WxH) to ![alt](src)<!-- IMG_SIZE:W:H -->
    #
    # @param document [Jekyll::Document] the document being processed
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
        processed_line = line.dup
        
        # Match ![alt](src =dimensions) pattern
        # Use gsub with block to check each match
        processed_line.gsub!(/!\[([^\]]*)\]\(([^)]+)\s+=([^)]+)\)/) do |match|
          match_start = Regexp.last_match.begin(0)
          
          # Skip if inside inline code
          if in_inline_code?(line, match_start)
            match
          else
            alt = Regexp.last_match(1)
            src = Regexp.last_match(2).strip
            size = Regexp.last_match(3).strip
            
            # Parse dimensions using DimensionParser
            width, height = parse_dimensions(size)
            
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
      output.gsub!(%r{(<img\s+[^>]*>)\s*<!--\s*IMG_SIZE:([^:]*):([^:]*)\s*-->}) do
        img_tag = Regexp.last_match(1)
        width = Regexp.last_match(2).to_s.strip
        height = Regexp.last_match(3).to_s.strip

        # Build attributes to add
        attrs = []
        attrs << %(width="#{width}") unless width.to_s.empty?
        attrs << %(height="#{height}") unless height.to_s.empty?

        # Add attributes to img tag
        modified_img = if attrs.any?
                         img_tag.sub(/<img/, "<img #{attrs.join(' ')}")
                       else
                         img_tag
                       end

        # Extract src for auto-linking
        src = img_tag[/src=["']([^"']+)["']/, 1]

        # Check if image is already in a link (look back in output)
        # Simple heuristic: check if there's an <a> tag before this image without a closing </a>
        already_linked = false
        img_position = Regexp.last_match.begin(0)
        prefix = output[0...img_position]
        
        # Count <a> and </a> tags before this image
        open_count = prefix.scan(/<a\s+/).length
        close_count = prefix.scan(%r{</a>}).length
        already_linked = (open_count > close_count)

        # Auto-link if not already linked
        if already_linked
          modified_img
        else
          %(<a href="#{CGI.escapeHTML(src)}">#{modified_img}</a>)
        end
      end

      document.output = output
    end

    # Check if a line is inside a code fence
    #
    # @param lines [Array<String>] all lines in the document
    # @param line_idx [Integer] the current line index
    # @return [Boolean] true if inside code fence
    def self.in_code_fence?(lines, line_idx)
      # Check for fenced code blocks (backticks or tildes)
      fence_count = 0
      (0...line_idx).each do |i|
        # Match both backtick and tilde fences
        fence_count += 1 if lines[i] =~ /^(`{3,}|~{3,})/
      end
      # Odd count means we're inside a fence
      return true if fence_count.odd?

      # Check for indented code blocks
      # A line is in an indented code block if there's a contiguous run
      # of indented lines (4+ spaces or tab) leading up to it
      return false if line_idx.zero?

      # Check if current line and previous lines are indented
      idx = line_idx
      while idx > 0
        line = lines[idx]
        # If line starts with 4+ spaces or tab, it's indented code
        break unless line =~ /^(    |\t)/

        idx -= 1
      end

      # If we found a contiguous run of indented lines reaching current line
      idx < line_idx
    end

    # Check if text position is inside inline code
    #
    # @param line [String] the line of text
    # @param position [Integer] the position in the line
    # @return [Boolean] true if inside inline code
    def self.in_inline_code?(line, position)
      # Count backticks before the position
      backtick_count = 0
      line[0...position].each_char do |char|
        backtick_count += 1 if char == "`"
      end
      # Odd count means we're inside inline code
      backtick_count.odd?
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

