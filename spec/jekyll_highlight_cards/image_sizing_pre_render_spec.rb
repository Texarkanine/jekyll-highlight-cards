# frozen_string_literal: true

require "spec_helper"
require_relative "../support/image_sizing_document"

RSpec.describe JekyllHighlightCards::ImageSizingHooks do
  include_context "image sizing document"

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

      it "processes content when the document content string is frozen" do
        allow(mock_document).to receive(:content).and_return(String.new("![Alt](image.jpg =300x200)").freeze)
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:300:200 -->")
      end

      it "handles multiple whitespace characters before the equals sign" do
        allow(mock_document).to receive(:content).and_return("![Alt](img.jpg\t\t=300x200)")
        described_class.process_pre_render(mock_document)
        expect(@content).to include("<!-- IMG_SIZE:300:200 -->")
      end

      it "leaves sized images unchanged when there is no space or tab before the equals sign" do
        allow(mock_document).to receive(:content).and_return("![Alt](img.jpg=300x200)")
        described_class.process_pre_render(mock_document)
        expect(@content).to eq("![Alt](img.jpg=300x200)")
        expect(@content).not_to include("IMG_SIZE")
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
end
