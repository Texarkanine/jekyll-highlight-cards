# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::ArchiveHelper do
  # Create a test class that includes the module and ExpressionEvaluator for logging
  let(:helper) do
    Class.new do
      include JekyllHighlightCards::ArchiveHelper
      include JekyllHighlightCards::ExpressionEvaluator
    end.new
  end

  let(:test_url) { "https://example.com/page" }
  let(:archive_url) { "https://web.archive.org/web/20231201120000/https://example.com/page" }

  before do
    # Clear the cache before each test
    described_class.class_variable_set(:@@archive_cache, {})

    # Reset environment variables
    ENV.delete("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE")
    ENV.delete("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE")
    ENV.delete("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_UA")
    ENV.delete("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_CONTACT")
  end

  describe "#archive_enabled?" do
    it "returns true when JEKYLL_HIGHLIGHT_CARDS_ARCHIVE is 1" do
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE"] = "1"
      expect(helper.archive_enabled?).to be true
    end

    it "returns false when JEKYLL_HIGHLIGHT_CARDS_ARCHIVE is not set" do
      expect(helper.archive_enabled?).to be false
    end

    it "returns true when archive save is enabled" do
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = "1"
      expect(helper.archive_enabled?).to be true
    end
  end

  describe "#archive_save_enabled?" do
    it "returns true when JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE is 1" do
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = "1"
      expect(helper.archive_save_enabled?).to be true
    end

    it "returns false when JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE is not set" do
      expect(helper.archive_save_enabled?).to be false
    end

    it "returns false when JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE is 0" do
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = "0"
      expect(helper.archive_save_enabled?).to be false
    end
  end

  describe "#archive_user_agent" do
    it "returns custom user agent when JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_UA is set" do
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_UA"] = "CustomBot/1.0"
      expect(helper.archive_user_agent).to eq("CustomBot/1.0")
    end

    it "returns default user agent with contact info" do
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_CONTACT"] = "mailto:test@example.com"
      expect(helper.archive_user_agent).to eq("jekyll:highlight-cards (+mailto:test@example.com)")
    end

    it "returns default user agent without contact info" do
      expect(helper.archive_user_agent).to eq("jekyll:highlight-cards (+mailto:unknown)")
    end
  end

  describe "#archive_url_for" do
    context "when archive is found via CDX lookup" do
      before do
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE"] = "1"

        # Mock CDX API response
        cdx_response_body = [
          %w[timestamp original],
          ["20231201120000", test_url]
        ].to_json

        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_return(status: 200, body: cdx_response_body, headers: { "Content-Type" => "application/json" })
      end

      it "returns the archive URL" do
        result = helper.archive_url_for(test_url)
        expect(result).to eq(archive_url)
      end

      it "caches the result" do
        helper.archive_url_for(test_url)
        helper.archive_url_for(test_url)

        # Should only make one request due to caching
        expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx}).once
      end
    end

    context "when archive is not found" do
      before do
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE"] = "1"

        # Mock CDX API response with only header
        cdx_response_body = [%w[timestamp original]].to_json

        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_return(status: 200, body: cdx_response_body, headers: { "Content-Type" => "application/json" })
      end

      it "returns nil" do
        result = helper.archive_url_for(test_url)
        expect(result).to be_nil
      end
    end

    context "when SavePageNow is enabled" do
      before do
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE"] = "1"
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = "1"

        # Mock CDX API (no result)
        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_return(status: 200, body: [%w[timestamp original]].to_json)

        # Mock SavePageNow API
        stub_request(:get, %r{web\.archive\.org/save/})
          .to_return(
            status: 200,
            headers: { "Content-Location" => "/web/20231201130000/https://example.com/page" }
          )
      end

      it "submits to SavePageNow and returns the archive URL" do
        result = helper.archive_url_for(test_url)
        expect(result).to eq("https://web.archive.org/web/20231201130000/https://example.com/page")
      end

      it "makes both CDX and SavePageNow requests" do
        helper.archive_url_for(test_url)

        expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx}).once
        expect(WebMock).to have_requested(:get, %r{web\.archive\.org/save/}).once
      end
    end

    context "when CDX lookup fails" do
      before do
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE"] = "1"

        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "returns nil" do
        result = helper.archive_url_for(test_url)
        expect(result).to be_nil
      end

      it "does not raise an exception" do
        expect { helper.archive_url_for(test_url) }.not_to raise_error
      end
    end

    context "when SavePageNow submission fails" do
      before do
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE"] = "1"
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = "1"

        # Mock CDX API (found result)
        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_return(status: 200, body: [%w[timestamp original], ["20231201120000", test_url]].to_json)

        # Mock SavePageNow API (fails)
        stub_request(:get, %r{web\.archive\.org/save/})
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "returns the CDX lookup result" do
        result = helper.archive_url_for(test_url)
        expect(result).to eq(archive_url)
      end
    end

    context "when network error occurs" do
      before do
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE"] = "1"

        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_raise(SocketError.new("Failed to open TCP connection"))
      end

      it "returns nil" do
        result = helper.archive_url_for(test_url)
        expect(result).to be_nil
      end

      it "does not raise an exception" do
        expect { helper.archive_url_for(test_url) }.not_to raise_error
      end
    end
  end

  describe "cache behavior" do
    before do
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE"] = "1"

      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(status: 200, body: [%w[timestamp original], ["20231201120000", test_url]].to_json)
    end

    it "caches results across multiple helper instances" do
      helper1 = Class.new do
        include JekyllHighlightCards::ArchiveHelper
        include JekyllHighlightCards::ExpressionEvaluator
      end.new

      helper2 = Class.new do
        include JekyllHighlightCards::ArchiveHelper
        include JekyllHighlightCards::ExpressionEvaluator
      end.new

      helper1.archive_url_for(test_url)
      helper2.archive_url_for(test_url)

      # Should only make one request due to shared cache
      expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx}).once
    end

    it "caches different URLs separately" do
      url1 = "https://example.com/page1"
      url2 = "https://example.com/page2"

      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(status: 200, body: [%w[timestamp original], ["20231201120000", url1]].to_json)

      helper.archive_url_for(url1)
      helper.archive_url_for(url2)

      # Should make two requests for different URLs
      expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx}).twice
    end
  end

  describe "URL encoding" do
    before do
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE"] = "1"
    end

    it "properly encodes URLs with special characters" do
      special_url = "https://example.com/page?param=value&other=test"

      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .with(query: hash_including("url" => special_url))
        .to_return(status: 200, body: [%w[timestamp original], ["20231201120000", special_url]].to_json)

      result = helper.archive_url_for(special_url)
      expect(result).to include(special_url)
    end
  end
end
