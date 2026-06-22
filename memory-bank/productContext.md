# Product Context

`jekyll-highlight-cards` is a Jekyll plugin (distributed as a Ruby gem) that provides styled "card" components for links and images, with optional Internet Archive integration.

## Target Audience

Authors of Jekyll-based static sites (blogs, devblogs, documentation sites) who want richer link/image presentation than raw Markdown provides, without hand-writing HTML/CSS for each instance.

## Use Cases

- Render styled link cards with `{% linkcard %}` (optional title, optional archive link).
- Render polaroid-style image cards with `{% polaroid %}` (sizing, titles, links, alt text, archive support).
- Add dimensions to standard Markdown images via extended syntax: `![alt](image.jpg =300x200)`.
- Automatically look up (and optionally submit) Wayback Machine archive snapshots for linked URLs.
- Customize appearance by overriding the bundled SCSS or HTML templates.

## Key Benefits

- Drop-in Liquid tags: no per-page HTML/CSS boilerplate.
- Customizable at two layers: HTML templates (via `_includes/highlight-cards/`) and CSS (structure-only vs. full styles).
- Archive integration is opt-in and fails soft, so builds never break on network issues.
- Accessibility-aware: explicit `alt` handling with sensible fallbacks.

## Success Criteria

- Tags render correct, well-formed, HTML-escaped markup across the documented parameter combinations.
- Site builds remain fast and never fail due to archive lookups (network errors degrade gracefully).
- Consumers can override styles and templates without forking the gem.
- Behavior is regression-protected by a high-coverage RSpec suite.

## Key Constraints

- Must run inside Jekyll's build lifecycle (Liquid tags + Jekyll hooks) and stay compatible with Jekyll 4.x / Liquid 4.x.
- Network calls (Internet Archive) are off by default and gated behind environment variables.
- User-supplied template names must be constrained to prevent path-traversal.
