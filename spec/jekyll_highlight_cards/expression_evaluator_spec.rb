# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllHighlightCards::ExpressionEvaluator do
  # Create a test class that includes the module
  let(:evaluator) do
    Class.new do
      include JekyllHighlightCards::ExpressionEvaluator
    end.new
  end

  let(:context) do
    Liquid::Context.new(
      { "page" => { "title" => "Test Title", "url" => "https://example.com" } },
      {},
      { registers: { site: instance_double(Jekyll::Site) } }
    )
  end

  describe "#evaluate_expression" do
    context "with quoted strings" do
      it "treats double-quoted strings as literals" do
        result = evaluator.evaluate_expression('"My Title"', context)
        expect(result).to eq("My Title")
      end

      it "treats single-quoted strings as literals" do
        result = evaluator.evaluate_expression("'My Title'", context)
        expect(result).to eq("My Title")
      end

      it "handles empty quoted strings" do
        result = evaluator.evaluate_expression('""', context)
        expect(result).to eq("")
      end

      it "preserves content inside quotes" do
        result = evaluator.evaluate_expression('"{{ page.title }}"', context)
        expect(result).to eq("{{ page.title }}")
      end
    end

    context "with Liquid variable lookups" do
      it "evaluates simple variable" do
        result = evaluator.evaluate_expression("{{ page.title }}", context)
        expect(result).to eq("Test Title")
      end

      it "evaluates nested variable" do
        result = evaluator.evaluate_expression("{{ page.url }}", context)
        expect(result).to eq("https://example.com")
      end

      it "handles undefined variables gracefully" do
        result = evaluator.evaluate_expression("{{ page.nonexistent }}", context)
        expect(result).to eq("")
      end
    end

    context "with literal strings (unquoted)" do
      it "returns the string as-is" do
        result = evaluator.evaluate_expression("literal-value", context)
        expect(result).to eq("literal-value")
      end

      it "does not evaluate plain literals through Liquid" do
        poison = instance_double(Liquid::Template, render: "from-liquid")
        allow(Liquid::Template).to receive(:parse).and_return(poison)
        expect(evaluator.evaluate_expression("literal-value", context)).to eq("literal-value")
      end

      it "handles URLs" do
        result = evaluator.evaluate_expression("https://example.com", context)
        expect(result).to eq("https://example.com")
      end

      it "handles paths" do
        result = evaluator.evaluate_expression("/assets/image.jpg", context)
        expect(result).to eq("/assets/image.jpg")
      end
    end

    context "with allow_nil parameter" do
      it "returns nil when allow_nil is true and value is nil" do
        result = evaluator.evaluate_expression(nil, context, allow_nil: true)
        expect(result).to be_nil
      end

      it "returns nil when allow_nil is false and value is nil" do
        result = evaluator.evaluate_expression(nil, context, allow_nil: false)
        expect(result).to be_nil
      end

      it "returns empty string when allow_nil is true and result is empty" do
        result = evaluator.evaluate_expression('""', context, allow_nil: true)
        expect(result).to eq("")
      end

      it "returns nil when allow_nil is false and result is empty quoted string" do
        result = evaluator.evaluate_expression('""', context, allow_nil: false)
        expect(result).to be_nil
      end

      it "returns nil when allow_nil is false and Liquid result is empty" do
        result = evaluator.evaluate_expression("{{ page.nonexistent }}", context, allow_nil: false)
        expect(result).to be_nil
      end

      it "returns non-empty Liquid results when allow_nil is false" do
        expect(evaluator.evaluate_expression("{{ page.title }}", context, allow_nil: false)).to eq("Test Title")
      end

      it "returns the literal when allow_nil is false and token is not a lookup" do
        expect(evaluator.evaluate_expression("literal-value", context, allow_nil: false)).to eq("literal-value")
      end

      it "returns stripped content when allow_nil is false and quoted value is non-empty" do
        expect(evaluator.evaluate_expression('"Title"', context, allow_nil: false)).to eq("Title")
      end
    end

    context "with invalid Liquid expressions" do
      before do
        allow(Jekyll.logger).to receive(:debug)
      end

      it "falls back to literal string on syntax error" do
        result = evaluator.evaluate_expression("{{ invalid", context)
        expect(result).to eq("{{ invalid")
      end

      it "handles malformed tags" do
        result = evaluator.evaluate_expression("{% invalid %", context)
        expect(result).to eq("{% invalid %")
      end

      it "logs a debug message including the token and error class on syntax failure" do
        error = begin
          Liquid::Template.parse("{{ invalid")
        rescue StandardError => e
          e
        end
        evaluator.evaluate_expression("{{ invalid", context)
        expect(Jekyll.logger).to have_received(:debug).with(
          "HighlightCards:",
          a_string_including("{{ invalid", error.class.to_s, error.to_s)
        )
      end

      it "falls back to literal string on syntax error when allow_nil is false" do
        expect(evaluator.evaluate_expression("{{ invalid", context, allow_nil: false)).to eq("{{ invalid")
      end
    end

    context "with edge cases" do
      it "handles empty string" do
        result = evaluator.evaluate_expression("", context)
        expect(result).to eq("")
      end

      it "handles whitespace" do
        result = evaluator.evaluate_expression("   ", context)
        expect(result).to eq("   ")
      end

      it "handles special characters" do
        result = evaluator.evaluate_expression("<script>alert('xss')</script>", context)
        expect(result).to eq("<script>alert('xss')</script>")
      end
    end
  end

  describe "#variable_lookup?" do
    it "returns true for Liquid variable syntax" do
      expect(evaluator.variable_lookup?("{{ page.title }}")).to be true
    end

    it "returns true for Liquid tag syntax" do
      expect(evaluator.variable_lookup?("{% if true %}")).to be true
    end

    it "returns false for literal strings" do
      expect(evaluator.variable_lookup?("literal-string")).to be false
    end

    it "returns false for quoted strings" do
      expect(evaluator.variable_lookup?('"quoted"')).to be false
    end

    it "returns false for nil" do
      expect(evaluator.variable_lookup?(nil)).to be false
    end

    it "returns false for empty string" do
      expect(evaluator.variable_lookup?("")).to be false
    end
  end

  describe "#quote_wrapped?" do
    it "returns true for matching double quotes" do
      expect(evaluator.quote_wrapped?('"value"')).to be true
    end

    it "returns true for matching single quotes" do
      expect(evaluator.quote_wrapped?("'value'")).to be true
    end

    it "returns true for empty double-quoted string" do
      expect(evaluator.quote_wrapped?('""')).to be true
    end

    it "returns true for empty single-quoted string" do
      expect(evaluator.quote_wrapped?("''")).to be true
    end

    it "returns false for unquoted strings" do
      expect(evaluator.quote_wrapped?("value")).to be false
    end

    it "returns false for a single double-quote character" do
      expect(evaluator.quote_wrapped?('"')).to be false
    end

    it "returns false for a single single-quote character" do
      expect(evaluator.quote_wrapped?("'")).to be false
    end

    it "returns false for empty string" do
      expect(evaluator.quote_wrapped?("")).to be false
    end

    it "returns false when double quotes are mismatched" do
      expect(evaluator.quote_wrapped?('"value')).to be false
    end

    it "returns false when only the end has a double quote" do
      expect(evaluator.quote_wrapped?('value"')).to be false
    end

    it "returns false when single quotes are mismatched at the end" do
      expect(evaluator.quote_wrapped?("'value")).to be false
    end

    it "returns false when only the end has a single quote" do
      expect(evaluator.quote_wrapped?("value'")).to be false
    end

    it "returns false for mixed quote styles" do
      expect(evaluator.quote_wrapped?("\"value'")).to be false
    end
  end

  describe "#strip_outer_quotes" do
    it "strips double quotes" do
      expect(evaluator.strip_outer_quotes('"value"')).to eq("value")
    end

    it "strips single quotes" do
      expect(evaluator.strip_outer_quotes("'value'")).to eq("value")
    end

    it "does not strip mismatched quotes" do
      expect(evaluator.strip_outer_quotes("\"value'")).to eq("\"value'")
    end

    it "does not strip inner quotes" do
      expect(evaluator.strip_outer_quotes('say "hello"')).to eq('say "hello"')
    end

    it "handles empty quoted string" do
      expect(evaluator.strip_outer_quotes('""')).to eq("")
    end

    it "handles single character quoted string" do
      expect(evaluator.strip_outer_quotes('"x"')).to eq("x")
    end

    it "returns unquoted strings unchanged" do
      expect(evaluator.strip_outer_quotes("unquoted")).to eq("unquoted")
    end

    it "handles nil" do
      expect(evaluator.strip_outer_quotes(nil)).to be_nil
    end

    it "handles empty string" do
      expect(evaluator.strip_outer_quotes("")).to eq("")
    end

    it "does not strip a lone double-quote character" do
      expect(evaluator.strip_outer_quotes('"')).to eq('"')
    end

    it "does not strip a lone single-quote character" do
      expect(evaluator.strip_outer_quotes("'")).to eq("'")
    end

    it "requires matching single quotes on both ends" do
      expect(evaluator.strip_outer_quotes("'value")).to eq("'value")
    end
  end

  describe "logging methods" do
    before do
      allow(Jekyll.logger).to receive(:debug)
      allow(Jekyll.logger).to receive(:info)
      allow(Jekyll.logger).to receive(:warn)
      allow(Jekyll.logger).to receive(:error)
    end

    it "#log_debug logs debug messages" do
      evaluator.log_debug("test message")
      expect(Jekyll.logger).to have_received(:debug).with("HighlightCards:", "test message")
    end

    it "#log_info logs info messages" do
      evaluator.log_info("test message")
      expect(Jekyll.logger).to have_received(:info).with("HighlightCards:", "test message")
    end

    it "#log_warn logs warning messages" do
      evaluator.log_warn("test message")
      expect(Jekyll.logger).to have_received(:warn).with("HighlightCards:", "test message")
    end

    it "#log_error logs error messages" do
      evaluator.log_error("test message")
      expect(Jekyll.logger).to have_received(:error).with("HighlightCards:", "test message")
    end
  end
end
