# frozen_string_literal: true

module JekyllHighlightCards
  module FreezeArchives
    # Classify `{% linkcard %}` / `{% polaroid %}` markup for freeze-archives.
    #
    # A freeze candidate is a tag that has a literal archiveable target URL and
    # does not already encode an archive (`archive:` / `archive=` / `none`).
    # Liquid-dynamic targets are skipped (build-time fallback remains).
    class MarkupAnalyzer
      include ArchiveHelper
      include ExpressionEvaluator

      # Analyze tag markup for freeze eligibility
      #
      # @param tag [String] +"linkcard"+ or +"polaroid"+
      # @param markup [String] contents between the tag name and +%}+
      # @return [Hash, nil] +{ target_url: String }+ when freezable, else +nil+
      def analyze(tag, markup)
        case tag.to_s
        when "linkcard"
          analyze_linkcard(markup)
        when "polaroid"
          analyze_polaroid(markup)
        end
      end

      private

      def analyze_linkcard(markup)
        parsed = LinkcardMarkup.split(markup)
        return nil if parsed.key?(:archive)

        target = parsed[:url]
        candidate_for(target)
      end

      def analyze_polaroid(markup)
        parsed = PolaroidMarkup.parse(markup)
        return nil if parsed.key?(:archive)
        return nil unless parsed.key?(:link)

        candidate_for(strip_outer_quotes(parsed[:link]))
      end

      def candidate_for(target)
        return nil if target.to_s.empty?
        return nil if variable_lookup?(target)
        return nil unless archiveable_url?(target)

        { target_url: target }
      end
    end
  end
end
