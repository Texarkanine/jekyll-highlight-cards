# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::FreezeArchives::TagLocator do
  subject(:locator) { described_class.new }

  describe "#locate" do
    # L1–L2: find linkcard/polaroid spans; ignore unrelated Liquid tags

    it "L1: finds multiple tags in one file" do
      text = <<~TEXT
        Intro
        {% linkcard https://one.example Title One %}
        Middle
        {% polaroid /img.jpg link="https://two.example" %}
        {% linkcard
            https://three.example
        %}
      TEXT

      spans = locator.locate(text)
      expect(spans.size).to eq(3)
      expect(spans.map { |s| s[:tag] }).to eq(%w[linkcard polaroid linkcard])
      expect(spans[0][:markup]).to include("https://one.example")
      expect(spans[1][:markup]).to include('link="https://two.example"')
      expect(spans[2][:markup]).to include("https://three.example")
      spans.each do |span|
        expect(span[:range]).to be_a(Range)
        expect(text[span[:range]]).to start_with("{%")
        expect(text[span[:range]]).to end_with("%}")
      end
    end

    it "L2: ignores unrelated Liquid tags" do
      text = <<~TEXT
        {% assign x = 1 %}
        {% include foo.html %}
        {% linkcard https://example.com %}
        {% if page.title %}{{ page.title }}{% endif %}
      TEXT

      spans = locator.locate(text)
      expect(spans.size).to eq(1)
      expect(spans.first[:tag]).to eq("linkcard")
      expect(spans.first[:markup]).to include("https://example.com")
    end

    it "does not fold whitespace-control dash into markup" do
      text = "{% linkcard https://example.com Title -%}"
      span = locator.locate(text).first

      expect(span[:markup]).to eq("https://example.com Title ")
      expect(text[span[:range]]).to end_with("-%}")
    end
  end
end
