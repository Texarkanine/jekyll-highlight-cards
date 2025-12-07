# frozen_string_literal: true

module JekyllHighlightCards
  # Module for parsing dimension specifications in "WxH" format
  # Supports formats: WIDTHxHEIGHT, WIDTHx, xHEIGHT, WIDTH
  module DimensionParser
    # Parse dimension string into width and height components
    #
    # @param dim_str [String] dimension string (e.g., "300x200", "300x", "x200", "300")
    # @return [Array<String, nil>] array of [width, height] where nil indicates unspecified
    #
    # @example
    #   parse_dimensions("300x200")  #=> ["300", "200"]
    #   parse_dimensions("300x")     #=> ["300", nil]
    #   parse_dimensions("x200")     #=> [nil, "200"]
    #   parse_dimensions("300")      #=> ["300", nil]
    #   parse_dimensions("400px")    #=> ["400px", nil]
    def parse_dimensions(dim_str)
      return [nil, nil] if dim_str.nil? || dim_str.empty?

      # Determine the separator:
      # - If "xx" is present, the SECOND 'x' is the separator (first 'x' is part of the dimension)
      #   Example: "400pxx300px" → width="400px", height="300px"
      # - Otherwise, check if there's an 'x' that's a separator (not part of a unit like "px")
      #   An 'x' is a separator if it's at the end, followed by a digit, or at the start
      if dim_str.include?("xx")
        # Find the position of "xx"
        idx = dim_str.index("xx")
        # Split at the second 'x' (include first 'x' in width, skip both 'x's for height)
        width = dim_str[0..idx].empty? ? nil : dim_str[0..idx]
        height = dim_str[idx+2..-1]
        height = nil if height.nil? || height.empty?
        [width, height]
      elsif dim_str =~ /x\d/ || dim_str =~ /(?<![a-z])x$/i || dim_str.start_with?("x")
        # Single 'x' separator in one of these cases:
        # 1. Followed by a digit: "300x200", "10emx20em"
        # 2. At end but NOT preceded by a letter: "300x"
        # 3. At start: "x200"
        # This matches "300x", "300x200", "x200", "10emx20em", but NOT "400px"
        parts = dim_str.split("x", 2)
        width = parts[0].empty? ? nil : parts[0]
        height = parts[1].nil? || parts[1].empty? ? nil : parts[1]
        [width, height]
      else
        # No separator found - treat as width only
        [dim_str, nil]
      end
    end

    module_function :parse_dimensions
  end
end


