# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::PolaroidTag do
  let(:site) { instance_double("Jekyll::Site", source: "/test/site") }
  let(:registers) { { site: site } }
  let(:context) { Liquid::Context.new({}, {}, registers) }

  # Clear archive cache before each test to ensure isolation
  before do
    JekyllHighlightCards::ArchiveHelper.class_variable_set(:@@archive_cache, {})
    allow(ENV).to receive(:[]).and_call_original
    # Stub archive lookups by default (archiving disabled)
    stub_request(:get, %r{web\.archive\.org/cdx/search/cdx}).to_return(status: 404)
  end

  # Helper to render a tag
  def render_tag(markup)
    tag = Liquid::Template.parse("{% polaroid #{markup} %}").root.nodelist.first
    tag.render(context)
  end

  describe "basic usage" do
    context "with image URL only" do
      it "renders the image" do
        result = render_tag("/assets/photo.jpg")
        expect(result).to include("/assets/photo.jpg")
        expect(result).to include("<img")
      end

      it "links image to itself" do
        result = render_tag("/assets/photo.jpg")
        expect(result).to include('href="/assets/photo.jpg"')
      end

      it "does not display image path as link text" do
        result = render_tag("/assets/photo.jpg")
        # Should not show the image filename as visible link text
        expect(result).not_to match(/>\/assets\/photo\.jpg</i)
        expect(result).not_to match(/>assets\/photo\.jpg</i)
      end
    end

    context "with image and size" do
      it "applies width and height" do
        result = render_tag('/assets/photo.jpg size=300x200')
        expect(result).to include('width="300"')
        expect(result).to include('height="200"')
      end
    end

    context "with image and title" do
      it "renders title" do
        result = render_tag('/assets/photo.jpg title="My Photo"')
        expect(result).to include("My Photo")
      end
    end

    context "with image and link" do
      it "links to specified URL" do
        result = render_tag('/assets/photo.jpg link="https://example.com"')
        expect(result).to include('href="https://example.com"')
      end

      it "displays link URL" do
        result = render_tag('/assets/photo.jpg link="https://example.com"')
        expect(result).to include("example.com")
      end
    end

    context "with all parameters" do
      it "renders complete polaroid" do
        result = render_tag('/assets/photo.jpg size=300x200 title="Photo" link="https://example.com" archive="none"')
        expect(result).to include("/assets/photo.jpg")
        expect(result).to include("Photo")
        expect(result).to include("example.com")
        expect(result).to include('width="300"')
        expect(result).to include('height="200"')
        # Should not include actual archive URL link
        expect(result).not_to include("web.archive.org")
      end
    end
  end

  describe "size parameter" do
    context "with WIDTHxHEIGHT format" do
      it "applies both dimensions" do
        result = render_tag('/photo.jpg size=300x200')
        expect(result).to include('width="300"')
        expect(result).to include('height="200"')
      end
    end

    context "with WIDTHx format" do
      it "applies width only" do
        result = render_tag('/photo.jpg size=300x')
        expect(result).to include('width="300"')
        expect(result).not_to include('height=')
      end
    end

    context "with xHEIGHT format" do
      it "applies height only" do
        result = render_tag('/photo.jpg size=x200')
        expect(result).not_to include('width=')
        expect(result).to include('height="200"')
      end
    end

    context "with WIDTH format" do
      it "applies width only" do
        result = render_tag('/photo.jpg size=400')
        expect(result).to include('width="400"')
        expect(result).not_to include('height=')
      end
    end

    context "with units" do
      it "handles px units with xx separator" do
        result = render_tag('/photo.jpg size=400pxx300px')
        expect(result).to include('width="400px"')
        expect(result).to include('height="300px"')
      end

      it "handles percentage values" do
        result = render_tag('/photo.jpg size=50%')
        expect(result).to include('width="50%"')
      end
    end
  end

  describe "alt attribute" do
    context "with alt parameter provided" do
      it "uses alt text for img alt attribute" do
        result = render_tag('/photo.jpg alt="Description for screen readers"')
        expect(result).to include('alt="Description for screen readers"')
      end

      it "uses alt even when title is also provided" do
        result = render_tag('/photo.jpg alt="Alt text" title="Title text"')
        expect(result).to include('alt="Alt text"')
        expect(result).not_to include('alt="Title text"')
      end
    end

    context "without alt parameter" do
      it "uses title as alt fallback" do
        result = render_tag('/photo.jpg title="My Photo"')
        expect(result).to include('alt="My Photo"')
      end

      it "has empty alt when neither alt nor title provided" do
        result = render_tag('/photo.jpg')
        expect(result).to include('alt=""')
      end
    end

    context "with HTML in alt text" do
      it "escapes HTML in alt attribute" do
        result = render_tag('/photo.jpg alt="Text with <script>alert(\'xss\')</script>"')
        expect(result).to include('alt="Text with &lt;script&gt;')
        expect(result).not_to include('<script>')
      end
    end
  end

  describe "archive functionality" do
    context "with archive opt-out" do
      it "does not include archive link" do
        result = render_tag('/photo.jpg link="https://example.com" archive="none"')
        # Should not include actual archive URL
        expect(result).not_to include("web.archive.org")
      end
    end

    context "with explicit archive URL" do
      it "uses the provided archive URL" do
        result = render_tag('/photo.jpg link="https://example.com" archive="https://archive.org/123"')
        expect(result).to include("archive.org/123")
      end
    end

    context "with automatic archive lookup" do
      before do
        allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
        stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
          .to_return(status: 200, body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json, headers: { "Content-Type" => "application/json" })
      end

      it "archives the link URL not the image URL" do
        result = render_tag('/photo.jpg link="https://example.com"')
        expect(result).to include("web.archive.org")
        expect(result).to include("20231201120000")
      end
    end
  end

  describe "Liquid expression evaluation" do
    before do
      context.environments.first["page"] = {
        "image" => "/assets/photo.jpg",
        "title" => "My Photo",
        "link" => "https://example.com"
      }
    end

    context "with variable for image URL" do
      it "evaluates the variable" do
        result = render_tag("{{ page.image }}")
        expect(result).to include("/assets/photo.jpg")
      end
    end

    context "with variable for title" do
      it "evaluates the variable" do
        result = render_tag('/photo.jpg title={{ page.title }}')
        expect(result).to include("My Photo")
      end
    end

    context "with multiple variables" do
      it "evaluates all variables" do
        result = render_tag('{{ page.image }} title={{ page.title }} link={{ page.link }}')
        expect(result).to include("/assets/photo.jpg")
        expect(result).to include("My Photo")
        expect(result).to include("example.com")
      end
    end
  end

  describe "HTML escaping" do
    it "escapes HTML in image URL" do
      result = render_tag('/photo.jpg?param=<script>')
      expect(result).to include("&lt;script&gt;")
      expect(result).not_to include("<script>")
    end

    it "escapes HTML in title" do
      result = render_tag('/photo.jpg title="Title <b>bold</b>"')
      expect(result).to include("&lt;b&gt;")
      expect(result).not_to include("<b>bold</b>")
    end

    it "escapes HTML in link URL" do
      result = render_tag('/photo.jpg link="https://example.com?x=<script>"')
      expect(result).to include("&lt;script&gt;")
    end
  end

  describe "error handling" do
    context "when image URL is missing" do
      it "raises an error" do
        expect { render_tag("") }.to raise_error(ArgumentError, /requires.*image/)
      end
    end

    context "when template is not found" do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "raises an error" do
        expect { render_tag("/photo.jpg") }.to raise_error(/Template not found/)
      end
    end
  end

  describe "edge cases" do
    it "handles empty title gracefully" do
      result = render_tag('/photo.jpg title=""')
      expect(result).to include("/photo.jpg")
      # Should render without errors
    end

    it "handles empty link gracefully" do
      result = render_tag('/photo.jpg link=""')
      expect(result).to include("/photo.jpg")
      # Should render without errors
    end

    it "does not show link display when no explicit link provided" do
      result = render_tag('/photo.jpg')
      # Link section should show &nbsp; not the image path
      expect(result).to include('<div class="polaroid-link">')
      expect(result).to match(/polaroid-link[^>]*>\s*&nbsp;/i)
    end

    it "shows link display only when explicit link provided" do
      result = render_tag('/photo.jpg link="https://example.com"')
      expect(result).to include("example.com")
      expect(result).not_to include("photo.jpg")
    end

    it "handles multiline markup" do
      result = render_tag("/photo.jpg\nsize=300x200\ntitle=\"Test\"")
      expect(result).to include("/photo.jpg")
      expect(result).to include("Test")
      expect(result).to include('width="300"')
    end
  end
end

