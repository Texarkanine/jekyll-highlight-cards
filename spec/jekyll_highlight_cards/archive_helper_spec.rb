# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::ArchiveHelper do
  let(:helper) do
    Class.new do
      include JekyllHighlightCards::ArchiveHelper
      include JekyllHighlightCards::ExpressionEvaluator
    end.new
  end

  let(:test_url) { "https://example.com/page" }
  let(:archive_url) { "https://web.archive.org/web/20231201120000/https://example.com/page" }

  before do
    described_class.archive_cache = {}
    described_class.noarchive_regexp_cache = {}
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

  describe "#lookup_archive" do
    before do
      allow(Net::HTTP).to receive(:start).and_call_original
      allow(Net::HTTP::Get).to receive(:new).and_call_original
    end

    it "returns the archive URL from CDX API results" do
      cdx_response_body = [
        %w[timestamp original],
        ["20231201120000", test_url]
      ].to_json

      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(status: 200, body: cdx_response_body, headers: { "Content-Type" => "application/json" })

      expect(helper.archive_url_for(test_url)).to eq(archive_url)
    end

    it "uses the latest timestamp when multiple snapshots exist" do
      cdx_response_body = [
        %w[timestamp original],
        ["20231201110000", test_url],
        ["20231201130000", test_url]
      ].to_json

      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(status: 200, body: cdx_response_body)

      expect(helper.archive_url_for(test_url)).to eq(
        "https://web.archive.org/web/20231201130000/https://example.com/page"
      )
    end

    it "returns nil when CDX response has only the header row" do
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(status: 200, body: [%w[timestamp original]].to_json)

      expect(helper.archive_url_for(test_url)).to be_nil
    end

    it "returns nil when CDX response is not successful" do
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(status: 500, body: "Internal Server Error")

      expect(helper.archive_url_for(test_url)).to be_nil
    end

    it "returns nil when CDX response is not successful even with a JSON body" do
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 404,
          body: [%w[timestamp original], ["20231201120000", test_url]].to_json
        )

      expect(helper.archive_url_for(test_url)).to be_nil
    end

    it "returns nil when CDX lookup raises a network error" do
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect(helper.archive_url_for(test_url)).to be_nil
    end

    it "returns nil when CDX response body is invalid JSON" do
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(status: 200, body: "not-json")

      expect(helper.archive_url_for(test_url)).to be_nil
    end

    # Net::HTTP connection kwargs are not observable via WebMock response stubs;
    # these examples are the mutation-kill surface for host/port/ssl/timeouts/path.
    it "connects to web.archive.org over HTTPS with timeouts" do
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", test_url]].to_json
        )

      helper.archive_url_for(test_url)

      expect(Net::HTTP).to have_received(:start).with(
        "web.archive.org",
        443,
        hash_including(use_ssl: true, open_timeout: 10, read_timeout: 30)
      )
    end

    it "requests the CDX path from the parsed CDX URL" do
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", test_url]].to_json
        )

      helper.archive_url_for(test_url)

      expect(Net::HTTP::Get).to have_received(:new).with(
        a_string_starting_with("/cdx/search/cdx?url=")
      )
    end

    it "requests the CDX endpoint with encoded URL query parameters" do
      special_url = "https://example.com/page?param=value&other=test"

      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .with(query: hash_including("url" => special_url))
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", special_url]].to_json
        )

      result = helper.archive_url_for(special_url)
      expect(result).to include(special_url)
    end
  end

  describe "#submit_archive" do
    before do
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = "1"
      allow(Net::HTTP).to receive(:start).and_call_original
      allow(Net::HTTP::Get).to receive(:new).and_call_original

      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(status: 200, body: [%w[timestamp original]].to_json)
    end

    it "returns the archive URL from the Content-Location header" do
      stub_request(:get, %r{web\.archive\.org/save/})
        .to_return(
          status: 200,
          headers: { "Content-Location" => "/web/20231201130000/https://example.com/page" }
        )

      expect(helper.archive_url_for(test_url)).to eq(
        "https://web.archive.org/web/20231201130000/https://example.com/page"
      )
    end

    it "returns nil when Content-Location is absent" do
      stub_request(:get, %r{web\.archive\.org/save/})
        .to_return(status: 200, headers: {})

      expect(helper.archive_url_for(test_url)).to be_nil
    end

    it "returns nil when Content-Location is empty" do
      stub_request(:get, %r{web\.archive\.org/save/})
        .to_return(status: 200, headers: { "Content-Location" => "" })

      expect(helper.archive_url_for(test_url)).to be_nil
    end

    it "sends the configured User-Agent header" do
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_UA"] = "CustomBot/1.0"

      stub_request(:get, %r{web\.archive\.org/save/})
        .with(headers: { "User-Agent" => "CustomBot/1.0" })
        .to_return(
          status: 200,
          headers: { "Content-Location" => "/web/20231201130000/https://example.com/page" }
        )

      expect(helper.archive_url_for(test_url)).to include("web.archive.org/web/")
      expect(WebMock).to have_requested(:get, %r{web\.archive\.org/save/})
        .with(headers: { "User-Agent" => "CustomBot/1.0" })
    end

    it "encodes the URL in the save request path" do
      special_url = "https://example.com/page?param=value&other=test"
      encoded = URI.encode_www_form_component(special_url)

      stub_request(:get, "https://web.archive.org/save/#{encoded}")
        .to_return(
          status: 200,
          headers: { "Content-Location" => "/web/20231201130000/#{special_url}" }
        )

      expect(helper.archive_url_for(special_url)).to include("web.archive.org/web/")
      expect(WebMock).to have_requested(:get, "https://web.archive.org/save/#{encoded}")
    end

    # See lookup_archive: Net::HTTP kwargs/path are mutation-kill only via collaborator spies.
    it "requests the save path from the parsed save URL" do
      stub_request(:get, %r{web\.archive\.org/save/})
        .to_return(
          status: 200,
          headers: { "Content-Location" => "/web/20231201130000/https://example.com/page" }
        )

      helper.archive_url_for(test_url)

      expect(Net::HTTP::Get).to have_received(:new).with(
        a_string_starting_with("/save/"),
        { "User-Agent" => helper.archive_user_agent }
      )
    end

    it "connects to web.archive.org over HTTPS with timeouts" do
      stub_request(:get, %r{web\.archive\.org/save/})
        .to_return(
          status: 200,
          headers: { "Content-Location" => "/web/20231201130000/https://example.com/page" }
        )

      helper.archive_url_for(test_url)

      expect(Net::HTTP).to have_received(:start).with(
        "web.archive.org",
        443,
        hash_including(use_ssl: true, open_timeout: 10, read_timeout: 30)
      ).twice
    end

    it "returns nil when submission raises a network error" do
      stub_request(:get, %r{web\.archive\.org/save/})
        .to_raise(SocketError.new("Failed to open TCP connection"))

      expect(helper.archive_url_for(test_url)).to be_nil
    end

    it "does not submit when CDX already found a snapshot" do
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", test_url]].to_json
        )

      stub_request(:get, %r{web\.archive\.org/save/})

      expect(helper.archive_url_for(test_url)).to eq(archive_url)
      expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/save/})
    end
  end

  describe "#archive_url_for" do
    before do
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", test_url]].to_json
        )
    end

    it "returns the archive URL" do
      expect(helper.archive_url_for(test_url)).to eq(archive_url)
    end

    it "caches the result for repeated lookups of the same URL" do
      helper.archive_url_for(test_url)
      helper.archive_url_for(test_url)

      expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx}).once
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

      expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx}).once
    end

    it "caches different URLs separately" do
      url1 = "https://example.com/page1"
      url2 = "https://example.com/page2"

      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx\?.*#{Regexp.escape(url1)}.*})
        .to_return(status: 200, body: [%w[timestamp original], ["20231201120000", url1]].to_json)
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx\?.*#{Regexp.escape(url2)}.*})
        .to_return(status: 200, body: [%w[timestamp original], ["20231201120000", url2]].to_json)

      helper.archive_url_for(url1)
      helper.archive_url_for(url2)

      expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx}).twice
    end

    it "returns nil when lookup raises an error" do
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_raise(StandardError.new("unexpected failure"))

      expect(helper.archive_url_for(test_url)).to be_nil
    end

    context "when SavePageNow is enabled and CDX finds a snapshot" do
      before do
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = "1"

        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_return(
            status: 200,
            body: [%w[timestamp original], ["20231201120000", test_url]].to_json
          )

        stub_request(:get, %r{web\.archive\.org/save/})
      end

      it "returns the CDX snapshot without calling SavePageNow" do
        expect(helper.archive_url_for(test_url)).to eq(archive_url)
        expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/save/})
      end
    end

    context "when SavePageNow is enabled and CDX finds no snapshot" do
      before do
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = "1"

        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_return(status: 200, body: [%w[timestamp original]].to_json)

        save_pattern = %r{
          web\.archive\.org/save/#{Regexp.escape(test_url)}|
          web\.archive\.org/save/https%3A%2F%2Fexample.com%2Fpage
        }x
        stub_request(:get, save_pattern)
          .to_return(
            status: 200,
            headers: { "Content-Location" => "/web/20231201130000/https://example.com/page" }
          )
      end

      it "submits the original URL to SavePageNow" do
        helper.archive_url_for(test_url)

        expect(WebMock).to have_requested(:get, %r{web\.archive\.org/save/https:%2F%2Fexample\.com%2Fpage})
      end

      it "makes both CDX and SavePageNow requests" do
        helper.archive_url_for(test_url)

        expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx}).once
        expect(WebMock).to have_requested(:get, %r{web\.archive\.org/save/}).once
      end

      it "returns nil when SavePageNow fails after a CDX miss" do
        stub_request(:get, %r{web\.archive\.org/save/})
          .to_return(status: 500, body: "Internal Server Error")

        expect(helper.archive_url_for(test_url)).to be_nil
      end
    end

    # Guard A/B: skip non-archivable URLs (relative paths, non-http, archive.org hosts)
    # without CDX or SavePageNow calls.
    context "when the URL is not archiveable" do
      before do
        ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = "1"
        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        stub_request(:get, %r{web\.archive\.org/save/})
      end

      shared_examples "skips without archive HTTP" do |url|
        it "returns nil and makes no archive requests for #{url.inspect}" do
          expect(helper.archive_url_for(url)).to be_nil
          expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx})
          expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/save/})
        end
      end

      it_behaves_like "skips without archive HTTP", "photo.jpg"
      it_behaves_like "skips without archive HTTP", "./img/x.png"
      it_behaves_like "skips without archive HTTP", "/assets/x.png"
      it_behaves_like "skips without archive HTTP", "ftp://example.com/a"
      it_behaves_like "skips without archive HTTP", ""
      it_behaves_like "skips without archive HTTP",
                      "https://web.archive.org/web/20030101000000/http://example.com/"
      it_behaves_like "skips without archive HTTP", "https://archive.org/details/foo"
      it_behaves_like "skips without archive HTTP", "http://["
    end

    # highlight_cards.noarchive: site-config regexes skip archive attempts
    context "when site configures highlight_cards.noarchive" do
      def site_with(config)
        instance_double(Jekyll::Site, config: config)
      end

      before do
        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_return(
            status: 200,
            body: [%w[timestamp original], ["20231201120000", test_url]].to_json
          )
        stub_request(:get, %r{web\.archive\.org/save/})
      end

      it "skips URLs matching a noarchive pattern" do
        site = site_with("highlight_cards" => { "noarchive" => ["x\\.com"] })
        blocked = "https://x.com/someone/status/1"

        expect(helper.archive_url_for(blocked, site: site)).to be_nil
        expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx})
        expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/save/})
      end

      it "looks up URLs that do not match any noarchive pattern" do
        site = site_with("highlight_cards" => { "noarchive" => ["x\\.com"] })

        expect(helper.archive_url_for(test_url, site: site)).to eq(archive_url)
        expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx})
      end

      it "does not skip when noarchive is empty" do
        site = site_with("highlight_cards" => { "noarchive" => [] })

        expect(helper.archive_url_for(test_url, site: site)).to eq(archive_url)
      end

      it "does not skip when highlight_cards is absent" do
        site = site_with({})

        expect(helper.archive_url_for(test_url, site: site)).to eq(archive_url)
      end

      it "skips when any of multiple patterns matches" do
        site = site_with(
          "highlight_cards" => { "noarchive" => ["example\\.org", "x\\.com"] }
        )
        blocked = "https://x.com/foo"

        expect(helper.archive_url_for(blocked, site: site)).to be_nil
        expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx})
      end

      it "raises on an invalid noarchive regex" do
        site = site_with("highlight_cards" => { "noarchive" => ["["] })

        expect { helper.archive_url_for(test_url, site: site) }.to raise_error(RegexpError)
      end
    end
  end
end
