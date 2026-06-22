# Current Task: Polaroid Optional Title/Link Rendering

**Complexity:** Level 1

## Fix Record

- **What broke:** Polaroid cards rendered optional metadata wrappers (`.polaroid-title`, `.polaroid-link`, `.polaroid-archive`) when their data was absent, causing avoidable tail spacing.
- **Why it broke:** The template used placeholder output (`&nbsp;`) and always-rendered archive markup instead of conditionally omitting optional metadata elements.
- **What changed:** Added conditional rendering for title/link wrappers plus archive wrapper, then added an archive-only modifier class with targeted spacing (`.polaroid-archive-only`) for the archive-only state.
- **Files affected:**
  - `_includes/highlight-cards/polaroid.html`
  - `_sass/_highlight-cards-structure.scss`
  - `lib/jekyll-highlight-cards/polaroid_tag.rb`
  - `spec/jekyll_highlight_cards/polaroid_tag_spec.rb`

## Verification

- `bundle exec rspec spec/jekyll_highlight_cards/polaroid_tag_spec.rb`
- `bundle exec rspec`
- `bundle exec rubocop`
