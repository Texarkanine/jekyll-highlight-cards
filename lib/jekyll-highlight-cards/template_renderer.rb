# frozen_string_literal: true

module JekyllHighlightCards
  # Custom exception for template not found errors
  class TemplateNotFoundError < StandardError; end

  # Custom exception for template rendering errors
  class TemplateRenderError < StandardError; end

  # Module for rendering Liquid templates with user override support
  module TemplateRenderer
    # Render a template with given variables
    #
    # @param site [Jekyll::Site] the Jekyll site object
    # @param template_name [String] template name (e.g., "linkcard", "polaroid")
    # @param variables [Hash] variables to pass to template
    # @return [String] rendered HTML
    # @raise [TemplateNotFoundError] if template file not found
    # @raise [TemplateRenderError] if template rendering fails
    def render_template(site, template_name, variables)
      template_path = find_template_path(site, template_name)

      raise TemplateNotFoundError, "Template not found: #{template_name}" if template_path.nil?

      begin
        template_content = File.read(template_path)
        template = Liquid::Template.parse(template_content)
        template.render(variables)
      rescue Errno::ENOENT, Errno::EACCES => e
        raise TemplateRenderError, "Failed to read template '#{template_name}' at #{template_path}: #{e.class}: #{e}"
      rescue Encoding::InvalidByteSequenceError => e
        raise TemplateRenderError,
              "Invalid encoding in template '#{template_name}' at #{template_path}: #{e.class}: #{e}"
      rescue Liquid::SyntaxError, Liquid::Error => e
        raise TemplateRenderError, "Liquid error in template '#{template_name}': #{e.class}: #{e}"
      rescue StandardError => e
        raise TemplateRenderError, "Unexpected error rendering template '#{template_name}': #{e.class}: #{e}"
      end
    end

    # Find template file path, checking user override first, then gem default
    #
    # @param site [Jekyll::Site] the Jekyll site object
    # @param template_name [String] template name without .html extension
    # @return [String, nil] path to template file or nil if not found
    # @raise [ArgumentError] if template_name contains invalid characters
    def find_template_path(site, template_name)
      validate_template_name!(template_name)

      template_filename = "#{template_name}.html"
      relative_path = File.join("highlight-cards", template_filename)

      # Check for user override first
      user_path = find_user_template(site, relative_path)
      return user_path if user_path

      # Fall back to gem bundled template
      find_gem_template(relative_path)
    end

    # Verify template path is safe (within allowed directory)
    #
    # @param allowed_dir [String] the allowed base directory
    # @param template_path [String] the template path to check
    # @return [String, nil] template path if safe, nil otherwise
    def safe_template_path(allowed_dir, template_path)
      return nil unless File.exist?(template_path)

      expanded_dir = File.expand_path(allowed_dir)
      expanded_path = File.expand_path(template_path)
      template_path if expanded_path.start_with?(expanded_dir)
    end

    private

    # Validate template name to prevent path traversal attacks
    #
    # @param template_name [String] the template name to validate
    # @raise [ArgumentError] if template_name contains invalid characters
    def validate_template_name!(template_name)
      return if template_name.match?(/\A[A-Za-z0-9_-]+\z/)

      raise ArgumentError, "Invalid template name: #{template_name}. " \
                           "Must contain only letters, numbers, hyphens, and underscores."
    end

    # Find template in user's site _includes directory
    #
    # @param site [Jekyll::Site] the Jekyll site object
    # @param relative_path [String] relative path to template
    # @return [String, nil] path to template or nil
    def find_user_template(site, relative_path)
      source = site&.source
      # Empty source would File.join to "/_includes/..." — skip it explicitly.
      return nil unless source.is_a?(String) && !source.empty?

      includes_dir = File.join(source, "_includes")
      template_path = File.join(includes_dir, relative_path)

      safe_template_path(includes_dir, template_path)
    end

    # Find template in gem's bundled _includes directory
    #
    # @param relative_path [String] relative path to template
    # @return [String, nil] path to template or nil
    def find_gem_template(relative_path)
      gem_root = File.expand_path("../..", __dir__)
      includes_dir = File.join(gem_root, "_includes")
      template_path = File.join(includes_dir, relative_path)

      safe_template_path(includes_dir, template_path)
    end
  end
end
