# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::DimensionParser do
  describe ".parse_dimensions" do
    context "with WIDTHxHEIGHT format" do
      it "parses both dimensions" do
        expect(described_class.parse_dimensions("300x200")).to eq(%w[300 200])
      end

      it "handles dimensions with units" do
        expect(described_class.parse_dimensions("400pxx300px")).to eq(%w[400px 300px])
      end

      it "handles percentage values" do
        expect(described_class.parse_dimensions("50%x75%")).to eq(["50%", "75%"])
      end

      it "handles em values" do
        expect(described_class.parse_dimensions("10emx20em")).to eq(%w[10em 20em])
      end
    end

    context "with WIDTHx format (height omitted)" do
      it "parses width only" do
        expect(described_class.parse_dimensions("300x")).to eq(["300", nil])
      end

      it "handles width with units" do
        expect(described_class.parse_dimensions("400pxx")).to eq(["400px", nil])
      end
    end

    context "with xHEIGHT format (width omitted)" do
      it "parses height only" do
        expect(described_class.parse_dimensions("x200")).to eq([nil, "200"])
      end

      it "handles height with units" do
        expect(described_class.parse_dimensions("x300px")).to eq([nil, "300px"])
      end
    end

    context "with WIDTH format (no x separator)" do
      it "parses as width only" do
        expect(described_class.parse_dimensions("300")).to eq(["300", nil])
      end

      it "handles width with units" do
        expect(described_class.parse_dimensions("400px")).to eq(["400px", nil])
      end

      it "handles percentage" do
        expect(described_class.parse_dimensions("50%")).to eq(["50%", nil])
      end
    end

    context "with empty or nil input" do
      it "handles nil" do
        expect(described_class.parse_dimensions(nil)).to eq([nil, nil])
      end

      it "handles empty string" do
        expect(described_class.parse_dimensions("")).to eq([nil, nil])
      end
    end

    context "with edge cases" do
      it "handles single x (both dimensions omitted)" do
        expect(described_class.parse_dimensions("x")).to eq([nil, nil])
      end

      it "handles zero dimensions" do
        expect(described_class.parse_dimensions("0x0")).to eq(%w[0 0])
      end

      it "handles very large numbers" do
        expect(described_class.parse_dimensions("9999x9999")).to eq(%w[9999 9999])
      end

      it "treats leading x with non-digit height as height-only" do
        expect(described_class.parse_dimensions("xabc")).to eq([nil, "abc"])
      end

      it "treats xx with empty height as width only" do
        expect(described_class.parse_dimensions("50xx")).to eq(["50x", nil])
      end

      it "does not treat trailing newline as end-of-string x separator" do
        expect(described_class.parse_dimensions("300x\n")).to eq(["300x\n", nil])
      end
    end
  end
end
