# frozen_string_literal: true

module JekyllHighlightCards
  module FreezeArchives
    # Locate `{% linkcard %}` / `{% polaroid %}` spans in source text.
    #
    # Supports multiline tags. Returns structural spans for analysis/insert —
    # does not decide freeze eligibility.
    class TagLocator
      TAG_PATTERN = /{%\s*(linkcard|polaroid)\s+([\s\S]*?)%}/

      # Find highlight-card tag spans in +text+
      #
      # @param text [String] file contents
      # @return [Array<Hash>] each hash has +:tag+, +:markup+, +:range+ (exclusive end)
      def locate(text)
        spans = []
        text.to_s.scan(TAG_PATTERN) do
          match = Regexp.last_match
          spans << {
            tag: match[1],
            markup: match[2],
            range: match.begin(0)...match.end(0)
          }
        end
        spans
      end
    end
  end
end
