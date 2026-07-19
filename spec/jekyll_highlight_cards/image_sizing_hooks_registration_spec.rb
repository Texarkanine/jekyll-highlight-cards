# frozen_string_literal: true

require "spec_helper"
require_relative "../support/image_sizing_document"

RSpec.describe JekyllHighlightCards::ImageSizingHooks do
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
