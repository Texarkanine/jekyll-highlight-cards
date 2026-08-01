# frozen_string_literal: true

module JekyllHighlightCards
  # Shared structural parser for `{% linkcard %}` markup.
  #
  # Used by {LinkcardTag} at render time and by freeze-archives analysis
  # without Liquid evaluation. Tokens are returned as written in source.
  module LinkcardMarkup
    module_function

    # Parse linkcard markup into URL, title, and archive components
    #
    # @param markup [String] the tag markup (contents between tag name and `%}`)
    # @return [Hash] keys +:url+, optional +:title+, optional +:archive+ (unevaluated)
    def split(markup)
      tokens = tokenize(markup)

      result = {}
      result[:url] = tokens.shift

      title_tokens = []
      tokens.each do |token|
        if token.start_with?("archive:")
          result[:archive] = token.delete_prefix("archive:")
        else
          title_tokens << token
        end
      end
      result[:title] = title_tokens.join(" ") unless title_tokens.empty?

      result
    end

    # Tokenize markup respecting quotes and Liquid brace depth
    #
    # @param markup [String] the tag markup
    # @return [Array<String>] non-empty tokens
    def tokenize(markup)
      tokens = []
      current = ""
      in_quotes = false
      quote_char = nil
      in_liquid = 0
      escaped = false

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
        elsif char == '"' && !in_quotes
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
      tokens.reject!(&:empty?)
      tokens
    end
  end
end
