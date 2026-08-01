# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::PolaroidTag do
  let(:site) { instance_double(Jekyll::Site, source: "/test/site") }
  let(:registers) { { site: site } }
  let(:context) { Liquid::Context.new({}, {}, registers) }

  before do
    JekyllHighlightCards::ArchiveHelper.archive_cache = {}
    allow(ENV).to receive(:[]).and_call_original
    stub_request(:get, %r{web\.archive\.org/cdx/search/cdx}).to_return(status: 404)
  end

  def render_tag(markup)
    tag = Liquid::Template.parse("{% polaroid #{markup} %}").root.nodelist.first
    tag.render(context)
  end

  def with_custom_polaroid_template(site_source, template_html)
    includes = File.join(site_source, "_includes", "highlight-cards")
    FileUtils.mkdir_p(includes)
    File.write(File.join(includes, "polaroid.html"), template_html)
    allow(site).to receive(:source).and_return(site_source)
    yield
  ensure
    FileUtils.rm_rf(site_source)
  end

  describe "#initialize" do
    it "sets tag name via Liquid::Tag initialization" do
      tag = Liquid::Template.parse("{% polaroid /photo.jpg %}").root.nodelist.first
      expect(tag.tag_name).to eq("polaroid")
    end
  end

  describe "#render" do
    describe "basic usage" do
      context "with image URL only" do
        it "renders the image" do
          result = render_tag("/assets/photo.jpg")
          expect(result).to include('src="/assets/photo.jpg"')
          expect(result).to include("<img")
        end

        it "links image to itself" do
          result = render_tag("/assets/photo.jpg")
          expect(result).to include('href="/assets/photo.jpg"')
        end

        it "does not display image path as link text" do
          result = render_tag("/assets/photo.jpg")
          expect(result).not_to match(%r{>/assets/photo\.jpg<}i)
          expect(result).not_to match(%r{>assets/photo\.jpg<}i)
        end
      end

      context "with image and size" do
        it "applies width and height" do
          result = render_tag("/assets/photo.jpg size=300x200")
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
          expect(result).not_to include("web.archive.org")
        end
      end
    end

    describe "size parameter" do
      context "with WIDTHxHEIGHT format" do
        it "applies both dimensions" do
          result = render_tag("/photo.jpg size=300x200")
          expect(result).to include('width="300"')
          expect(result).to include('height="200"')
        end
      end

      context "with WIDTHx format" do
        it "applies width only" do
          result = render_tag("/photo.jpg size=300x")
          expect(result).to include('width="300"')
          expect(result).not_to include("height=")
        end
      end

      context "with xHEIGHT format" do
        it "applies height only" do
          result = render_tag("/photo.jpg size=x200")
          expect(result).not_to include("width=")
          expect(result).to include('height="200"')
        end
      end

      context "with WIDTH format" do
        it "applies width only" do
          result = render_tag("/photo.jpg size=400")
          expect(result).to include('width="400"')
          expect(result).not_to include("height=")
        end
      end

      context "with units" do
        it "handles px units with xx separator" do
          result = render_tag("/photo.jpg size=400pxx300px")
          expect(result).to include('width="400px"')
          expect(result).to include('height="300px"')
        end

        it "handles percentage values" do
          result = render_tag("/photo.jpg size=50%")
          expect(result).to include('width="50%"')
        end
      end
    end

    describe "image_link parameter" do
      context "with image_link but no link parameter" do
        it "links image to image_link URL" do
          result = render_tag('/photo.jpg image_link="https://custom.com"')
          expect(result).to include('href="https://custom.com"')
        end

        it "does not display link text" do
          result = render_tag('/photo.jpg image_link="https://custom.com"')
          expect(result).to include('<div class="polaroid-link">')
          expect(result).to match(/polaroid-link[^>]*>\s*&nbsp;/i)
          expect(result).not_to match(%r{>custom\.com</a>}i)
        end
      end

      context "with both link and image_link parameters" do
        it "links image to image_link URL" do
          result = render_tag('/photo.jpg link="https://example.com" image_link="https://custom.com"')
          expect(result).to match(%r{<a href="https://custom\.com"[^>]*>\s*<img}i)
        end

        it "displays the link URL text" do
          result = render_tag('/photo.jpg link="https://example.com" image_link="https://custom.com"')
          expect(result).to include("example.com")
        end

        it "image href uses image_link not link parameter" do
          result = render_tag('/photo.jpg link="https://example.com" image_link="https://custom.com"')
          expect(result).to match(%r{<a href="https://custom\.com"[^>]*>\s*<img}i)
          expect(result).to match(%r{<a href="https://example\.com"[^>]*>example\.com</a>}i)
        end
      end

      context "with image_link containing special characters" do
        it "escapes HTML in image_link URL" do
          result = render_tag('/photo.jpg image_link="https://custom.com?x=<script>"')
          expect(result).to include("&lt;script&gt;")
          expect(result).not_to include("<script>")
        end
      end
    end

    describe "error handling" do
      context "when image URL is missing" do
        it "raises an error" do
          expect { render_tag("") }.to raise_error(ArgumentError, /requires.*image/)
        end
      end

      context "when image URL is empty" do
        it "raises an error for empty quoted URL" do
          expect { render_tag('""') }.to raise_error(ArgumentError, /requires.*image/)
        end

        it "raises an error for whitespace-only markup" do
          expect { render_tag("   ") }.to raise_error(ArgumentError, /requires.*image/)
        end
      end

      context "when template is not found" do
        before do
          allow(File).to receive(:exist?).and_return(false)
        end

        it "raises an error" do
          expect { render_tag("/photo.jpg") }.to raise_error(
            JekyllHighlightCards::TemplateNotFoundError,
            /Template not found/
          )
        end
      end
    end

    it "omits width and height when size is absent" do
      result = render_tag("/photo.jpg")
      expect(result).not_to include("width=")
      expect(result).not_to include("height=")
    end

    it "falls back to link_url when image_link is empty" do
      result = render_tag('/photo.jpg link="https://example.com" image_link=""')
      expect(result).to match(%r{<a href="https://example\.com"[^>]*>\s*<img}i)
    end

    it "defaults link_url to image_url when link is absent" do
      result = render_tag("/assets/photo.jpg")
      expect(result).to include('href="/assets/photo.jpg"')
    end

    it "evaluates liquid markup using the render context" do
      context.environments.first["page"] = { "image" => "/liquid-photo.jpg" }
      result = render_tag("{{ page.image }}")
      expect(result).to include("/liquid-photo.jpg")
    end

    it "adds target blank when image links to a different URL" do
      result = render_tag('/photo.jpg image_link="https://example.com"')
      expect(result).to include('target="_blank"')
    end

    it "omits target blank when image links to itself" do
      result = render_tag("/photo.jpg")
      expect(result).not_to include('target="_blank"')
    end

    it "shows an explicit archive URL in the rendered markup" do
      result = render_tag('/photo.jpg link="https://example.com" archive="https://archive.org/snap"')
      expect(result).to include("archive.org/snap")
    end

    it "passes parsed title into the rendered output" do
      result = render_tag('/photo.jpg title="Render Title"')
      expect(result).to match(/polaroid-title[^>]*>\s*Render Title\s*</i)
    end

    it "auto-archives the link URL when archiving is enabled" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20240101120000", "https://render-archive.example/"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = render_tag('/photo.jpg link="https://render-archive.example/"')
      expect(result).to include(
        "web.archive.org/web/20240101120000/https://render-archive.example/"
      )
    end

    it "shows visible link text only for explicit link parameters" do
      result = render_tag('/photo.jpg link="https://example.com"')
      expect(result).to match(%r{polaroid-link[^>]*>\s*<a[^>]*>example\.com</a>})
    end

    it "renders without archive when archiving is disabled" do
      result = render_tag('/photo.jpg link="https://example.com"')
      expect(result).not_to include("web.archive.org")
    end

    it "renders using the site register from context" do
      custom_dir = File.join("/tmp", "polaroid-site-#{Process.pid}")
      with_custom_polaroid_template(custom_dir, '<div class="custom-polaroid">{{ escaped_image_url }}</div>') do
        result = render_tag("/custom.jpg")
        expect(result).to include('class="custom-polaroid"')
        expect(result).to include("/custom.jpg")
      end
    end

    it "falls back to the gem template when site is absent from registers" do
      bare_context = Liquid::Context.new({}, {}, {})
      tag = Liquid::Template.parse("{% polaroid /photo.jpg %}").root.nodelist.first
      result = tag.render(bare_context)
      expect(result).to include('src="/photo.jpg"')
      expect(result).to include("polaroid-container")
    end

    it "passes alt text through to the img attribute" do
      result = render_tag('/photo.jpg alt="Screen reader alt"')
      expect(result).to include('alt="Screen reader alt"')
    end

    it "passes size dimensions through to width and height attributes" do
      result = render_tag("/photo.jpg size=111x222")
      expect(result).to include('width="111"')
      expect(result).to include('height="222"')
    end

    it "evaluates liquid archive URLs with the render context" do
      context.environments.first["page"] = { "archive" => "https://archive.org/from-liquid" }
      result = render_tag('/photo.jpg link="https://example.com" archive={{ page.archive }}')
      expect(result).to include("archive.org/from-liquid")
    end

    it "keeps distinct image, link, and image_link URLs in the markup" do
      result = render_tag(
        '/img-only.jpg link="https://link.example/path" image_link="https://image-link.example/i"'
      )
      expect(result).to include('src="/img-only.jpg"')
      expect(result).to match(%r{<a href="https://image-link\.example/i"[^>]*>\s*<img}i)
      expect(result).to match(%r{<a href="https://link\.example/path"[^>]*>link\.example/path</a>}i)
    end
  end

  describe "#parse_markup" do
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
          result = render_tag("/photo.jpg title={{ page.title }}")
          expect(result).to include("My Photo")
        end
      end

      context "with multiple variables" do
        it "evaluates all variables" do
          result = render_tag("{{ page.image }} title={{ page.title }} link={{ page.link }}")
          expect(result).to include("/assets/photo.jpg")
          expect(result).to include("My Photo")
          expect(result).to include("example.com")
        end
      end
    end

    describe "edge cases" do
      it "renders nbsp in link area when link is an empty string" do
        result = render_tag('/photo.jpg link=""')
        expect(result).to match(/polaroid-link[^>]*>\s*&nbsp;/)
      end

      it "handles multiline markup" do
        result = render_tag("/photo.jpg\nsize=300x200\ntitle=\"Test\"")
        expect(result).to include("/photo.jpg")
        expect(result).to include("Test")
        expect(result).to include('width="300"')
      end

      it "handles escaped quotes in title" do
        result = render_tag('/photo.jpg title="Photo with \\" quote"')
        expect(result).to include("Photo with &quot; quote")
      end

      it "handles escaped backslash in title" do
        result = render_tag('/photo.jpg title="Photo with \\\\ backslash"')
        expect(result).to include("Photo with \\ backslash")
      end

      it "handles complex escapes in title" do
        result = render_tag('/photo.jpg title="Complex: \\" and \\\\"')
        expect(result).to include("Complex: &quot; and \\")
      end
    end

    it "parses single-quoted parameter values" do
      result = render_tag("/photo.jpg title='Single Quoted'")
      expect(result).to include("Single Quoted")
    end

    it "ignores tokens that are not key=value pairs" do
      result = render_tag("/photo.jpg orphan size=300x200")
      expect(result).to include('width="300"')
      expect(result).not_to include("orphan")
    end

    it "preserves spaces inside quoted title values" do
      result = render_tag('/photo.jpg title="Photo With Spaces"')
      expect(result).to include("Photo With Spaces")
    end

    it "does not split on whitespace inside Liquid expressions" do
      context.environments.first["page"] = { "image" => "/img.jpg", "title" => "Liquid Title" }
      result = render_tag("{{ page.image }} title={{ page.title }}")
      expect(result).to include("/img.jpg")
      expect(result).to include("Liquid Title")
    end

    it "does not treat braces inside quotes as Liquid boundaries" do
      result = render_tag('/photo.jpg title="Not {{ liquid }}"')
      expect(result).to include("Not {{ liquid }}")
    end

    it "handles tab-separated parameters" do
      result = render_tag("/photo.jpg\tsize=300x200\ttitle=\"Tabbed\"")
      expect(result).to include('width="300"')
      expect(result).to include("Tabbed")
    end

    it "parses values containing equals signs" do
      result = render_tag('/photo.jpg link="https://example.com?a=1&b=2"')
      expect(result).to include("https://example.com?a=1&amp;b=2")
    end

    it "handles mixed single-quoted keys with double-quoted values" do
      result = render_tag("/photo.jpg title=\"Double\" alt='Single'")
      expect(result).to include("Double")
      expect(result).to include('alt="Single"')
    end

    it "tolerates repeated whitespace between parameters" do
      result = render_tag('/photo.jpg  size=300x200  title="Spaced"')
      expect(result).to include('width="300"')
      expect(result).to include("Spaced")
    end

    it "keeps liquid expressions intact when tokenizing" do
      context.environments.first["page"] = { "image" => "/liquid.jpg" }
      result = render_tag("{{ page.image }} size=100x100")
      expect(result).to include("/liquid.jpg")
      expect(result).to include('width="100"')
    end

    it "preserves backslash escapes inside quoted values" do
      result = render_tag('/photo.jpg title="back\\\\slash"')
      expect(result).to include("back\\slash")
    end

    it "parses trailing size parameter tokens" do
      result = render_tag("/photo.jpg size=300x200")
      expect(result).to include('width="300"')
      expect(result).to include('height="200"')
    end

    it "parses link and archive key=value parameters" do
      result = render_tag('/photo.jpg link="https://example.com" archive="https://archive.org/1"')
      expect(result).to include("example.com")
      expect(result).to include("archive.org/1")
    end

    it "uses an image-only markup token as the img src" do
      result = render_tag("/only-image.jpg")
      expect(result).to include('src="/only-image.jpg"')
    end

    it "tokenizes closing braces inside liquid expressions" do
      context.environments.first["page"] = { "image" => "/brace.jpg" }
      result = render_tag("{{ page.image }} title=Done")
      expect(result).to include("/brace.jpg")
      expect(result).to include("Done")
    end

    it "tokenizes opening braces for liquid expressions" do
      context.environments.first["page"] = { "title" => "Brace Title" }
      result = render_tag("/photo.jpg title={{ page.title }}")
      expect(result).to include("Brace Title")
    end

    it "parses a double-quoted image URL as the first token" do
      result = render_tag('"/quoted-photo.jpg"')
      expect(result).to include('src="/quoted-photo.jpg"')
    end

    it "does not open quotes while inside a Liquid expression" do
      context.environments.first["page"] = { "image" => "/from-liquid.jpg" }
      result = render_tag('{{ page.image }} title="Quoted Title"')
      expect(result).to include("/from-liquid.jpg")
      expect(result).to include("Quoted Title")
    end

    it "keeps closing braces inside quoted titles literal" do
      result = render_tag('/photo.jpg title="literal } brace"')
      expect(result).to include("literal } brace")
    end

    it "keeps opening braces inside quoted titles literal when archive follows" do
      result = render_tag('/photo.jpg title="brace { here" archive="none"')
      expect(result).to include("brace { here")
      expect(result).not_to include("web.archive.org")
    end

    it "treats backslashes outside quotes as literal characters" do
      result = render_tag('/photo.jpg title=foo\\bar')
      expect(result).to include("foo\\bar")
    end

    it "closes quoted values after escaped backslashes before the next parameter" do
      result = render_tag('/photo.jpg title="path\\\\" size=300x200')
      expect(result).to include("path\\")
      expect(result).to include('width="300"')
    end

    it "does not decrement liquid depth for unpaired closing braces" do
      context.environments.first["page"] = { "title" => "After Brace" }
      result = render_tag("/photo.jpg/} title={{ page.title }}")
      expect(result).to include("/photo.jpg/}")
      expect(result).to include("After Brace")
    end

    it "parses markup with no trailing whitespace from Liquid" do
      tag = Liquid::Template.parse("{%polaroid /photo.jpg size=300x200%}").root.nodelist.first
      result = tag.render(context)
      expect(result).to include('src="/photo.jpg"')
      expect(result).to include('width="300"')
    end

    it "ignores leading whitespace before the image URL" do
      tag = Liquid::Template.parse("{% polaroid  /photo.jpg %}").root.nodelist.first
      result = tag.render(context)
      expect(result).to include('src="/photo.jpg"')
    end

    it "keeps size parsing working after a single-brace title value" do
      result = render_tag("/photo.jpg title={foo} size=300x200")
      expect(result).to include('width="300"')
      expect(result).to include("{foo}")
    end
  end

  describe "#resolve_archive" do
    describe "archive functionality" do
      context "with archive opt-out" do
        it "does not include archive link" do
          result = render_tag('/photo.jpg link="https://example.com" archive="none"')
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
            .to_return(
              status: 200,
              body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json,
              headers: { "Content-Type" => "application/json" }
            )
        end

        it "archives the link URL not the image URL" do
          result = render_tag('/photo.jpg link="https://example.com"')
          expect(result).to include(
            "web.archive.org/web/20231201120000/https://example.com"
          )
          expect(result).not_to include(
            "web.archive.org/web/20231201120000/https://example.com/photo.jpg"
          )
          expect(result).not_to match(%r{web\.archive\.org/web/\d+/[^"]*photo\.jpg})
        end

        # Guard C: self-link (no link=) is lightbox UX, not an outbound archive target.
        it "does not auto-archive when link is omitted" do
          result = render_tag("/photo.jpg")
          expect(result).not_to include("web.archive.org")
          expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx})
        end

        it "still uses an explicit archive URL when link is omitted" do
          result = render_tag('/photo.jpg archive="https://archive.org/explicit"')
          expect(result).to include("archive.org/explicit")
          expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx})
        end
      end
    end

    it "opts out when archive is NONE with archiving enabled" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = render_tag('/photo.jpg link="https://example.com" archive="NONE"')
      expect(result).not_to include("web.archive.org")
      expect(result).not_to match(/polaroid-archive[^>]*>\s*\(\s*<a/)
    end

    it "does not auto-lookup when archiving is disabled" do
      result = render_tag('/photo.jpg link="https://example.com"')
      expect(result).not_to include("web.archive.org")
      expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx})
    end

    it "evaluates Liquid expressions in explicit archive URLs" do
      context.environments.first["page"] = { "archive" => "https://archive.org/snapshot" }
      result = render_tag('/photo.jpg link="https://example.com" archive={{ page.archive }}')
      expect(result).to include("archive.org/snapshot")
    end

    it "skips explicit archive lookup when archive parameter is empty" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx}).to_return(status: 404)

      result = render_tag('/photo.jpg link="https://example.com" archive=""')
      expect(result).not_to include("web.archive.org")
    end

    it "returns no archive link when auto-lookup finds nothing" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx}).to_return(status: 404)

      result = render_tag('/photo.jpg link="https://example.com"')
      expect(result).not_to match(/polaroid-archive[^>]*>\s*\(\s*<a/)
    end

    it "suppresses archive anchor for archive=none even when archiving is enabled" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = render_tag('/photo.jpg link="https://example.com" archive="none"')
      expect(result).not_to match(/polaroid-archive[^>]*>\s*\(\s*<a/)
      expect(result).not_to include("20231201120000")
    end

    it "auto-archives via ENV when no explicit archive parameter is given" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = render_tag('/photo.jpg link="https://example.com"')
      expect(result).to include("20231201120000")
    end

    it "evaluates explicit archive parameters literally" do
      result = render_tag('/photo.jpg link="https://example.com" archive="https://archive.org/explicit"')
      expect(result).to include("archive.org/explicit")
    end

    it "tolerates archive liquid expressions that evaluate to nil" do
      context.environments.first["page"] = {}
      result = render_tag('/photo.jpg link="https://example.com" archive={{ page.missing }}')
      expect(result).not_to match(/polaroid-archive[^>]*>\s*\(\s*<a/)
    end

    it "opts out for mixed-case archive none values" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = render_tag('/photo.jpg link="https://example.com" archive="NoNe"')
      expect(result).not_to include("20231201120000")
      expect(result).not_to match(/polaroid-archive[^>]*>\s*\(\s*<a/)
    end

    it "looks up the provided link URL when auto-archiving" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20240101120000", "https://unique-archive-target.example/"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = render_tag('/photo.jpg link="https://unique-archive-target.example/"')
      expect(result).to include(
        "web.archive.org/web/20240101120000/https://unique-archive-target.example/"
      )
    end

    it "evaluates an explicit archive liquid expression against context" do
      context.environments.first["page"] = { "snap" => "https://archive.org/ctx-snap" }
      result = render_tag('/photo.jpg link="https://example.com" archive={{ page.snap }}')
      expect(result).to include("archive.org/ctx-snap")
    end
  end

  describe "#build_template_variables" do
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
          result = render_tag("/photo.jpg")
          expect(result).to include('alt=""')
        end
      end

      context "with HTML in alt text" do
        it "escapes HTML in alt attribute" do
          result = render_tag('/photo.jpg alt="Text with <script>alert(\'xss\')</script>"')
          expect(result).to include('alt="Text with &lt;script&gt;')
          expect(result).not_to include("<script>")
        end
      end
    end

    describe "HTML escaping" do
      it "escapes HTML in image URL" do
        result = render_tag("/photo.jpg?param=<script>")
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

    it "renders nbsp in title area when title is empty" do
      result = render_tag('/photo.jpg title=""')
      expect(result).to match(/polaroid-title[^>]*>\s*&nbsp;/)
    end

    it "renders nbsp in link area when no explicit link is provided" do
      result = render_tag("/photo.jpg")
      expect(result).to match(/polaroid-link[^>]*>\s*&nbsp;/)
    end

    it "does not show link display when no explicit link provided" do
      result = render_tag("/photo.jpg")
      expect(result).to include('<div class="polaroid-link">')
      expect(result).to match(/polaroid-link[^>]*>\s*&nbsp;/i)
    end

    it "shows link display only when explicit link provided" do
      result = render_tag('/photo.jpg link="https://example.com"')
      expect(result).to include("example.com")
      expect(result).not_to match(/polaroid-link[^>]*>[^<]*photo\.jpg/i)
    end

    it "escapes HTML in archive URLs" do
      result = render_tag('/photo.jpg link="https://example.com" archive="https://archive.org/<script>"')
      expect(result).to include("&lt;script&gt;")
      expect(result).not_to include("archive.org/<script>")
    end

    it "includes width and height attributes when size is set" do
      result = render_tag("/photo.jpg size=300x200")
      expect(result).to include('width="300"')
      expect(result).to include('height="200"')
    end

    it "fills img alt from title when alt is omitted" do
      result = render_tag('/photo.jpg title="Visible Title"')
      expect(result).to include('alt="Visible Title"')
    end

    it "uses the alt parameter for img alt when provided" do
      result = render_tag('/photo.jpg alt="Screen Text" title="Visible Title"')
      expect(result).to include('alt="Screen Text"')
    end

    it "renders an archive anchor for an explicit archive URL" do
      result = render_tag('/photo.jpg link="https://example.com" archive="https://archive.org/snap"')
      expect(result).to match(%r{polaroid-archive[^>]*>\s*\(\s*<a[^>]*>archive</a>\s*\)})
    end

    it "hides the archive anchor when archive is none" do
      result = render_tag('/photo.jpg link="https://example.com" archive="none"')
      expect(result).not_to match(/polaroid-archive[^>]*>\s*\(\s*<a/)
    end

    it "omits target blank when image links to itself" do
      result = render_tag("/photo.jpg")
      expect(result).not_to include('target="_blank"')
    end

    it "adds target blank when image links elsewhere" do
      result = render_tag('/photo.jpg image_link="https://other.example"')
      expect(result).to include('target="_blank"')
    end

    it "renders escaped link display text for explicit links" do
      result = render_tag('/photo.jpg link="https://example.com/path"')
      expect(result).to match(%r{polaroid-link[^>]*>\s*<a[^>]*>example\.com/path</a>})
    end

    it "applies width and height attributes from size" do
      result = render_tag("/photo.jpg size=400x300")
      expect(result).to include('width="400"')
      expect(result).to include('height="300"')
    end

    it "adds target blank for an external image_link" do
      result = render_tag('/photo.jpg image_link="https://external.example/img"')
      expect(result).to include('href="https://external.example/img"')
      expect(result).to include('target="_blank"')
    end

    # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations -- observing all template locals for Mutant
    it "passes raw template variables through to the template" do
      custom_dir = File.join("/tmp", "polaroid-vars-#{Process.pid}")
      template = <<~HTML
        <div
          data-image="{{ image_url }}"
          data-image-link="{{ image_link_url }}"
          data-title="{{ title }}"
          data-alt="{{ alt }}"
          data-link-display="{{ link_display }}"
          data-archive="{{ archive_url }}"
          data-width="{{ width }}"
          data-height="{{ height }}"
          data-esc-image="{{ escaped_image_url }}"
          data-esc-link="{{ escaped_link_url }}"
          data-esc-image-link="{{ escaped_image_link_url }}"
          data-esc-title="{{ escaped_title }}"
          data-esc-alt="{{ escaped_alt }}"
          data-esc-link-display="{{ escaped_link_display }}"
          data-esc-archive="{{ escaped_archive_url }}"
        ></div>
      HTML

      with_custom_polaroid_template(custom_dir, template) do
        result = render_tag(
          '/photo.jpg?x=<a> size=10x20 title="T&T" alt="A&A" ' \
          'link="https://example.com?y=<b>" image_link="https://other.example/i?z=<c>" ' \
          'archive="https://archive.org/x?q=<d>"'
        )
        expect(result).to include('data-image="/photo.jpg?x=<a>"')
        expect(result).to include('data-image-link="https://other.example/i?z=<c>"')
        expect(result).to include('data-title="T&T"')
        expect(result).to include('data-alt="A&A"')
        expect(result).to include('data-link-display="example.com?y=<b>"')
        expect(result).to include('data-archive="https://archive.org/x?q=<d>"')
        expect(result).to include('data-width="10"')
        expect(result).to include('data-height="20"')
        expect(result).to include('data-esc-image="/photo.jpg?x=&lt;a&gt;"')
        expect(result).to include('data-esc-link="https://example.com?y=&lt;b&gt;"')
        expect(result).to include('data-esc-image-link="https://other.example/i?z=&lt;c&gt;"')
        expect(result).to include('data-esc-title="T&amp;T"')
        expect(result).to include('data-esc-alt="A&amp;A"')
        expect(result).to include('data-esc-link-display="example.com?y=&lt;b&gt;"')
        expect(result).to include('data-esc-archive="https://archive.org/x?q=&lt;d&gt;"')
      end
    end
    # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

    it "uses distinct escaped URLs when image, link, and image_link differ" do
      result = render_tag(
        '/only-image.jpg?a=<1> link="https://only-link.example?b=<2>" ' \
        'image_link="https://only-image-link.example?c=<3>"'
      )
      expect(result).to include('src="/only-image.jpg?a=&lt;1&gt;"')
      expect(result).to include('href="https://only-image-link.example?c=&lt;3&gt;"')
      expect(result).to include('href="https://only-link.example?b=&lt;2&gt;"')
    end
  end

  describe "#strip_protocol" do
    it "strips http from link display text" do
      result = render_tag('/photo.jpg link="http://example.com/path"')
      expect(result).to match(%r{polaroid-link[^>]*>\s*<a[^>]*>example\.com/path</a>})
    end

    it "strips https from link display text" do
      result = render_tag('/photo.jpg link="https://example.com/path"')
      expect(result).to match(%r{polaroid-link[^>]*>\s*<a[^>]*>example\.com/path</a>})
    end
  end
end
