# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::FreezeArchives::MarkupAnalyzer do
  subject(:analyzer) { described_class.new }

  describe "#analyze" do
    # A1–A8: classify freeze candidates vs skips from tag markup

    it "A1: returns a candidate for linkcard with literal https URL and no archive" do
      result = analyzer.analyze("linkcard", "https://example.com My Title")
      expect(result).to eq(target_url: "https://example.com")
    end

    it "A2: skips linkcard with archive:none" do
      expect(analyzer.analyze("linkcard", "https://example.com archive:none")).to be_nil
    end

    it "A3: skips linkcard with an explicit archive URL" do
      markup = "https://example.com archive:https://web.archive.org/web/2020/https://example.com"
      expect(analyzer.analyze("linkcard", markup)).to be_nil
    end

    it "A4: skips linkcard whose URL is a Liquid expression" do
      expect(analyzer.analyze("linkcard", "{{ page.url }} Title")).to be_nil
    end

    it "A5: returns a candidate for polaroid with explicit link= and no archive" do
      markup = '/img.jpg link="https://example.com/page"'
      result = analyzer.analyze("polaroid", markup)
      expect(result).to eq(target_url: "https://example.com/page")
    end

    it "A6: skips polaroid without link=" do
      expect(analyzer.analyze("polaroid", "/img.jpg title=\"Photo\"")).to be_nil
    end

    it "A7: skips polaroid with archive=\"none\"" do
      markup = '/img.jpg link="https://example.com" archive="none"'
      expect(analyzer.analyze("polaroid", markup)).to be_nil
    end

    it "A8: skips relative or archive.org targets" do
      expect(analyzer.analyze("linkcard", "/relative/path Title")).to be_nil
      expect(analyzer.analyze("linkcard", "https://archive.org/details/foo")).to be_nil
      expect(analyzer.analyze("polaroid",
                              '/img.jpg link="https://web.archive.org/web/2020/https://example.com"')).to be_nil
    end

    it "A9: skips URLs matching site highlight_cards.noarchive" do
      site = instance_double(
        Jekyll::Site,
        config: { "highlight_cards" => { "noarchive" => ["x\\.com"] } }
      )
      analyzer = described_class.new(site: site)

      expect(analyzer.analyze("linkcard", "https://x.com/foo Title")).to be_nil
    end

    it "A10: freezes linkcard URLs with outer quotes" do
      result = analyzer.analyze("linkcard", '"https://example.com" Title')
      expect(result).to eq(target_url: "https://example.com")
    end
  end
end
