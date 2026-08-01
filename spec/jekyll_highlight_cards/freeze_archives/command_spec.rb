# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"
require "mercenary"

RSpec.describe JekyllHighlightCards::Commands::FreezeArchives do
  # C1–C6: freeze-archives command integration against a temp site

  let(:archive_url) { "https://web.archive.org/web/20200101120000/https://example.com" }
  let(:target_url) { "https://example.com" }

  def write_site(dir, post_body)
    File.write(File.join(dir, "_config.yml"), "title: Freeze Test\n")
    FileUtils.mkdir_p(File.join(dir, "_posts"))
    path = File.join(dir, "_posts", "2020-01-01-hello.md")
    File.write(path, post_body)
    path
  end

  def site_options(dir)
    {
      "source" => dir,
      "destination" => File.join(dir, "_site"),
      "quiet" => true
    }
  end

  def stub_cdx_hit
    stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
      .to_return(
        status: 200,
        body: [%w[timestamp original], ["20200101120000", target_url]].to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_cdx_miss
    stub_request(:get, %r{web\.archive\.org/cdx/search/cdx})
      .to_return(status: 200, body: [%w[timestamp original]].to_json)
  end

  before do
    JekyllHighlightCards::ArchiveHelper.archive_cache = {}
  end

  describe ".process" do
    it "C1: --dry-run with CDX hit reports a planned edit and leaves the file unchanged" do
      Dir.mktmpdir do |dir|
        post = write_site(dir, <<~MD)
          ---
          title: Hello
          ---
          {% linkcard https://example.com Title %}
        MD
        original = File.read(post)
        stub_cdx_hit

        summary = described_class.process(site_options(dir).merge("dry_run" => true))

        expect(File.read(post)).to eq(original)
        expect(summary[:frozen]).to eq(1)
        expect(summary[:written]).to eq(0)
        expect(ENV.fetch("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE", nil)).to be_nil
      end
    end

    it "C2: write mode with CDX hit updates source without ARCHIVE=1" do
      Dir.mktmpdir do |dir|
        post = write_site(dir, <<~MD)
          ---
          title: Hello
          ---
          {% linkcard https://example.com Title %}
        MD
        stub_cdx_hit

        summary = described_class.process(site_options(dir))

        expect(ENV.fetch("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE", nil)).to be_nil
        expect(File.read(post)).to include("archive:#{archive_url}")
        expect(summary[:frozen]).to eq(1)
        expect(summary[:written]).to eq(1)
      end
    end

    it "C3: CDX miss leaves the file unchanged" do
      Dir.mktmpdir do |dir|
        post = write_site(dir, <<~MD)
          ---
          title: Hello
          ---
          {% linkcard https://example.com Title %}
        MD
        original = File.read(post)
        stub_cdx_miss

        summary = described_class.process(site_options(dir))

        expect(File.read(post)).to eq(original)
        expect(summary[:miss]).to eq(1)
        expect(summary[:written]).to eq(0)
      end
    end

    it "C4: tags that already have archive are left unchanged" do
      Dir.mktmpdir do |dir|
        post = write_site(dir, <<~MD)
          ---
          title: Hello
          ---
          {% linkcard https://example.com Title archive:https://web.archive.org/web/1999/https://example.com %}
        MD
        original = File.read(post)

        summary = described_class.process(site_options(dir))

        expect(File.read(post)).to eq(original)
        expect(summary[:frozen]).to eq(0)
        expect(summary[:skipped]).to be >= 1
        expect(WebMock).not_to have_requested(:get, %r{web\.archive\.org/cdx/search/cdx})
      end
    end

    it "C5: --save triggers SavePageNow when CDX is empty" do
      Dir.mktmpdir do |dir|
        post = write_site(dir, <<~MD)
          ---
          title: Hello
          ---
          {% linkcard https://example.com Title %}
        MD
        stub_cdx_miss
        save_stub = stub_request(:get, %r{web\.archive\.org/save/})
                    .to_return(
                      status: 200,
                      headers: { "Content-Location" => "/web/20200101120000/https://example.com" }
                    )

        summary = described_class.process(site_options(dir).merge("save" => true))

        expect(save_stub).to have_been_requested
        expect(File.read(post)).to include("archive:#{archive_url}")
        expect(summary[:frozen]).to eq(1)
        expect(ENV.fetch("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE", nil)).to be_nil
      end
    end

    it "C6: jekyll build alone does not rewrite sources" do
      Dir.mktmpdir do |dir|
        post = write_site(dir, <<~MD)
          ---
          title: Hello
          ---
          {% linkcard https://example.com Title %}
        MD
        original = File.read(post)
        stub_cdx_hit

        config = Jekyll.configuration(site_options(dir))
        site = Jekyll::Site.new(config)
        site.process

        expect(File.read(post)).to eq(original)
        freeze_generators = Jekyll::Generator.descendants.select do |klass|
          klass.name.to_s.include?("Freeze")
        end
        expect(freeze_generators).to be_empty
      end
    end
  end

  describe ".init_with_program" do
    it "registers the freeze-archives command on the program" do
      program = Mercenary::Program.new(:jekyll)
      described_class.init_with_program(program)
      expect(program.commands).to have_key(:"freeze-archives")
    end
  end
end
