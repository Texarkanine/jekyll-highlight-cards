# frozen_string_literal: true

module JekyllHighlightCards
  # Module for Internet Archive integration functionality
  # Provides archive URL lookup, submission, and caching
  module ArchiveHelper
    # Shared cache for archive URLs across all tag instances
    @@archive_cache = {}

    # Get archive URL for a given URL, with caching and optional submission
    #
    # @param url [String] the original URL to archive
    # @return [String] the archive URL, or empty string if not found
    def archive_url_for(url)
      @@archive_cache[url] ||= begin
        log_info("Looking up archive for #{url}")
        archive_url = lookup_archive(url) || ""
        log_info("Archive URL: #{archive_url}")

        if archive_save_enabled?
          log_info("Submitting to SavePageNow: #{url}")
          archive_url = submit_archive(url) || archive_url
          log_info("SavePageNow archived #{url} -> #{archive_url}")
        end

        archive_url
      end
    rescue StandardError => e
      log_debug("Archive lookup failed for #{url}: #{e.message}")
      ""
    end

    # Check if archiving is enabled via environment variables
    #
    # @return [Boolean] true if archiving is enabled
    def archive_enabled?
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE"] == "1" || archive_save_enabled?
    end

    # Check if SavePageNow submission is enabled
    #
    # @return [Boolean] true if submission is enabled
    def archive_save_enabled?
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE"] == "1"
    end

    # Get User-Agent string for archive HTTP requests
    #
    # @return [String] User-Agent header value
    def archive_user_agent
      ENV["JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_UA"] ||
        "jekyll:highlight-cards (+#{ENV.fetch("JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_CONTACT", "mailto:unknown")})"
    end

    private

    # Look up the latest archived snapshot for a URL via Internet Archive CDX API
    #
    # @param url [String] the URL to look up
    # @return [String, nil] the archive URL if found, nil otherwise
    def lookup_archive(url)
      log_debug("lookup_archive(#{url})")

      encoded_url = URI.encode_www_form_component(url)
      cdx_url_str = "https://web.archive.org/cdx/search/cdx?url=#{encoded_url}&output=json&filter=statuscode:200&limit=-1&fl=timestamp,original"
      cdx_url = URI.parse(cdx_url_str)

      log_debug("CDX lookup URL: #{cdx_url_str}")

      response = Net::HTTP.start(
        cdx_url.host,
        cdx_url.port,
        use_ssl: cdx_url.scheme == "https",
        open_timeout: 10,
        read_timeout: 30
      ) do |http|
        http.request(Net::HTTP::Get.new(cdx_url.request_uri))
      end

      unless response.is_a?(Net::HTTPSuccess)
        log_debug("CDX lookup failed: #{response.code} #{response.message}")
        return nil
      end

      log_debug("CDX lookup found archived page...")
      rows = JSON.parse(response.body)

      # First row is header, so we need at least 2 rows
      return nil if rows.length <= 1

      latest = rows.last
      timestamp = latest[0]
      archive_url = "https://web.archive.org/web/#{timestamp}/#{url}"

      log_debug("CDX lookup found archived page: #{archive_url}")
      archive_url
    rescue StandardError => e
      log_debug("CDX lookup error for #{url}: #{e.message}")
      nil
    end

    # Submit a URL to Internet Archive SavePageNow service
    #
    # @param url [String] the URL to submit for archiving
    # @return [String, nil] the archive URL if successful, nil otherwise
    def submit_archive(url)
      log_debug("submit_archive(#{url})")

      encoded_url = URI.encode_www_form_component(url)
      save_url = URI.parse("https://web.archive.org/save/#{encoded_url}")

      response = Net::HTTP.start(
        save_url.host,
        save_url.port,
        use_ssl: save_url.scheme == "https",
        open_timeout: 10,
        read_timeout: 30
      ) do |http|
        req = Net::HTTP::Get.new(save_url.request_uri, { "User-Agent" => archive_user_agent })
        http.request(req)
      end

      location = response["content-location"]

      if location && !location.empty?
        archive_url = "https://web.archive.org#{location}"
        log_info("SavePageNow archived #{url} -> #{archive_url}")
        archive_url
      else
        log_debug("Archive submission returned no location for #{url}")
        nil
      end
    rescue StandardError => e
      log_debug("Archive submission error for #{url}: #{e.message}")
      nil
    end
  end
end
