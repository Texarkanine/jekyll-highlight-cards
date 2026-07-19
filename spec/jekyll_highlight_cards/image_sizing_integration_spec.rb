# frozen_string_literal: true

require "spec_helper"
require_relative "../support/image_sizing_document"

RSpec.describe JekyllHighlightCards::ImageSizingHooks do
  include_context "image sizing document"

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
end
