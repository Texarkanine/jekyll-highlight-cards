# frozen_string_literal: true

module JekyllHighlightCards
  # Parse dimension specifications in "WxH" format
  #
  # Supports multiple formats for specifying image dimensions:
  # - `WIDTHxHEIGHT`: Both dimensions (e.g., "300x200")
  # - `WIDTHx`: Width only (e.g., "300x")
  # - `xHEIGHT`: Height only (e.g., "x200")
  # - `WIDTH`: Width only shorthand (e.g., "300")
  # - Units: Supports px, em, %, etc. (e.g., "400pxx300px")
  #
  # @example
  #   width, height = DimensionParser.parse_dimensions("300x200")  #=> ["300", "200"]
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
    def self.parse_dimensions(dim_str)
      return [nil, nil] if dim_str.nil? || dim_str.empty?

      # Determine the separator:
      # - If "xx" is present, the SECOND 'x' is the separator (first 'x' is part of the dimension)
      #   Example: "400pxx300px" → width="400px", height="300px"
      # - Otherwise, check if there's an 'x' that's a separator (not part of a unit like "px")
      #   An 'x' is a separator if it's at the end, followed by a digit, or at the start
      if dim_str.include?("xx")
        idx = dim_str.index("xx")
        width = dim_str[...(idx + 1)]
        height = dim_str[(idx + 2)..]
        height = nil if height.empty?
        [width, height]
      elsif dim_str.match?(/x\d|(?<![a-z])x\z/) || dim_str.start_with?("x")
        width_str, height_str = dim_str.split("x", 2)
        width = width_str
        width = nil if width.empty?
        height = height_str
        height = nil if height.empty?
        [width, height]
      else
        # No separator found - treat as width only
        [dim_str, nil]
      end
    end
  end
end
