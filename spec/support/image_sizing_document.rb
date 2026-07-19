# frozen_string_literal: true

# Shared mock Jekyll document for ImageSizingHooks specs.
RSpec.shared_context "image sizing document" do
  let(:mock_document) do
    instance_double(Jekyll::Document).tap do |doc|
      allow(doc).to receive(:content) { defined?(content) ? content : @content }
      allow(doc).to receive(:content=) { |new_content| @content = new_content }
      allow(doc).to receive(:output) { defined?(output) ? output : @output }
      allow(doc).to receive(:output=) { |new_output| @output = new_output }
    end
  end
end
