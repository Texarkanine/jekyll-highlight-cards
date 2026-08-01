# frozen_string_literal: true

module JekyllHighlightCards
  # Shared structural parser for `{% polaroid %}` markup.
  #
  # Used by {PolaroidTag} at render time (with Liquid evaluation applied by the
  # tag) and by freeze-archives analysis on unevaluated tokens.
  module PolaroidMarkup
    module_function

    # Parse polaroid markup into image URL and named parameters (unevaluated)
    #
    # @param markup [String] the tag markup (contents between tag name and `%}`)
    # @return [Hash] +:image_url+ plus any +key=value+ params as symbols (raw tokens)
    def parse(markup)
      tokens = tokenize(markup)

      image_url_token = tokens.shift
      result = { image_url: image_url_token }
      tokens.each do |token|
        next unless token =~ /\A(\w+)=(.+)\z/

        key = Regexp.last_match(1).to_sym
        value_token = Regexp.last_match(2)
        result[key] = value_token
      end

      result
    end

    # Tokenize markup respecting quotes (single or double) and Liquid brace depth
    #
    # @param markup [String] the tag markup
    # @return [Array<String>] tokens (may include empty strings from leading whitespace)
    def tokenize(markup)
      tokens = []
      current = ""
      in_quotes = false
      quote_char = nil
      in_liquid = 0
      escaped = false

      # Trailing space flushes the final token through the whitespace branch
      "#{markup} ".each_char do |char|
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

      tokens
    end
  end
end
