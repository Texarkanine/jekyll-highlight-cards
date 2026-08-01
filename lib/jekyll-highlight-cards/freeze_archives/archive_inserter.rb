# frozen_string_literal: true

module JekyllHighlightCards
  module FreezeArchives
    # Surgically insert an archive token into a located tag span.
    #
    # Single-line tags splice after the last non-whitespace of the markup.
    # Multiline tags add a new line before the closer, indented like the last
    # content line (see creative-source-scan-rewrite).
    class ArchiveInserter
      # Insert archive URL into +content+ at +span+
      #
      # @param content [String] full file contents
      # @param span [Hash] locator span with +:tag+, +:markup+, +:range+
      # @param archive_url [String] Wayback (or other) archive URL to freeze
      # @return [String] updated file contents
      def insert(content, span, archive_url)
        range = span.fetch(:range)
        tag_text = content[range]
        updated = rewrite_tag(tag_text, span.fetch(:tag), archive_url)
        content[0...range.begin] + updated + content[range.end..]
      end

      private

      def rewrite_tag(tag_text, tag, archive_url)
        token = archive_token(tag, archive_url)
        closer_index = tag_text.rindex("%}")
        raise ArgumentError, "tag span missing closing %}" unless closer_index

        head = tag_text[0...closer_index]
        closer = tag_text[closer_index..]

        if head.include?("\n")
          insert_multiline(head, closer, token)
        else
          insert_single_line(head, closer, token)
        end
      end

      def insert_single_line(head, closer, token)
        # Preserve trailing whitespace before %}
        trailing = head[/\s*\z/] || ""
        body = head[0...(head.length - trailing.length)]
        "#{body} #{token}#{trailing}#{closer}"
      end

      def insert_multiline(head, closer, token)
        lines = head.split("\n", -1)
        # Drop trailing empty segment produced by a newline immediately before %}
        lines.pop if lines.last == ""

        last_content = lines.reverse.find { |line| !line.strip.empty? }
        indent = last_content ? last_content[/\A[ \t]*/] : ""

        "#{lines.join("\n")}\n#{indent}#{token}\n#{closer}"
      end

      def archive_token(tag, archive_url)
        case tag.to_s
        when "linkcard"
          "archive:#{archive_url}"
        when "polaroid"
          %(archive="#{archive_url.to_s.gsub('"', '\\"')}")
        else
          raise ArgumentError, "unsupported tag: #{tag}"
        end
      end
    end
  end
end
