# frozen_string_literal: true

module JekyllHighlightCards
  module Commands
    # Opt-in Jekyll subcommand: +jekyll freeze-archives+
    #
    # Scans site source for archive-eligible +linkcard+ / +polaroid+ tags that
    # lack an encoded archive, looks up Internet Archive, and surgically inserts
    # successful hits into source. Does not run during +jekyll build+.
    #
    # @see https://jekyllrb.com/docs/plugins/commands/
    class FreezeArchives < Jekyll::Command
      class << self
        # Register the +freeze-archives+ Mercenary subcommand
        #
        # @param prog [Mercenary::Program] the Jekyll CLI program
        # @return [void]
        def init_with_program(prog)
          prog.command(:"freeze-archives") do |c|
            c.syntax "freeze-archives [options]"
            c.description "Freeze Internet Archive URLs into highlight-card source tags"

            c.option "dry_run", "--dry-run", "Report planned edits without writing files"
            c.option "save", "--save", "Enable SavePageNow when CDX has no snapshot"
            c.option "config", "--config CONFIG_FILE[,CONFIG_FILE2,...]", Array,
                     "Custom configuration file"
            c.option "source", "-s", "--source SOURCE", "Custom source directory"

            c.action do |_args, options|
              process(options)
            end
          end
        end

        # Run freeze-archives against a configured site
        #
        # @param options [Hash] Mercenary/Jekyll options (+dry_run+, +save+, +source+, …)
        # @return [Hash] summary counts +:frozen+, +:skipped+, +:miss+, +:written+
        def process(options)
          previous_save = ENV.fetch("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE", nil)
          ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = "1" if options["save"]

          site = Jekyll::Site.new(configuration_from_options(options))
          site.read

          summary = Runner.new(
            dry_run: options["dry_run"],
            logger: Jekyll.logger
          ).run(site)

          Jekyll.logger.info "freeze-archives:",
                             "frozen=#{summary[:frozen]} skipped=#{summary[:skipped]} " \
                             "miss=#{summary[:miss]} written=#{summary[:written]}"
          summary
        ensure
          restore_save_env(previous_save, options)
        end

        private

        def restore_save_env(previous_save, options)
          return unless options && options["save"]

          if previous_save.nil?
            ENV.delete("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE")
          else
            ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] = previous_save
          end
        end
      end

      # Orchestrates locate → analyze → lookup → insert for one site
      class Runner
        include ArchiveHelper

        def initialize(dry_run:, logger:)
          @dry_run = dry_run
          @logger = logger
          @locator = JekyllHighlightCards::FreezeArchives::TagLocator.new
          @analyzer = JekyllHighlightCards::FreezeArchives::MarkupAnalyzer.new
          @inserter = JekyllHighlightCards::FreezeArchives::ArchiveInserter.new
        end

        # @param site [Jekyll::Site]
        # @return [Hash] summary counts
        def run(site)
          summary = { frozen: 0, skipped: 0, miss: 0, written: 0 }

          source_files(site).each do |path|
            process_file(path, summary)
          end

          summary
        end

        private

        def source_files(site)
          paths = site.pages.map { |page| resolve_source_path(site, page.path) }
          site.collections.each_value do |collection|
            paths.concat(collection.docs.map { |doc| resolve_source_path(site, doc.path) })
          end

          paths.compact.uniq.select do |path|
            File.file?(path) && path.start_with?(site.source)
          end
        end

        # Jekyll::Page#path is source-relative; Document#path is absolute.
        def resolve_source_path(site, path)
          return nil if path.to_s.empty?
          return path if File.absolute_path?(path)

          site.in_source_dir(path)
        end

        def process_file(path, summary)
          content = File.read(path)
          spans = @locator.locate(content)
          return if spans.empty?

          edits = []
          spans.each do |span|
            candidate = @analyzer.analyze(span[:tag], span[:markup])
            unless candidate
              summary[:skipped] += 1
              next
            end

            archive_url = archive_url_for(candidate[:target_url])
            unless archive_url
              summary[:miss] += 1
              next
            end

            summary[:frozen] += 1
            edits << { span: span, archive_url: archive_url }
          end

          return if edits.empty?

          if @dry_run
            edits.each do |edit|
              @logger.info "freeze-archives:",
                           "would freeze #{path} ← #{edit[:archive_url]}"
            end
            return
          end

          # Apply from end of file so earlier ranges stay valid
          updated = content
          edits.sort_by { |e| -e[:span][:range].begin }.each do |edit|
            updated = @inserter.insert(updated, edit[:span], edit[:archive_url])
          end

          return if updated == content

          File.write(path, updated)
          summary[:written] += 1
        end
      end
    end
  end
end
