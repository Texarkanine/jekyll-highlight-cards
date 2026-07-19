# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::ImageSizingHooks do
  # Create mock Jekyll document
  let(:mock_document) do
    instance_double(Jekyll::Document).tap do |doc|
      allow(doc).to receive(:content) { defined?(content) ? content : @content }
      allow(doc).to receive(:content=) { |new_content| @content = new_content }
      allow(doc).to receive(:output) { defined?(output) ? output : @output }
      allow(doc).to receive(:output=) { |new_output| @output = new_output }
    end
  end

  describe ".process_pre_render" do
    context "when content is nil" do
      it "returns without modifying the document" do
        allow(mock_document).to receive(:content).and_return(nil)
        expect(mock_document).not_to receive(:content=)

        expect(described_class.process_pre_render(mock_document)).to be_nil
      end
    end

    context "with sized images" do
      let(:content) { "![Alt text](image.jpg =300x200)" }

      it "converts to marker syntax" do
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:300:200 -->")
      end

      it "preserves alt text" do
        described_class.process_pre_render(mock_document)
        expect(@content).to include("![Alt text]")
      end

      it "removes size from src" do
        described_class.process_pre_render(mock_document)
        expect(@content).to include("(image.jpg)")
        expect(@content).not_to include("=300x200")
      end

      it "handles empty alt text" do
        allow(mock_document).to receive(:content).and_return("![](image.jpg =300x200)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("![](image.jpg)<!-- IMG_SIZE:300:200 -->")
      end

      it "strips whitespace around the image src" do
        allow(mock_document).to receive(:content).and_return("![Alt](  image.jpg  =300x200)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("![Alt](image.jpg)<!-- IMG_SIZE:300:200 -->")
      end

      it "strips whitespace around the size specifier" do
        allow(mock_document).to receive(:content).and_return("![Alt](image.jpg = 300x200 )")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:300:200 -->")
      end

      it "processes content when lines are frozen" do
        allow(mock_document).to receive(:content).and_return("![Alt](image.jpg =300x200)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:300:200 -->")
      end

      it "handles multiple whitespace characters before the equals sign" do
        allow(mock_document).to receive(:content).and_return("![Alt](img.jpg\t\t=300x200)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:300:200 -->")
      end

      it "requires at least one space or tab before the equals sign" do
        allow(mock_document).to receive(:content).and_return("![Alt](img.jpg  =300x200)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:300:200 -->")
      end

      it "uses the match start rather than the alt text start for inline-code checks" do
        allow(mock_document).to receive(:content).and_return("![`tip`](img.jpg =100x100)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:100:100 -->")
      end

      it "does not treat a backtick inside alt text as inline-code markup" do
        allow(mock_document).to receive(:content).and_return("![`tip`](img.jpg =100x100)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("![`tip`](img.jpg)")
      end
    end

    context "with size variations" do
      it "handles width only (=300x)" do
        allow(mock_document).to receive(:content).and_return("![Alt](img.jpg =300x)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:300: -->")
      end

      it "handles height only (=x200)" do
        allow(mock_document).to receive(:content).and_return("![Alt](img.jpg =x200)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE::200 -->")
      end

      it "handles width shorthand (=300)" do
        allow(mock_document).to receive(:content).and_return("![Alt](img.jpg =300)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:300: -->")
      end

      it "handles units (=400pxx300px)" do
        allow(mock_document).to receive(:content).and_return("![Alt](img.jpg =400pxx300px)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:400px:300px -->")
      end
    end

    context "with code fences" do
      let(:content) do
        <<~MARKDOWN
          Some text
          ```
          ![Alt](image.jpg =300x200)
          ```
          ![Real](other.jpg =400x300)
        MARKDOWN
      end

      it "skips images in backtick code fences" do
        described_class.process_pre_render(mock_document)
        # Should not convert the fenced image
        expect(@content).to include("![Alt](image.jpg =300x200)")
        # Should convert the real image
        expect(@content).to include("<!-- IMG_SIZE:400:300 -->")
        expect(@content.scan("IMG_SIZE").length).to eq(1)
      end
    end

    context "with a code fence starting on the first line" do
      let(:content) do
        <<~MARKDOWN
          ```
          ![Alt](image.jpg =300x200)
          ```
          ![Real](other.jpg =400x300)
        MARKDOWN
      end

      it "skips images when the opening fence is on line zero" do
        described_class.process_pre_render(mock_document)
        expect(@content).to include("![Alt](image.jpg =300x200)")
        expect(@content).to include("<!-- IMG_SIZE:400:300 -->")
      end
    end

    context "with tilde code fences" do
      let(:content) do
        <<~MARKDOWN
          Some text
          ~~~
          ![Alt](image.jpg =300x200)
          ~~~
          ![Real](other.jpg =400x300)
        MARKDOWN
      end

      it "skips images in tilde code fences" do
        described_class.process_pre_render(mock_document)
        # Should not convert the fenced image
        expect(@content).to include("![Alt](image.jpg =300x200)")
        # Should convert the real image
        expect(@content).to include("<!-- IMG_SIZE:400:300 -->")
      end
    end

    context "with indented code blocks (spaces)" do
      let(:content) do
        <<~MARKDOWN
          Some text
              ![Alt](image.jpg =300x200)
              still code
          ![Real](other.jpg =400x300)
        MARKDOWN
      end

      it "skips images in indented code blocks" do
        described_class.process_pre_render(mock_document)
        # Should not convert the indented image
        expect(@content).to include("![Alt](image.jpg =300x200)")
        # Should convert the real image
        expect(@content).to include("<!-- IMG_SIZE:400:300 -->")
      end
    end

    context "with indented code blocks (tab)" do
      let(:content) { "Some text\n\t![Alt](image.jpg =300x200)\n![Real](other.jpg =400x300)" }

      it "skips images in tab-indented code blocks" do
        described_class.process_pre_render(mock_document)
        # Should not convert the tab-indented image
        expect(@content).to include("![Alt](image.jpg =300x200)")
        # Should convert the real image
        expect(@content).to include("<!-- IMG_SIZE:400:300 -->")
      end
    end

    context "with inline code" do
      let(:content) { "Text `![Alt](image.jpg =300x200)` more text" }

      it "skips images in inline code" do
        described_class.process_pre_render(mock_document)
        # Should not convert
        expect(@content).to include("`![Alt](image.jpg =300x200)`")
        expect(@content).not_to include("IMG_SIZE")
      end

      it "skips images when the match starts immediately after an opening backtick" do
        allow(mock_document).to receive(:content).and_return("`![Alt](image.jpg =300x200)`")
        described_class.process_pre_render(mock_document)
        expect(@content).to eq("`![Alt](image.jpg =300x200)`")
      end
    end

    context "with multiple images" do
      let(:content) do
        <<~MARKDOWN
          ![First](img1.jpg =100x100)
          ![Second](img2.jpg =200x200)
        MARKDOWN
      end

      it "processes all images" do
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:100:100 -->")
        expect(@content).to include("<!-- IMG_SIZE:200:200 -->")
      end
    end
  end

  describe ".process_post_render" do
    context "when output is nil" do
      it "returns without modifying the document" do
        allow(mock_document).to receive(:output).and_return(nil)
        expect(mock_document).not_to receive(:output=)

        expect(described_class.process_post_render(mock_document)).to be_nil
      end
    end

    context "with size markers" do
      let(:output) { '<img src="image.jpg" alt="Alt"><!-- IMG_SIZE:300:200 -->' }

      it "applies width and height attributes" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).to include('height="200"')
        expect(@output).to include('<img width="300"')
      end

      it "auto-links the image" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('<a href="image.jpg">')
        expect(@output).to include("</a>")
      end

      it "removes the marker comment" do
        described_class.process_post_render(mock_document)
        expect(@output).not_to include("IMG_SIZE")
      end

      it "strips whitespace from marker dimensions" do
        allow(mock_document).to receive(:output)
          .and_return('<img src="image.jpg" alt="Alt"><!-- IMG_SIZE: 300 : 200 -->')
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).to include('height="200"')
      end

      it "escapes HTML entities in auto-link hrefs" do
        allow(mock_document).to receive(:output)
          .and_return('<img src="image&amp;file.jpg" alt="Alt"><!-- IMG_SIZE:300:200 -->')
        described_class.process_post_render(mock_document)
        expect(@output).to include('<a href="image&amp;amp;file.jpg">')
      end

      it "processes output when the string is frozen" do
        allow(mock_document).to receive(:output)
          .and_return('<img src="image.jpg" alt="Alt"><!-- IMG_SIZE:300:200 -->')
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
      end

      it "separates width and height attributes with a space" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300" height="200"')
      end

      it "inserts attributes immediately after the img opening tag" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('<img width="300" height="200" src="image.jpg"')
        expect(@output.scan("<img").length).to eq(1)
      end
    end

    context "with width only marker" do
      let(:output) { '<img src="image.jpg" alt="Alt"><!-- IMG_SIZE:300: -->' }

      it "applies width attribute only" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).not_to include("height=")
      end
    end

    context "with height only marker" do
      let(:output) { '<img src="image.jpg" alt="Alt"><!-- IMG_SIZE::200 -->' }

      it "applies height attribute only" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('height="200"')
        expect(@output).not_to include("width=")
      end
    end

    context "with empty dimension marker" do
      let(:output) { '<img src="image.jpg" alt="Alt"><!-- IMG_SIZE:: -->' }

      it "leaves the img tag unchanged aside from auto-linking" do
        described_class.process_post_render(mock_document)
        expect(@output).not_to include("width=")
        expect(@output).not_to include("height=")
        expect(@output).to include('<img src="image.jpg" alt="Alt">')
        expect(@output).to include('<a href="image.jpg">')
      end
    end

    context "with an img tag containing angle-bracket text in alt" do
      let(:output) { '<img alt="1 <a 2" src="image.jpg"><!-- IMG_SIZE:300:200 -->' }

      it "auto-links using img position rather than marker position" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('<a href="image.jpg">')
      end
    end

    context "with an img tag using multiple spaces before attributes" do
      let(:output) { '<img  src="image.jpg" alt="Alt"><!-- IMG_SIZE:300:200 -->' }

      it "still applies dimensions and auto-links" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).to include('<a href="image.jpg">')
      end
    end

    context "with an empty src attribute" do
      let(:output) { '<img src="" alt="Alt"><!-- IMG_SIZE:300:200 -->' }

      it "applies dimensions without auto-linking" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).not_to include("<a href=")
      end
    end

    context "with single-quoted src attribute" do
      let(:output) { "<img src='image.jpg' alt='Alt'><!-- IMG_SIZE:300:200 -->" }

      it "auto-links using the single-quoted src" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('<a href="image.jpg">')
        expect(@output).to include('width="300"')
      end
    end

    context "with leading whitespace before the img tag" do
      let(:output) { ' <img src="image.jpg" alt="Alt"><!-- IMG_SIZE:300:200 -->' }

      it "auto-links the image" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('<a href="image.jpg">')
      end
    end

    context "with a newline between the img tag and marker" do
      let(:output) { "<img src=\"image.jpg\" alt=\"Alt\">\n<!-- IMG_SIZE:300:200 -->" }

      it "still applies dimensions and auto-links" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).to include('<a href="image.jpg">')
      end
    end

    context "with a trailing colon and no height value" do
      let(:output) { '<img src="image.jpg"><!-- IMG_SIZE:100: -->' }

      it "applies the width attribute without requiring height text" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="100"')
        expect(@output).not_to include("height=")
      end
    end

    context "with unclosed anchor whitespace before the img tag" do
      let(:output) do
        '<a href="page">   <img alt="note <a extra" src="image.jpg"><!-- IMG_SIZE:300:200 -->'
      end

      it "does not auto-link when an earlier anchor is still open" do
        described_class.process_post_render(mock_document)
        expect(@output).not_to include('<a href="image.jpg">')
        expect(@output).to include('width="300"')
      end
    end

    context "with images already in links" do
      let(:output) { '<a href="/page"><img src="img.jpg" alt="Alt"><!-- IMG_SIZE:300:200 --></a>' }

      it "does not auto-link images already in anchors" do
        described_class.process_post_render(mock_document)
        # Should have only one <a> tag
        expect(@output.scan("<a ").length).to eq(1)
        expect(@output).to include('<a href="/page">')
      end

      it "still applies dimensions" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).to include('height="200"')
      end
    end

    context "with a closed anchor before the image" do
      let(:output) { '<a href="/page"></a><img src="img.jpg" alt="Alt"><!-- IMG_SIZE:300:200 -->' }

      it "auto-links the image when earlier anchors are closed" do
        described_class.process_post_render(mock_document)
        expect(@output.scan("<a ").length).to eq(2)
        expect(@output).to include('<a href="img.jpg">')
      end
    end

    context "with multiple sized images" do
      let(:output) do
        '<img src="img1.jpg"><!-- IMG_SIZE:100:100 -->' \
          '<img src="img2.jpg"><!-- IMG_SIZE:200:200 -->'
      end

      it "processes all images" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="100"')
        expect(@output).to include('height="100"')
        expect(@output).to include('width="200"')
        expect(@output).to include('height="200"')
      end
    end

    context "with malformed img tag (missing src)" do
      let(:output) { '<img alt="Alt"><!-- IMG_SIZE:300:200 -->' }

      it "does not crash and applies dimensions" do
        expect { described_class.process_post_render(mock_document) }.not_to raise_error
        expect(@output).to include('width="300"')
        expect(@output).to include('height="200"')
      end

      it "does not attempt to auto-link" do
        described_class.process_post_render(mock_document)
        # Should not wrap in <a> tag when src is missing
        expect(@output).not_to include("<a href=")
      end
    end

    context "with img tag with malformed src attribute" do
      let(:output) { "<img src=><!-- IMG_SIZE:300:200 -->" }

      it "does not crash" do
        expect { described_class.process_post_render(mock_document) }.not_to raise_error
        expect(@output).to include('width="300"')
      end

      it "does not auto-link when src is empty" do
        described_class.process_post_render(mock_document)
        expect(@output).not_to include("<a href=")
      end
    end
  end

  describe ".markdown_inline_check_position" do
    it "uses the full-match start for inline-code detection" do
      line = "![alt](img.jpg =100x100)"
      match = line.match(described_class::SIZED_MARKDOWN_PATTERN)
      expect(described_class.markdown_inline_check_position(match)).to eq(match.begin(0))
    end

    it "does not assume matches begin at string index zero" do
      line = "prefix ![alt](img.jpg =100x100)"
      match = line.match(described_class::SIZED_MARKDOWN_PATTERN)
      expect(described_class.markdown_inline_check_position(match)).to be > 0
    end
  end

  describe ".img_link_prefix" do
    it "ends immediately before the img tag" do
      output = '   <img src="image.jpg"><!-- IMG_SIZE:100:100 -->'
      match = output.match(described_class::SIZED_IMG_HTML_PATTERN)
      expect(described_class.img_link_prefix(output, match)).to eq("   ")
      expect(described_class.img_link_prefix(output, match).length).to eq(match.begin(2))
    end
  end

  describe ".unclosed_anchor_count" do
    it "returns zero when anchors are balanced" do
      prefix = '<a href="/page"></a><p>'
      expect(described_class.unclosed_anchor_count(prefix)).to eq(0)
    end

    it "returns one for a single unclosed anchor" do
      prefix = '<a href="/page"><p>'
      expect(described_class.unclosed_anchor_count(prefix)).to eq(1)
    end

    it "requires whitespace after the a tag name" do
      prefix = "<article><p>"
      expect(described_class.unclosed_anchor_count(prefix)).to eq(0)
      expect(described_class.unclosed_anchor_count("<a\thref=\"x\">")).to eq(1)
      expect(described_class.unclosed_anchor_count('<a  href="x">')).to eq(1)
    end

    it "counts multiple opens and closes in order" do
      prefix = '<a href="/one"></a><a href="/two"><p>'
      expect(described_class.unclosed_anchor_count(prefix)).to eq(1)
    end

    it "starts scanning from position zero" do
      expect(described_class.unclosed_anchor_count("")).to eq(0)
      expect(described_class.unclosed_anchor_count('<a href="x">')).to eq(1)
    end

    it "does not treat closing tags as opens" do
      prefix = "</a>"
      expect(described_class.unclosed_anchor_count(prefix)).to eq(-1)
    end

    it "counts consecutive unclosed anchors" do
      expect(described_class.unclosed_anchor_count('<a href="1"><a href="2">')).to eq(2)
    end
  end

  describe ".fence_count_before" do
    it "returns zero for the first line" do
      lines = ["```\n", "content\n"]
      expect(described_class.fence_count_before(lines, 0)).to eq(0)
    end

    it "counts fence delimiters before the given line" do
      lines = ["```\n", "content\n", "```\n", "text\n"]
      expect(described_class.fence_count_before(lines, 3)).to eq(2)
    end

    it "includes an opening fence on line zero" do
      lines = ["```\n", "content\n"]
      expect(described_class.fence_count_before(lines, 1)).to eq(1)
    end

    it "does not include the current line in the count" do
      lines = ["text\n", "```\n", "content\n"]
      expect(described_class.fence_count_before(lines, 1)).to eq(0)
    end

    it "does not count a fence delimiter on the final line when checking line zero" do
      lines = ["text\n", "```\n"]
      expect(described_class.fence_count_before(lines, 0)).to eq(0)
    end

    it "counts tilde fences" do
      lines = ["~~~\n", "content\n"]
      expect(described_class.fence_count_before(lines, 1)).to eq(1)
    end

    it "does not count two-character tilde markers" do
      lines = ["~~\n", "content\n"]
      expect(described_class.fence_count_before(lines, 1)).to eq(0)
    end

    it "counts consecutive fence lines individually" do
      lines = ["```\n", "~~~\n", "text\n"]
      expect(described_class.fence_count_before(lines, 2)).to eq(2)
    end

    it "ignores single-backtick lines" do
      lines = ["`\n", "content\n"]
      expect(described_class.fence_count_before(lines, 1)).to eq(0)
    end

    it "requires at least three matching fence markers" do
      lines = ["``\n", "```\n", "content\n"]
      expect(described_class.fence_count_before(lines, 2)).to eq(1)
    end

    it "counts four-or-more backtick fence markers" do
      lines = ["````ruby\n", "content\n"]
      expect(described_class.fence_count_before(lines, 1)).to eq(1)
    end
  end

  describe ".in_code_fence?" do
    it "returns false for line zero" do
      lines = ["![Alt](img.jpg =100x100)\n"]
      expect(described_class.in_code_fence?(lines, 0)).to be(false)
    end

    it "returns false for an indented first line" do
      lines = ["    code\n"]
      expect(described_class.in_code_fence?(lines, 0)).to be(false)
    end

    it "returns true inside a single-line fenced block opener" do
      lines = ["```\n", "![Alt](img.jpg =100x100)\n"]
      expect(described_class.in_code_fence?(lines, 1)).to be(true)
    end

    it "returns false after balanced fences" do
      lines = ["```\n", "```\n", "![Alt](img.jpg =100x100)\n"]
      expect(described_class.in_code_fence?(lines, 2)).to be(false)
    end

    it "returns true for a contiguous indented block" do
      lines = ["text\n", "    line one\n", "    line two\n"]
      expect(described_class.in_code_fence?(lines, 2)).to be(true)
    end

    it "returns true for tab-indented lines" do
      lines = %W[text\n \tcode\n]
      expect(described_class.in_code_fence?(lines, 1)).to be(true)
    end

    it "returns true for a deep indented block" do
      lines = ["text\n", "    one\n", "    two\n", "    three\n"]
      expect(described_class.in_code_fence?(lines, 3)).to be(true)
    end

    it "returns false when the current line is not indented" do
      lines = ["    code\n", "normal\n"]
      expect(described_class.in_code_fence?(lines, 1)).to be(false)
    end
  end

  describe ".backtick_count_before" do
    it "returns zero at position zero" do
      expect(described_class.backtick_count_before("text", 0)).to eq(0)
    end

    it "counts backticks before the position" do
      expect(described_class.backtick_count_before("a`b`c", 3)).to eq(1)
    end

    it "does not count backticks at or after the position" do
      expect(described_class.backtick_count_before("`code`", 1)).to eq(1)
      expect(described_class.backtick_count_before("`code`", 6)).to eq(2)
    end

    it "stops counting exactly at the position boundary" do
      expect(described_class.backtick_count_before("`a`", 2)).to eq(1)
    end

    it "uses a length-based slice rather than the whole line" do
      expect(described_class.backtick_count_before("```tail", 2)).to eq(2)
      expect(described_class.backtick_count_before("```tail", 3)).to eq(3)
    end
  end

  describe ".in_inline_code?" do
    it "returns false outside inline code" do
      expect(described_class.in_inline_code?("plain text", 3)).to be(false)
    end

    it "returns true after an opening backtick" do
      expect(described_class.in_inline_code?("`code", 1)).to be(true)
    end

    it "returns false after balanced backticks" do
      expect(described_class.in_inline_code?("``text", 2)).to be(false)
    end

    it "uses the start of the full match, not the alt text" do
      line = "`![Alt](img.jpg =100x100)"
      match_start = line.index("![")
      expect(described_class.in_inline_code?(line, match_start)).to be(true)
    end

    it "requires an explicit position" do
      expect(described_class.in_inline_code?("`code`", 4)).to be(true)
      expect(described_class.in_inline_code?("`code`", 0)).to be(false)
    end
  end

  describe "integration" do
    context "complete workflow" do
      let(:content) { "![Alt](image.jpg =300x200)" }
      let(:output) { '<img src="image.jpg" alt="Alt"><!-- IMG_SIZE:300:200 -->' }

      it "processes from markdown to final HTML" do
        # Pre-render: markdown → marker
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:300:200 -->")

        # Post-render: marker → final HTML
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).to include('height="200"')
        expect(@output).to include('<a href="image.jpg">')
        expect(@output).not_to include("IMG_SIZE")
      end
    end
  end

  # Observes the :documents hook bodies registered at the bottom of image_sizing_hooks.rb
  # (unit tests call process_* directly and never execute the register blocks).
  describe "Jekyll hook registration" do
    it "runs process_pre_render on documents pre_render" do
      document = instance_double(Jekyll::Document)
      allow(document).to receive(:content).and_return("![Alt](image.jpg =300x200)")
      allow(document).to receive(:content=) { |value| @hook_content = value }

      Jekyll::Hooks.trigger :documents, :pre_render, document

      expect(@hook_content).to include("<!-- IMG_SIZE:300:200 -->")
      expect(@hook_content).to include("(image.jpg)")
    end

    it "runs process_post_render on documents post_render" do
      document = instance_double(Jekyll::Document)
      allow(document).to receive(:output)
        .and_return('<p><img src="image.jpg" alt="Alt"><!-- IMG_SIZE:300:200 --></p>')
      allow(document).to receive(:output=) { |value| @hook_output = value }

      Jekyll::Hooks.trigger :documents, :post_render, document

      expect(@hook_output).to include('width="300"')
      expect(@hook_output).to include('height="200"')
      expect(@hook_output).to include('<a href="image.jpg">')
      expect(@hook_output).not_to include("IMG_SIZE")
    end
  end
end
