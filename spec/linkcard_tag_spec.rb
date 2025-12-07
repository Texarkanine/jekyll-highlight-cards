# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::LinkcardTag do
  let(:site) { instance_double("Jekyll::Site", source: "/test/site") }
  let(:registers) { { site: site } }
  let(:context) { Liquid::Context.new({}, {}, registers) }
  let(:template_path) { File.expand_path("../../_includes/highlight-cards/linkcard.html", __dir__) }

  # Clear archive cache and ENV before each test to ensure isolation
  before do
    JekyllHighlightCards::ArchiveHelper.class_variable_set(:@@archive_cache, {})
    allow(ENV).to receive(:[]).and_call_original
    # Stub any potential archive lookups with empty response (archiving disabled by default)
    stub_request(:get, %r{web\.archive\.org/cdx/search/cdx}).to_return(status: 404)
  end

  # Helper to render a tag
  def render_tag(markup)
    tag = Liquid::Template.parse("{% linkcard #{markup} %}").root.nodelist.first
    tag.render(context)
  end

  describe "basic usage" do
    context "with URL only" do
      it "renders the URL" do
        result = render_tag("https://example.com")
        expect(result).to include("https://example.com")
        expect(result).to include("example.com")
      end

      it "does not include a title" do
        result = render_tag("https://example.com")
        expect(result).not_to include("<h1>")
      end
    end

    context "with URL and title" do
      it "renders both URL and title" do
        result = render_tag('https://example.com "My Title"')
        expect(result).to include("My Title")
        expect(result).to include("example.com")
      end
    end

    context "with URL, title, and explicit archive" do
      it "renders URL, title, and archive" do
        result = render_tag('https://example.com "Title" archive:https://archive.org/123')
        expect(result).to include("example.com")
        expect(result).to include("Title")
        expect(result).to include("archive.org/123")
        expect(result).to include("archive")
      end
    end
  end

  describe "archive functionality" do
    context "with archive opt-out" do
      it "does not include archive link when archive:none" do
        result = render_tag("https://example.com archive:none")
        expect(result).not_to include("archive")
      end
    end

    context "with automatic archive lookup" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_return(status: 200, body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json, headers: { "Content-Type" => "application/json" })
      end

      it "includes archive link when found" do
        result = render_tag("https://example.com")
        expect(result).to include("web.archive.org/web/20231201120000")
        expect(result).to include("archive")
      end

      it "caches the archive URL" do
        render_tag("https://example.com")
        # Second call should use cache, not make another HTTP request
        expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx}).once
        render_tag("https://example.com")
      end
    end

    context "when archive lookup fails" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx}).to_return(status: 404)
      end

      it "renders without archive link" do
        result = render_tag("https://example.com")
        expect(result).not_to include("archive")
      end

      it "does not raise an error" do
        expect { render_tag("https://example.com") }.not_to raise_error
      end
    end
  end

  describe "Liquid expression evaluation" do
    before do
      context.environments.first["page"] = {
        "url" => "https://example.com/page",
        "title" => "My Page Title"
      }
    end

    context "with variable for URL" do
      it "evaluates the URL variable" do
        result = render_tag("{{ page.url }}")
        expect(result).to include("https://example.com/page")
      end
    end

    context "with variable for title" do
      it "evaluates the title variable" do
        result = render_tag('https://example.com {{ page.title }}')
        expect(result).to include("My Page Title")
      end
    end

    context "with both URL and title as variables" do
      it "evaluates both variables" do
        result = render_tag("{{ page.url }} {{ page.title }}")
        expect(result).to include("https://example.com/page")
        expect(result).to include("My Page Title")
      end
    end
  end

  describe "URL display" do
    it "strips protocol from display" do
      result = render_tag("https://example.com/path")
      expect(result).to include("example.com/path")
    end
  end

  describe "HTML escaping" do
    it "escapes HTML in URL" do
      result = render_tag('https://example.com?a=<script>alert(1)</script>')
      expect(result).to include("&lt;script&gt;")
      expect(result).not_to include("<script>alert(1)</script>")
    end

    it "escapes HTML in title" do
      result = render_tag('https://example.com "Title <b>bold</b>"')
      expect(result).to include("&lt;b&gt;")
      expect(result).not_to include("<b>bold</b>")
    end

    it "escapes HTML in archive URL" do
      result = render_tag('https://example.com archive:https://archive.org/<script>')
      expect(result).to include("&lt;script&gt;")
    end

    it "prevents XSS attacks" do
      result = render_tag('https://example.com "Title <script>alert(1)</script>" archive:none')
      expect(result).not_to include("<script>alert(1)</script>")
      expect(result).to include("&lt;script&gt;")
    end
  end

  describe "error handling" do
    context "when URL is missing" do
      it "raises an error" do
        expect { render_tag("") }.to raise_error(ArgumentError, /requires a URL/)
      end
    end

    context "when URL is empty" do
      it "raises an error" do
        expect { render_tag("   ") }.to raise_error(ArgumentError, /requires a URL/)
      end
    end

    context "when template is not found" do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "raises an error" do
        expect { render_tag("https://example.com") }.to raise_error(/Template not found/)
      end
    end
  end

  describe "parameter parsing" do
    it "handles quoted titles with spaces" do
      result = render_tag('https://example.com "This is a long title"')
      expect(result).to include("This is a long title")
    end

    it "handles archive parameter in any position" do
      result1 = render_tag('https://example.com "Title" archive:https://archive.org/123')
      result2 = render_tag('https://example.com archive:https://archive.org/123 "Title"')
      expect(result1).to include("archive.org/123")
      expect(result1).to include("Title")
      expect(result2).to include("archive.org/123")
      expect(result2).to include("Title")
    end
  end
end

