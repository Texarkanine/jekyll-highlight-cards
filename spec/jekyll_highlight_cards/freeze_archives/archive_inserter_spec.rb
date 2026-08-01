# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::FreezeArchives::ArchiveInserter do
  subject(:inserter) { described_class.new }

  let(:archive_url) { "https://web.archive.org/web/20200101120000/https://example.com" }

  def span_for(content, tag_name)
    JekyllHighlightCards::FreezeArchives::TagLocator.new.locate(content).find { |s| s[:tag] == tag_name }
  end

  describe "#insert" do
    # I1–I5: surgical archive insert preserving author formatting

    it "I1: splices archive: into a single-line linkcard" do
      content = "  {% linkcard https://example.com Title  %}\n"
      result = inserter.insert(content, span_for(content, "linkcard"), archive_url)
      expect(result).to eq("  {% linkcard https://example.com Title archive:#{archive_url}  %}\n")
    end

    it "I2: splices archive= into a single-line polaroid" do
      content = "{% polaroid /img.jpg link=\"https://example.com\" %}\n"
      result = inserter.insert(content, span_for(content, "polaroid"), archive_url)
      expect(result).to eq("{% polaroid /img.jpg link=\"https://example.com\" archive=\"#{archive_url}\" %}\n")
    end

    it "I3: preserves surrounding title and params without rebuilding" do
      content = "{% linkcard https://example.com \"My Title\" size=ignored %}\n"
      result = inserter.insert(content, span_for(content, "linkcard"), archive_url)
      expect(result).to include('"My Title"')
      expect(result).to include("size=ignored")
      expect(result).to include("archive:#{archive_url}")
      expect(result).to start_with("{% linkcard https://example.com \"My Title\" size=ignored archive:")
    end

    it "I4: inserts an indented archive line for multiline linkcard" do
      content = <<~TEXT
        {% linkcard
            https://example.com
        %}
      TEXT
      result = inserter.insert(content, span_for(content, "linkcard"), archive_url)
      expect(result).to eq(<<~TEXT)
        {% linkcard
            https://example.com
            archive:#{archive_url}
        %}
      TEXT
    end

    it "I5: inserts an indented archive line for multiline polaroid" do
      content = <<~TEXT
        {% polaroid
          /img.jpg
          link="https://example.com"
        %}
      TEXT
      result = inserter.insert(content, span_for(content, "polaroid"), archive_url)
      expect(result).to eq(<<~TEXT)
        {% polaroid
          /img.jpg
          link="https://example.com"
          archive="#{archive_url}"
        %}
      TEXT
    end

    it "escapes embedded double quotes in polaroid archive URLs" do
      nasty = 'https://example.com/q?"weird"'
      content = "{% polaroid /img.jpg link=\"https://example.com\" %}"
      result = inserter.insert(content, span_for(content, "polaroid"), nasty)
      expect(result).to include('archive="https://example.com/q?\\"weird\\""')
    end

    it "round-trips escaped polaroid archive URLs through PolaroidMarkup" do
      nasty = 'https://example.com/q?"weird"'
      token = inserter.send(:archive_token, "polaroid", nasty)
      parsed = JekyllHighlightCards::PolaroidMarkup.parse("/img.jpg #{token}")
      stripper = Class.new { include JekyllHighlightCards::ExpressionEvaluator }.new

      expect(stripper.strip_outer_quotes(parsed[:archive])).to eq(nasty)
    end

    it "preserves leading whitespace-control opener {%-" do
      content = "{%- linkcard https://example.com Title %}\n"
      result = inserter.insert(content, span_for(content, "linkcard"), archive_url)
      expect(result).to eq("{%- linkcard https://example.com Title archive:#{archive_url} %}\n")
    end

    it "copies tab indentation from the last content line" do
      content = "{% linkcard\n\thttps://example.com\n%}"
      result = inserter.insert(content, span_for(content, "linkcard"), archive_url)
      expect(result).to eq("{% linkcard\n\thttps://example.com\n\tarchive:#{archive_url}\n%}")
    end

    it "preserves indented closer indentation on multiline tags" do
      content = "  {% linkcard\n      https://example.com\n  %}\n"
      result = inserter.insert(content, span_for(content, "linkcard"), archive_url)
      expect(result).to eq(
        "  {% linkcard\n      https://example.com\n      archive:#{archive_url}\n  %}\n"
      )
    end

    it "preserves Liquid whitespace-control closer -%}" do
      content = "{% linkcard https://example.com Title -%}\n"
      result = inserter.insert(content, span_for(content, "linkcard"), archive_url)
      expect(result).to eq("{% linkcard https://example.com Title archive:#{archive_url} -%}\n")
    end
  end
end
