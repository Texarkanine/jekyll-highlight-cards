# Product Context

## Target Audience

Jekyll site authors who want styled link and image cards with optional Internet Archive integration, without hand-rolling Liquid/HTML/CSS for each use.

## Use Cases

- Highlight outbound links with `{% linkcard %}` (optional title, archive URL / `archive:none`)
- Present images as polaroid-style cards with `{% polaroid %}` (size, title, alt, link, archive options)
- Specify Markdown image dimensions via `![alt](image.jpg =300x200)`
- Override default HTML templates and SCSS for site-specific styling

## Key Benefits

- Drop-in Liquid tags and Markdown extension with sensible defaults
- Built-in Internet Archive lookup/caching for both card types
- Theme-friendly: structure/colors SCSS split and `_includes` templates are overridable

## Success Criteria

- Tags render correct HTML for documented parameter combinations
- Archive helper behaves correctly for auto-lookup, explicit URL, and disabled modes
- Gem installs cleanly into Jekyll 4.x sites; tests and RuboCop pass in CI

## Key Constraints

- Ruby gem for Jekyll 4.x / Liquid 4.x; required Ruby version is pinned in the gemspec
- License is AGPL-3.0-or-later
- Coverage reporting (SimpleCov + Cobertura) is a development concern used by CI/Codecov, not a runtime feature
