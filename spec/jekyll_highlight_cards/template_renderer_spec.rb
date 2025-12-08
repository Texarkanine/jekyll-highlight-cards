# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

RSpec.describe JekyllHighlightCards::TemplateRenderer do
  # Create a test class that includes the module
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

  describe "#find_template_path" do
    let(:mock_site) { instance_double(Jekyll::Site, source: "/test/site") }

    context "when user override exists" do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?)
          .with("/test/site/_includes/highlight-cards/test.html")
          .and_return(true)
      end

      it "returns the user override path" do
        result = renderer.find_template_path(mock_site, "test")
        expect(result).to eq("/test/site/_includes/highlight-cards/test.html")
      end
    end

    context "when only gem default exists" do
      let(:gem_root) { File.expand_path("../..", __dir__) }
      let(:gem_template_path) { File.join(gem_root, "_includes/highlight-cards/test.html") }

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?)
          .with("/test/site/_includes/highlight-cards/test.html")
          .and_return(false)
        allow(File).to receive(:exist?)
          .with(gem_template_path)
          .and_return(true)
      end

      it "returns the gem template path" do
        result = renderer.find_template_path(mock_site, "test")
        expect(result).to eq(gem_template_path)
      end
    end

    context "when template does not exist" do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "returns nil" do
        result = renderer.find_template_path(mock_site, "nonexistent")
        expect(result).to be_nil
      end
    end

    context "when site is nil" do
      let(:gem_root) { File.expand_path("../..", __dir__) }
      let(:gem_template_path) { File.join(gem_root, "_includes/highlight-cards/test.html") }

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?)
          .with(gem_template_path)
          .and_return(true)
      end

      it "falls back to gem template" do
        result = renderer.find_template_path(nil, "test")
        expect(result).to eq(gem_template_path)
      end
    end

    context "with invalid template names (path traversal protection)" do
      let(:mock_site) { instance_double(Jekyll::Site, source: "/test/site") }

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
        allow(File).to receive(:exist?).and_return(false)
        expect do
          renderer.find_template_path(mock_site, "link-card")
        end.not_to raise_error
      end

      it "accepts valid template names with underscores" do
        allow(File).to receive(:exist?).and_return(false)
        expect do
          renderer.find_template_path(mock_site, "link_card")
        end.not_to raise_error
      end

      it "accepts valid template names with numbers" do
        allow(File).to receive(:exist?).and_return(false)
        expect do
          renderer.find_template_path(mock_site, "template123")
        end.not_to raise_error
      end
    end
  end

  describe "#render_template" do
    let(:mock_site) { instance_double(Jekyll::Site, source: nil) }
    let(:variables) do
      {
        "title" => "Test Title",
        "url" => "https://example.com",
        "display_url" => "example.com"
      }
    end

    context "when template is found" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:template_dir) { File.join(temp_dir, "_includes", "highlight-cards") }
      let(:template_path) { File.join(template_dir, "test.html") }

      before do
        FileUtils.mkdir_p(template_dir)
        File.write(template_path, test_template_content)

        allow(renderer).to receive(:find_template_path)
          .with(mock_site, "test")
          .and_return(template_path)
      end

      after do
        FileUtils.rm_rf(temp_dir)
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
      before do
        allow(renderer).to receive(:find_template_path)
          .with(mock_site, "nonexistent")
          .and_return(nil)
      end

      it "raises TemplateNotFoundError" do
        expect do
          renderer.render_template(mock_site, "nonexistent", {})
        end.to raise_error(JekyllHighlightCards::TemplateNotFoundError, /Template not found: nonexistent/)
      end
    end

    context "when template has Liquid syntax error" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:template_dir) { File.join(temp_dir, "_includes", "highlight-cards") }
      let(:template_path) { File.join(template_dir, "invalid.html") }
      let(:invalid_template_content) { "<div>{{ unclosed tag" }

      before do
        FileUtils.mkdir_p(template_dir)
        File.write(template_path, invalid_template_content)

        allow(renderer).to receive(:find_template_path)
          .with(mock_site, "invalid")
          .and_return(template_path)
      end

      after do
        FileUtils.rm_rf(temp_dir)
      end

      it "raises TemplateRenderError with context" do
        expect do
          renderer.render_template(mock_site, "invalid", {})
        end.to raise_error(JekyllHighlightCards::TemplateRenderError, /Liquid error in template 'invalid'/)
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

      let(:temp_dir) { Dir.mktmpdir }
      let(:template_dir) { File.join(temp_dir, "_includes", "highlight-cards") }
      let(:template_path) { File.join(template_dir, "complex.html") }

      before do
        FileUtils.mkdir_p(template_dir)
        File.write(template_path, complex_template_content)

        allow(renderer).to receive(:find_template_path)
          .with(mock_site, "complex")
          .and_return(template_path)
      end

      after do
        FileUtils.rm_rf(temp_dir)
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
