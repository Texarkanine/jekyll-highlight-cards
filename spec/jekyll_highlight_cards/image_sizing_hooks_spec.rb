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

      it "skips images in code fences" do
        described_class.process_pre_render(mock_document)
        # Should not convert the fenced image
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
    context "with size markers" do
      let(:output) { '<img src="image.jpg" alt="Alt"><!-- IMG_SIZE:300:200 -->' }

      it "applies width and height attributes" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).to include('height="200"')
      end

      it "auto-links the image" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('<a href="image.jpg">')
        expect(@output).to include('</a>')
      end

      it "removes the marker comment" do
        described_class.process_post_render(mock_document)
        expect(@output).not_to include("IMG_SIZE")
      end
    end

    context "with width only marker" do
      let(:output) { '<img src="image.jpg" alt="Alt"><!-- IMG_SIZE:300: -->' }

      it "applies width attribute only" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).not_to include('height=')
      end
    end

    context "with height only marker" do
      let(:output) { '<img src="image.jpg" alt="Alt"><!-- IMG_SIZE::200 -->' }

      it "applies height attribute only" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('height="200"')
        expect(@output).not_to include('width=')
      end
    end

    context "with images already in links" do
      let(:output) { '<a href="/page"><img src="img.jpg" alt="Alt"><!-- IMG_SIZE:300:200 --></a>' }

      it "does not auto-link images already in anchors" do
        described_class.process_post_render(mock_document)
        # Should have only one <a> tag
        expect(@output.scan(/<a /).length).to eq(1)
        expect(@output).to include('<a href="/page">')
      end

      it "still applies dimensions" do
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).to include('height="200"')
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
end
