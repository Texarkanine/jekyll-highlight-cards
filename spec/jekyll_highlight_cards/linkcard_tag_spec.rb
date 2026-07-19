# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe JekyllHighlightCards::LinkcardTag do
  let(:site) { instance_double(Jekyll::Site, source: "/test/site") }
  let(:registers) { { site: site } }
  let(:context) { Liquid::Context.new({}, {}, registers) }

  before do
    JekyllHighlightCards::ArchiveHelper.archive_cache = {}
    allow(ENV).to receive(:[]).and_call_original
    stub_request(:get, %r{web\.archive\.org/cdx/search/cdx}).to_return(status: 404)
  end

  def render_tag(markup)
    tag = Liquid::Template.parse("{% linkcard #{markup}%}").root.nodelist.first
    tag.render(context)
  end

  describe "#initialize" do
    it "preserves markup for parsing, including surrounding whitespace" do
      result = render_tag("  https://example.com  ")
      expect(result).to include('href="https://example.com"')
      expect(result).to include("example.com</a>")
    end

    it "raises when markup is only whitespace" do
      expect { render_tag("   ") }.to raise_error(ArgumentError, /requires a URL/)
    end
  end

  describe "#render" do
    it "renders a URL-only linkcard" do
      result = render_tag("https://example.com")
      expect(result).to include("https://example.com")
      expect(result).to include("example.com</a>")
      expect(result).not_to include("<h1>")
    end

    it "renders URL, title, and explicit archive" do
      result = render_tag('https://example.com "Title" archive:https://archive.org/123')
      expect(result).to include("Title")
      expect(result).to include("archive.org/123")
    end

    it "raises when the URL is missing" do
      expect { render_tag("") }.to raise_error(ArgumentError, /requires a URL/)
    end

    it "raises when the URL resolves to an empty string" do
      context.environments.first["page"] = { "empty_url" => "" }
      expect { render_tag("{{ page.empty_url }}") }.to raise_error(ArgumentError, /requires a URL/)
    end

    it "preserves the href URL with protocol in the anchor" do
      result = render_tag("https://example.com/path")
      expect(result).to include('href="https://example.com/path"')
      expect(result).to include("example.com/path</a>")
    end

    it "does not render a title when none is provided" do
      result = render_tag("https://example.com")
      expect(result).not_to include("<h1>")
    end

    it "uses the site from Liquid context registers" do
      expect { render_tag("https://example.com") }.not_to raise_error
    end

    it "passes the resolved URL to automatic archive lookup" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .with(query: hash_including("url" => "https://example.com"))
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = render_tag("https://example.com")
      expect(result).to include("web.archive.org/web/20231201120000")
    end

    it "evaluates a Liquid URL variable through the render pipeline" do
      context.environments.first["page"] = { "url" => "https://example.com/page" }
      result = render_tag("{{ page.url }}")
      expect(result).to include("https://example.com/page")
    end

    it "evaluates a Liquid title variable through the render pipeline" do
      context.environments.first["page"] = { "title" => "Rendered Title" }
      result = render_tag("https://example.com {{ page.title }}")
      expect(result).to include("Rendered Title")
    end

    it "evaluates a Liquid archive variable through the render pipeline" do
      context.environments.first["page"] = { "archive" => "https://archive.org/789" }
      result = render_tag("https://example.com archive:{{ page.archive }}")
      expect(result).to include("archive.org/789")
    end

    it "renders a user-provided site template override" do
      Dir.mktmpdir do |tmpdir|
        includes = File.join(tmpdir, "_includes", "highlight-cards")
        FileUtils.mkdir_p(includes)
        File.write(File.join(includes, "linkcard.html"), "<custom-linkcard/>")

        custom_site = instance_double(Jekyll::Site, source: tmpdir)
        custom_context = Liquid::Context.new({}, {}, { site: custom_site })
        tag = Liquid::Template.parse("{% linkcard https://example.com %}").root.nodelist.first
        result = tag.render(custom_context)
        expect(result).to include("<custom-linkcard/>")
      end
    end

    context "when the template is not found" do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "raises an error" do
        expect { render_tag("https://example.com") }.to raise_error(/Template not found/)
      end
    end
  end

  describe "#split_markup" do
    it "parses an unquoted multi-word title" do
      result = render_tag("https://example.com My Long Title")
      expect(result).to include("My Long Title")
    end

    it "parses a double-quoted title with spaces" do
      result = render_tag('https://example.com "This is a long title"')
      expect(result).to include("This is a long title")
    end

    it "parses a single-quoted title" do
      result = render_tag("https://example.com 'Single quoted title'")
      expect(result).to include("Single quoted title")
    end

    it "keeps braces inside quoted titles literal" do
      result = render_tag('https://example.com "{not liquid}"')
      expect(result).to include("{not liquid}")
    end

    it "treats Liquid expressions as single URL tokens" do
      context.environments.first["page"] = { "url" => "https://example.com/page" }
      result = render_tag("{{ page.url }}")
      expect(result).to include("https://example.com/page")
    end

    it "treats Liquid expressions as single title tokens" do
      context.environments.first["page"] = { "title" => "My Page Title" }
      result = render_tag("https://example.com {{ page.title }}")
      expect(result).to include("My Page Title")
    end

    it "evaluates both URL and title from Liquid variables" do
      context.environments.first["page"] = {
        "url" => "https://example.com/page",
        "title" => "My Page Title"
      }
      result = render_tag("{{ page.url }} {{ page.title }}")
      expect(result).to include("https://example.com/page")
      expect(result).to include("My Page Title")
    end

    it "handles escaped quotes in a quoted title" do
      result = render_tag('https://example.com "Title with \\" quote"')
      expect(result).to include("Title with &quot; quote")
    end

    it "handles escaped backslashes in a quoted title" do
      result = render_tag('https://example.com "Title with \\\\ backslash"')
      expect(result).to include("Title with \\ backslash")
    end

    it "handles complex escapes in a quoted title" do
      result = render_tag('https://example.com "Complex: \\" and \\\\"')
      expect(result).to include("Complex: &quot; and \\")
    end

    it "parses archive before title" do
      result = render_tag('https://example.com archive:https://archive.org/123 "Title"')
      expect(result).to include("archive.org/123")
      expect(result).to include("Title")
    end

    it "parses archive after title" do
      result = render_tag('https://example.com "Title" archive:https://archive.org/123')
      expect(result).to include("archive.org/123")
      expect(result).to include("Title")
    end

    it "does not split on whitespace inside Liquid expressions" do
      context.environments.first["page"] = { "url" => "https://example.com/page" }
      result = render_tag("{{ page.url }} extra-title-token")
      expect(result).to include("https://example.com/page")
      expect(result).to include("extra-title-token")
    end

    it "parses a double-quoted URL token" do
      result = render_tag('"https://example.com"')
      expect(result).to include('href="https://example.com"')
    end

    it "parses a single-quoted URL token" do
      result = render_tag("'https://example.com'")
      expect(result).to include('href="https://example.com"')
    end

    it "parses two single-quoted title tokens separately" do
      result = render_tag("'https://example.com' 'Title Part'")
      expect(result).to include('href="https://example.com"')
      expect(result).to include("Title Part")
    end

    it "keeps closing braces inside quoted titles literal" do
      result = render_tag('https://example.com "title}suffix"')
      expect(result).to include("title}suffix")
    end

    it "does not treat archive-like text in titles as archive parameters" do
      result = render_tag('https://example.com "mentions archive: later"')
      expect(result).to include("mentions archive: later")
      expect(result).not_to include("archive.org")
    end

    it "parses archive:none as a dedicated archive token" do
      result = render_tag("https://example.com archive:none Title")
      expect(result).not_to include("archive")
    end

    it "accumulates multiple unquoted title tokens" do
      result = render_tag("https://example.com Part One Part Two")
      expect(result).to include("Part One Part Two")
    end

    it "ignores extra whitespace between parameters" do
      result = render_tag('https://example.com   "Spaced Title"   archive:https://archive.org/123')
      expect(result).to include("Spaced Title")
      expect(result).to include("archive.org/123")
    end

    it "parses tab-separated parameters" do
      result = render_tag("https://example.com\t\"Tab Title\"")
      expect(result).to include("Tab Title")
    end

    it "parses a single-quoted archive URL" do
      result = render_tag("https://example.com archive:'https://archive.org/quoted'")
      expect(result).to include("archive.org/quoted")
    end

    it "parses a Liquid archive token with spaces" do
      context.environments.first["page"] = { "archive" => "https://archive.org/liquid" }
      result = render_tag("https://example.com archive:{{ page.archive }}")
      expect(result).to include("archive.org/liquid")
    end

    it "parses a Liquid URL followed by an unquoted title" do
      context.environments.first["page"] = { "url" => "https://example.com/page" }
      result = render_tag("{{ page.url }} Plain Title")
      expect(result).to include("https://example.com/page")
      expect(result).to include("Plain Title")
    end

    it "parses nested braces only inside Liquid expressions" do
      context.environments.first["page"] = { "url" => "https://example.com/page" }
      result = render_tag("{{ page.url }} \"brace { literal } title\"")
      expect(result).to include("https://example.com/page")
      expect(result).to include("brace { literal } title")
    end

    it "parses archive:none before an unquoted title" do
      result = render_tag("https://example.com archive:none Optional Title")
      expect(result).not_to include("archive")
      expect(result).to include("Optional Title")
    end

    it "does not create empty tokens from repeated whitespace" do
      result = render_tag('https://example.com   "Title"')
      expect(result).to include("<h1>Title</h1>")
      expect(result).not_to match(/<h1>\s*<\/h1>/)
    end

    it "ignores empty tokens produced by trailing whitespace" do
      result = render_tag("https://example.com   ")
      expect(result).not_to include("<h1>")
    end

    it "parses a Liquid-only URL token without surrounding whitespace" do
      context.environments.first["page"] = { "url" => "https://example.com/liquid-only" }
      result = render_tag("{{ page.url }}")
      expect(result).to include("https://example.com/liquid-only")
    end

    it "parses nested-looking braces only within Liquid expressions" do
      context.environments.first["page"] = { "url" => "https://example.com/nested" }
      result = render_tag("{{ page.url }}")
      expect(result).to include("https://example.com/nested")
      expect(result).not_to include("{{")
    end

    it "preserves an opening brace inside a quoted title" do
      result = render_tag('https://example.com "Title { prefix"')
      expect(result).to include("Title { prefix")
    end

    it "preserves braces in an unquoted URL path" do
      result = render_tag("https://example.com?q={value}")
      expect(result).to include("{value}")
    end

    it "parses consecutive Liquid expressions as separate tokens" do
      context.environments.first["page"] = {
        "url" => "https://example.com/page",
        "title" => "Title"
      }
      result = render_tag("{{ page.url }} {{ page.title }}")
      expect(result).to include("https://example.com/page")
      expect(result).to include("Title")
    end

    it "balances nested Liquid braces when parsing consecutive expressions" do
      context.environments.first["page"] = {
        "outer" => "https://example.com/outer",
        "inner" => "https://example.com/inner"
      }
      result = render_tag("{{ page.outer }} {{ page.inner }}")
      expect(result).to include("https://example.com/outer")
      expect(result).to include("https://example.com/inner")
      expect(result).not_to include("{{")
    end

    it "parses a single-quoted title containing a double quote" do
      result = render_tag(%q(https://example.com 'My "nickname"'))
      expect(result).to include("My &quot;nickname&quot;")
    end

    it "parses a bare URL without a title" do
      result = render_tag("https://example.com")
      expect(result).to include('href="https://example.com"')
      expect(result).not_to include("<h1>")
    end

    it "treats backslashes outside quoted values as literal characters" do
      result = render_tag("https://example.com foo\\ bar")
      expect(result).to include("foo\\ bar")
    end

    it "recognizes archive:none after a quoted title containing an opening brace" do
      result = render_tag('https://example.com "brace { here" archive:none')
      expect(result).not_to include("archive")
      expect(result).to include("brace { here")
    end

    it "does not merge tokens after a quoted title when archive:none follows" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx}).to_return(status: 404)

      result = render_tag('https://example.com "brace { here" archive:none')
      expect(result).not_to include("archive")
      expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx})
    end

    it "does not treat a closing brace inside a quoted title as ending a Liquid expression" do
      result = render_tag('https://example.com "literal } brace"')
      expect(result).to include("literal } brace")
    end

    it "does not open quotes while parsing a Liquid URL expression" do
      context.environments.first["page"] = { "url" => "https://example.com/page" }
      result = render_tag('{{ page.url }} "Quoted Title"')
      expect(result).to include("https://example.com/page")
      expect(result).to include("<h1>Quoted Title</h1>")
    end

    it "closes a quoted value before an archive opt-out that follows escaped backslashes" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = render_tag('https://example.com "path\\\\" archive:none')
      expect(result).not_to include("web.archive.org")
      expect(result).to include("path\\")
    end

    it "does not treat a trailing brace in the URL as a Liquid delimiter when it is not paired" do
      context.environments.first["page"] = { "url" => "https://example.com/page" }
      result = render_tag("https://example.com/} {{ page.url }}")
      expect(result).to include('href="https://example.com/}"')
      expect(result).to include("https://example.com/page")
    end

    it "keeps a closing brace inside a single-quoted title literal" do
      result = render_tag("https://example.com 'title with } brace'")
      expect(result).to include("title with } brace")
    end
  end

  describe "#resolve_url" do
    it "evaluates a Liquid URL variable" do
      context.environments.first["page"] = { "url" => "https://example.com/page" }
      result = render_tag("{{ page.url }}")
      expect(result).to include("https://example.com/page")
    end

    it "returns a literal URL unchanged" do
      result = render_tag("https://example.com/path")
      expect(result).to include('href="https://example.com/path"')
    end

    it "raises when the URL token is empty" do
      expect { render_tag("") }.to raise_error(ArgumentError, /requires a URL/)
    end
  end

  describe "#resolve_title" do
    it "returns nil when no title is provided" do
      result = render_tag("https://example.com")
      expect(result).not_to include("<h1>")
    end

    it "evaluates a Liquid title variable" do
      context.environments.first["page"] = { "title" => "My Page Title" }
      result = render_tag("https://example.com {{ page.title }}")
      expect(result).to include("My Page Title")
    end

    it "evaluates a literal quoted title" do
      result = render_tag('https://example.com "Plain Title"')
      expect(result).to include("Plain Title")
    end
  end

  describe "#resolve_archive" do
    it "opts out when archive:none is specified" do
      result = render_tag("https://example.com archive:none")
      expect(result).not_to include("archive")
    end

    it "opts out when archive:none uses different casing" do
      result = render_tag("https://example.com archive:NONE")
      expect(result).not_to include("archive")
    end

    it "ignores an empty explicit archive value" do
      result = render_tag("https://example.com archive:")
      expect(result).not_to include("archive")
    end

    it "falls back to automatic lookup when archive is an empty token" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = render_tag("https://example.com archive:")
      expect(result).to include("web.archive.org/web/20231201120000")
    end

    it "evaluates a Liquid archive variable" do
      context.environments.first["page"] = { "archive" => "https://archive.org/456" }
      result = render_tag("https://example.com archive:{{ page.archive }}")
      expect(result).to include("archive.org/456")
    end

    it "does not look up an archive URL when archiving is disabled" do
      render_tag("https://example.com")
      expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx})
    end

    it "uses an explicit archive URL" do
      result = render_tag("https://example.com archive:https://archive.org/123")
      expect(result).to include("archive.org/123")
    end

    it "looks up an archive URL when archiving is enabled" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .with(query: hash_including("url" => "https://example.com"))
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = render_tag("https://example.com")
      expect(result).to include("web.archive.org/web/20231201120000")
    end

    it "caches archive lookup results" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
        .to_return(
          status: 200,
          body: [%w[timestamp original], ["20231201120000", "https://example.com"]].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      render_tag("https://example.com")
      render_tag("https://example.com")
      expect(WebMock).to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx}).once
    end

    it "renders without an archive link when lookup fails" do
      allow(ENV).to receive(:[]).with("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE").and_return("1")
      stub_request(:get, %r{web\.archive\.org/cdx/search/cdx}).to_return(status: 404)

      result = render_tag("https://example.com")
      expect(result).not_to include("archive")
    end
  end

  describe "#build_template_variables" do
    it "strips the protocol from the display URL" do
      result = render_tag("https://example.com/path")
      expect(result).to include('href="https://example.com/path"')
      expect(result).to include("example.com/path</a>")
      expect(result).not_to include("https://example.com/path</a>")
    end

    it "strips http protocol from the display URL" do
      result = render_tag("http://example.com/path")
      expect(result).to include('href="http://example.com/path"')
      expect(result).to include("example.com/path</a>")
      expect(result).not_to include("http://example.com/path</a>")
    end

    it "strips a trailing slash from the display URL" do
      result = render_tag("https://example.com/path/")
      expect(result).to include('href="https://example.com/path/"')
      expect(result).to include("example.com/path</a>")
      expect(result).not_to include("/path/</a>")
    end

    it "includes a title heading when a title is present" do
      result = render_tag('https://example.com "Visible Title"')
      expect(result).to include("<h1>Visible Title</h1>")
    end

    it "omits a title heading when no title is provided" do
      result = render_tag("https://example.com")
      expect(result).not_to include("<h1>")
    end

    it "escapes HTML in the URL" do
      result = render_tag("https://example.com?a=<script>alert(1)</script>")
      expect(result).to include("&lt;script&gt;")
      expect(result).not_to include("<script>alert(1)</script>")
    end

    it "escapes HTML in the title" do
      result = render_tag('https://example.com "Title <b>bold</b>"')
      expect(result).to include("&lt;b&gt;")
      expect(result).not_to include("<b>bold</b>")
    end

    it "escapes HTML in the archive URL" do
      result = render_tag("https://example.com archive:https://archive.org/<script>")
      expect(result).to include("&lt;script&gt;")
    end

    it "prevents XSS in title and URL fields" do
      result = render_tag('https://example.com "Title <script>alert(1)</script>" archive:none')
      expect(result).not_to include("<script>alert(1)</script>")
      expect(result).to include("&lt;script&gt;")
    end

    it "includes an archive link when an archive URL is present" do
      result = render_tag("https://example.com archive:https://archive.org/123")
      expect(result).to include('href="https://archive.org/123"')
      expect(result).to include(">archive</a>")
    end
  end

  describe "#strip_protocol" do
    it "removes https from display text while preserving the href" do
      result = render_tag("https://example.com")
      expect(result).to include('href="https://example.com"')
      expect(result).to include("example.com</a>")
      expect(result).not_to include("https://example.com</a>")
    end

    it "removes http from display text while preserving the href" do
      result = render_tag("http://example.com")
      expect(result).to include('href="http://example.com"')
      expect(result).to include("example.com</a>")
      expect(result).not_to include("http://example.com</a>")
    end
  end
end
