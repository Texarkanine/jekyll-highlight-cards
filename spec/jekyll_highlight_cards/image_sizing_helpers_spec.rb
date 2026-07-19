# frozen_string_literal: true

require "spec_helper"
require_relative "../support/image_sizing_document"

RSpec.describe JekyllHighlightCards::ImageSizingHooks do
  include_context "image sizing document"

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

    it "uses character offsets when the prefix contains multibyte characters" do
      # "é" is two UTF-8 bytes; MatchData#begin is character-based.
      output = 'é<img src="image.jpg"><!-- IMG_SIZE:100:100 -->'
      match = output.match(described_class::SIZED_IMG_HTML_PATTERN)
      expect(described_class.img_link_prefix(output, match)).to eq("é")
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
end
