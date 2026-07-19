# frozen_string_literal: true

require "spec_helper"
require_relative "../support/image_sizing_document"

RSpec.describe JekyllHighlightCards::ImageSizingHooks do
  include_context "image sizing document"

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

      it "keeps a single img tag with spaced width and height attributes" do
        described_class.process_post_render(mock_document)
        expect(@output.scan(/<img\b/).size).to eq(1)
        expect(@output).to match(/width="300"\s+height="200"/)
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

      it "processes output when the document output string is frozen" do
        allow(mock_document).to receive(:output)
          .and_return(String.new('<img src="image.jpg" alt="Alt"><!-- IMG_SIZE:300:200 -->').freeze)
        described_class.process_post_render(mock_document)
        expect(@output).to include('width="300"')
        expect(@output).to include('height="200"')
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
end
