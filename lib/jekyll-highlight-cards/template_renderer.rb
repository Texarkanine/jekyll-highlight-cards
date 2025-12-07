# frozen_string_literal: true

module JekyllHighlightCards
  # Module for rendering Liquid templates with user override support
  module TemplateRenderer
    # Render a template with given variables
    #
    # @param site [Jekyll::Site] the Jekyll site object
    # @param template_name [String] template name (e.g., "linkcard", "polaroid")
    # @param variables [Hash] variables to pass to template
    # @return [String] rendered HTML
    def render_template(site, template_name, variables)
      template_path = find_template_path(site, template_name)

      raise "Template not found: #{template_name}" if template_path.nil?

      template_content = File.read(template_path)
      template = Liquid::Template.parse(template_content)
      template.render(variables)
    end

    # Find template file path, checking user override first, then gem default
    #
    # @param site [Jekyll::Site] the Jekyll site object
    # @param template_name [String] template name without .html extension
    # @return [String, nil] path to template file or nil if not found
    def find_template_path(site, template_name)
      template_filename = "#{template_name}.html"
      relative_path = File.join("highlight-cards", template_filename)

      # Check for user override in site's _includes directory
      if site&.source
        user_template_path = File.join(site.source, "_includes", relative_path)
        return user_template_path if File.exist?(user_template_path)
      end

      # Fall back to gem bundled template
      gem_root = File.expand_path("../..", __dir__)
      gem_template_path = File.join(gem_root, "_includes", relative_path)
      return gem_template_path if File.exist?(gem_template_path)

      nil
    end
  end
end
