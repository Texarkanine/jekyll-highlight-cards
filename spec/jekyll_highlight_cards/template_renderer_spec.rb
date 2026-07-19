# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

RSpec.describe JekyllHighlightCards::TemplateRenderer do
  let(:renderer) do
    Class.new do
      include JekyllHighlightCards::TemplateRenderer
    end.new
  end

  let(:test_template_content) do
    <<~LIQUID
      <div class="test">
        <span>{{ title }}</span>
        <a href="{{ url }}">{{ display_url }}</a>
      </div>
    LIQUID
  end

  describe "#safe_template_path" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:allowed_dir) { File.join(temp_dir, "allowed") }

    before { FileUtils.mkdir_p(allowed_dir) }
    after { FileUtils.rm_rf(temp_dir) }

    it "returns the path when the file exists inside the allowed directory" do
      template_path = File.join(allowed_dir, "card.html")
      File.write(template_path, "<div/>")
      expect(renderer.safe_template_path(allowed_dir, template_path)).to eq(template_path)
    end

    it "returns nil when the file does not exist" do
      missing = File.join(allowed_dir, "missing.html")
      expect(renderer.safe_template_path(allowed_dir, missing)).to be_nil
    end

    it "returns nil when expand_path escapes the allowed directory via parent segments" do
      outside_dir = File.join(temp_dir, "outside")
      FileUtils.mkdir_p(outside_dir)
      outside = File.join(outside_dir, "secret.html")
      File.write(outside, "secret")
      escape_path = File.join(allowed_dir, "..", "outside", "secret.html")

      expect(File.exist?(escape_path)).to be true
      expect(renderer.safe_template_path(allowed_dir, escape_path)).to be_nil
    end

    it "expands relative allowed_dir before the prefix check" do
      template_path = File.join(allowed_dir, "card.html")
      File.write(template_path, "<div/>")
      Dir.chdir(temp_dir) do
        expect(renderer.safe_template_path("allowed", template_path)).to eq(template_path)
      end
    end
  end

  describe "#find_template_path" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:site_source) { File.join(temp_dir, "site") }
    let(:user_template_dir) { File.join(site_source, "_includes", "highlight-cards") }
    let(:mock_site) { instance_double(Jekyll::Site, source: site_source) }
    let(:gem_root) { File.expand_path("../..", __dir__) }
    let(:gem_template_path) { File.join(gem_root, "_includes/highlight-cards/linkcard.html") }

    before { FileUtils.mkdir_p(user_template_dir) }
    after { FileUtils.rm_rf(temp_dir) }

    context "when user override exists" do
      it "returns the user override path" do
        user_path = File.join(user_template_dir, "test.html")
        File.write(user_path, "<div>user</div>")
        expect(renderer.find_template_path(mock_site, "test")).to eq(user_path)
      end
    end

    context "when only gem default exists" do
      it "returns the gem template path" do
        expect(renderer.find_template_path(mock_site, "linkcard")).to eq(gem_template_path)
      end
    end

    context "when template does not exist" do
      it "returns nil" do
        expect(renderer.find_template_path(mock_site, "nonexistent")).to be_nil
      end
    end

    context "when site is nil" do
      it "falls back to gem template" do
        expect(renderer.find_template_path(nil, "linkcard")).to eq(gem_template_path)
      end
    end

    context "when site source is empty" do
      let(:mock_site) { instance_double(Jekyll::Site, source: "") }

      it "skips the user includes directory and uses the gem template" do
        expect(renderer.find_template_path(mock_site, "linkcard")).to eq(gem_template_path)
      end

      it "does not join a user includes path when source is empty" do
        allow(File).to receive(:join).and_call_original
        renderer.find_template_path(mock_site, "linkcard")
        expect(File).not_to have_received(:join).with("", "_includes")
      end
    end

    context "when site source is not a String" do
      it "skips the user includes directory and uses the gem template" do
        site = instance_double(Jekyll::Site, source: :not_a_path)
        expect(renderer.find_template_path(site, "linkcard")).to eq(gem_template_path)
      end
    end

    context "when site source is a String subclass" do
      it "still resolves a user override from that source path" do
        user_path = File.join(user_template_dir, "subclass.html")
        File.write(user_path, "<div>subclass</div>")
        source = Class.new(String).new(site_source)
        site = instance_double(Jekyll::Site, source: source)
        expect(renderer.find_template_path(site, "subclass")).to eq(user_path)
      end
    end

    context "when site source is nil" do
      let(:mock_site) { instance_double(Jekyll::Site, source: nil) }

      it "skips the user includes directory and uses the gem template" do
        expect(renderer.find_template_path(mock_site, "linkcard")).to eq(gem_template_path)
      end
    end

    context "with invalid template names (path traversal protection)" do
      it "rejects template names with path separators" do
        expect do
          renderer.find_template_path(mock_site, "../../../etc/passwd")
        end.to raise_error(ArgumentError, /Invalid template name/)
      end

      it "rejects template names with dots" do
        expect do
          renderer.find_template_path(mock_site, "..password")
        end.to raise_error(ArgumentError, /Invalid template name/)
      end

      it "rejects template names with slashes" do
        expect do
          renderer.find_template_path(mock_site, "subdir/template")
        end.to raise_error(ArgumentError, /Invalid template name/)
      end

      it "rejects template names with special characters" do
        expect do
          renderer.find_template_path(mock_site, "temp@late")
        end.to raise_error(ArgumentError, /Invalid template name/)
      end

      it "accepts valid template names with hyphens" do
        expect do
          renderer.find_template_path(mock_site, "link-card")
        end.not_to raise_error
      end

      it "accepts valid template names with underscores" do
        expect do
          renderer.find_template_path(mock_site, "link_card")
        end.not_to raise_error
      end

      it "accepts valid template names with numbers" do
        expect do
          renderer.find_template_path(mock_site, "template123")
        end.not_to raise_error
      end
    end
  end

  describe "#render_template" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:site_source) { File.join(temp_dir, "site") }
    let(:template_dir) { File.join(site_source, "_includes", "highlight-cards") }
    let(:mock_site) { instance_double(Jekyll::Site, source: site_source) }
    let(:variables) do
      {
        "title" => "Test Title",
        "url" => "https://example.com",
        "display_url" => "example.com"
      }
    end

    before { FileUtils.mkdir_p(template_dir) }
    after { FileUtils.rm_rf(temp_dir) }

    context "when template is found" do
      before do
        File.write(File.join(template_dir, "test.html"), test_template_content)
      end

      it "renders the template with variables" do
        result = renderer.render_template(mock_site, "test", variables)

        expect(result).to include("Test Title")
        expect(result).to include("https://example.com")
        expect(result).to include("example.com")
        expect(result).to include('<div class="test">')
      end

      it "handles empty variables" do
        result = renderer.render_template(mock_site, "test", {})

        expect(result).to include('<div class="test">')
        expect(result).not_to include("Test Title")
      end
    end

    context "when template is not found" do
      it "raises TemplateNotFoundError naming the template" do
        expect do
          renderer.render_template(mock_site, "nonexistent", {})
        end.to raise_error(
          JekyllHighlightCards::TemplateNotFoundError,
          "Template not found: nonexistent"
        )
      end
    end

    context "when File.read raises Errno::ENOENT" do
      before do
        File.write(File.join(template_dir, "test.html"), test_template_content)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(File.join(template_dir, "test.html")).and_raise(
          Errno::ENOENT, "No such file"
        )
      end

      it "raises TemplateRenderError with class and path context" do
        path = File.join(template_dir, "test.html")
        expect do
          renderer.render_template(mock_site, "test", {})
        end.to raise_error(
          JekyllHighlightCards::TemplateRenderError,
          "Failed to read template 'test' at #{path}: Errno::ENOENT: No such file or directory - No such file"
        )
      end
    end

    context "when File.read raises Encoding::InvalidByteSequenceError" do
      before do
        File.write(File.join(template_dir, "test.html"), test_template_content)
        encoding_error = Encoding::InvalidByteSequenceError.new("invalid byte")
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(File.join(template_dir, "test.html")).and_raise(encoding_error)
      end

      it "raises TemplateRenderError with encoding context" do
        path = File.join(template_dir, "test.html")
        expect do
          renderer.render_template(mock_site, "test", {})
        end.to raise_error(
          JekyllHighlightCards::TemplateRenderError,
          "Invalid encoding in template 'test' at #{path}: Encoding::InvalidByteSequenceError: invalid byte"
        )
      end
    end

    context "when template has Liquid syntax error" do
      before do
        File.write(File.join(template_dir, "invalid.html"), "<div>{{ unclosed tag")
      end

      it "raises TemplateRenderError with Liquid class context" do
        begin
          Liquid::Template.parse("<div>{{ unclosed tag")
        rescue StandardError => e
          @expected = "Liquid error in template 'invalid': #{e.class}: #{e}"
        end
        expect do
          renderer.render_template(mock_site, "invalid", {})
        end.to raise_error(JekyllHighlightCards::TemplateRenderError, @expected)
      end
    end

    context "when Liquid raises an unexpected StandardError" do
      before do
        File.write(File.join(template_dir, "test.html"), test_template_content)
        allow(Liquid::Template).to receive(:parse).and_raise(RuntimeError, "boom")
      end

      it "raises TemplateRenderError with unexpected-error context" do
        expect do
          renderer.render_template(mock_site, "test", {})
        end.to raise_error(JekyllHighlightCards::TemplateRenderError) { |error|
          expect(error.message).to eq(
            "Unexpected error rendering template 'test': RuntimeError: boom"
          )
        }
      end
    end

    context "with complex template" do
      let(:complex_template_content) do
        <<~LIQUID
          <div class="card">
            {% if title %}
              <h1>{{ title }}</h1>
            {% endif %}
            <a href="{{ url }}">{{ display_url }}</a>
            {% if archive_url %}
              <small>(<a href="{{ archive_url }}">archive</a>)</small>
            {% endif %}
          </div>
        LIQUID
      end

      before do
        File.write(File.join(template_dir, "complex.html"), complex_template_content)
      end

      it "handles conditionals with all variables present" do
        vars = variables.merge("archive_url" => "https://archive.org/test")
        result = renderer.render_template(mock_site, "complex", vars)

        expect(result).to include("<h1>Test Title</h1>")
        expect(result).to include("https://archive.org/test")
      end

      it "handles conditionals with missing variables" do
        result = renderer.render_template(mock_site, "complex", variables)

        expect(result).to include("<h1>Test Title</h1>")
        expect(result).not_to include("archive")
      end
    end
  end
end
