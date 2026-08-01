# frozen_string_literal: true

module JekyllHighlightCards
  # Internet Archive integration for automatic URL archival
  #
  # Provides methods for looking up existing archives and submitting
  # URLs to the Internet Archive's Wayback Machine. Results are cached
  # per-site-build to avoid redundant API calls.
  #
  # @example Enable archiving
  #   export JEKYLL_HIGHLIGHT_CARDS_ARCHIVE=1
  #
  # @example Enable auto-submission
  #   export JEKYLL_HIGHLIGHT_CARDS_ARCHIVE_SAVE=1
  module ArchiveHelper
    # Shared cache for archive URLs across all tag instances
    @archive_cache = {}

    class << self
      attr_accessor :archive_cache
    end

    # Get archive URL for a given URL, with caching and optional submission
    #
    # @param url [String] the original URL to archive
    # @return [String, nil] the archive URL, or nil if not found
    def archive_url_for(url)
      return nil unless archiveable_url?(url)

      ArchiveHelper.archive_cache[url] ||= begin
        archive_url = lookup_archive(url)

        archive_url = submit_archive(url) || archive_url if archive_save_enabled?

        archive_url
      end
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

    # Whether +url+ is eligible for CDX lookup / SavePageNow submission.
    #
    # Requires an absolute http(s) URI with a host. Rejects Internet Archive
    # hosts so Wayback / archive.org URLs are not re-submitted.
    #
    # @param url [String] candidate URL
    # @return [Boolean] true if the URL may be archived
    def archiveable_url?(url)
      uri = URI.parse(url.to_s)
      return false unless uri.is_a?(URI::HTTP) && uri.host
      return false if %w[archive.org web.archive.org].include?(uri.host.downcase)

      true
    rescue URI::InvalidURIError
      false
    end

    # Look up the latest archived snapshot for a URL via Internet Archive CDX API
    #
    # @param url [String] the URL to look up
    # @return [String, nil] the archive URL if found, nil otherwise
    def lookup_archive(url)
      encoded_url = URI.encode_www_form_component(url)
      cdx_url_str = "https://web.archive.org/cdx/search/cdx?url=#{encoded_url}&output=json&filter=statuscode:200&limit=-1&fl=timestamp,original"
      cdx_url = URI.parse(cdx_url_str)

      response = Net::HTTP.start(
        cdx_url.host,
        cdx_url.port,
        use_ssl: cdx_url.scheme == "https",
        open_timeout: 10,
        read_timeout: 30
      ) do |http|
        http.request(Net::HTTP::Get.new(cdx_url.request_uri))
      end

      return nil unless response.is_a?(Net::HTTPSuccess)

      rows = JSON.parse(response.body)

      return nil if rows.size < 2

      timestamp, = rows.last
      "https://web.archive.org/web/#{timestamp}/#{url}"
    rescue StandardError
      nil
    end

    # Submit a URL to Internet Archive SavePageNow service
    #
    # @param url [String] the URL to submit for archiving
    # @return [String, nil] the archive URL if successful, nil otherwise
    def submit_archive(url)
      encoded_url = URI.encode_www_form_component(url)
      save_url = URI.parse("https://web.archive.org/save/#{encoded_url}")

      response = begin
        Net::HTTP.start(
          save_url.host,
          save_url.port,
          use_ssl: save_url.scheme == "https",
          open_timeout: 10,
          read_timeout: 30
        ) do |http|
          req = Net::HTTP::Get.new(save_url.request_uri, { "User-Agent" => archive_user_agent })
          http.request(req)
        end
      rescue StandardError
        nil
      end
      return nil if response.nil?

      location = response["content-location"]
      return nil if location.to_s.empty?

      "https://web.archive.org#{location}"
    end
  end
end
