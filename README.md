# jekyll-highlight-cards

A Jekyll plugin providing styled card components for links and images with Internet Archive integration.

## Features

- **`{% linkcard %}`** - Styled link cards with optional titles and archive links
- **`{% polaroid %}`** - Polaroid-style image cards with titles, links, and archive support
- **Markdown Image Sizing** - Extended syntax for image dimensions: `![alt](image.jpg =300x200)`
- **Internet Archive Integration** - Automatic lookup and archival for both tags
- **Customizable** - Override HTML templates and CSS styles

## Installation

Add to your `Gemfile`:

```ruby
gem 'jekyll-highlight-cards'
```

Add to your `_config.yml`:

```yaml
plugins:
  - jekyll-highlight-cards
```

Run:

```bash
bundle install
```

## Usage

### Linkcard Tag

Create styled link cards:

```liquid
{% linkcard https://example.com %}
{% linkcard https://example.com My Cool Title %}
{% linkcard https://example.com Title archive:none %}
{% linkcard https://example.com archive:https://web.archive.org/... %}
```

**Parameters:**
- URL (required, first parameter)
- Title (optional, everything after URL until `archive:`)
- `archive:URL` - Explicit archive URL
- `archive:none` - Disable archive lookup

**With Liquid variables:**

```liquid
{% linkcard {{ page.url }} {{ page.title }} %}
```

### Polaroid Tag

Create polaroid-style image cards:

```liquid
{% polaroid /assets/image.jpg %}
{% polaroid /assets/image.jpg size=300x200 %}
{% polaroid /assets/image.jpg size=400x title="My Photo" %}
{% polaroid /assets/image.jpg alt="Screen reader description" %}
{% polaroid /assets/image.jpg alt="Alt text" title="Visible Title" %}
{% polaroid /assets/image.jpg title="Photo" link="https://example.com" %}
{% polaroid {{ page.image }} size=x400 title={{ page.title }} %}
```

**Parameters:**
- Image URL (required, first parameter)
- `size=WxH` - Image dimensions (formats: `300x200`, `300x`, `x200`, `300`, `400pxx300px`)
- `alt="..."` - Alt text for image (for accessibility)
- `title="..."` - Title text displayed below image (also used as alt fallback)
- `link="..."` - Explicit URL to link to
- `archive="..."` - Archive URL or `none` to disable

**Image Alt Text:**
The `alt` attribute priority: explicit `alt` parameter → `title` parameter → empty string.

This allows you to:
- Set accessible alt text without displaying a visible title
- Use title as both visual label and screen reader description
- Separate concerns: detailed alt for accessibility, brief title for display

**Link Display:**
- **No `link` parameter:** Image links to itself, no visible link text shown
- **With `link` parameter:** Image and visible link text both point to the specified URL

This keeps the display clean when showcasing images without external references.

### Markdown Image Sizing

Add dimensions to Markdown images:

```markdown
![Alt text](image.jpg =300x200)
![Alt text](image.jpg =400x)
![Alt text](image.jpg =x300)
![Alt text](image.jpg =400pxx300px)
```

Sized images are automatically wrapped in links to themselves.

## Configuration

### Internet Archive

Enable automatic archive lookup:

```bash
export JEKYLL_HIGHLIGHT_CARDS_ARCHIVE=1
```

Or in your shell config:

```bash
# In .bashrc, .zshrc, etc.
export JEKYLL_HIGHLIGHT_CARDS_ARCHIVE=1
```

### CSS Styles

**Option 1: Use default styles**

Add to your main SCSS file:

```scss
@import "highlight-cards";
```

**Option 2: Custom styles only**

Don't import the default styles. Define your own:

```scss
.link-card { /* your styles */ }
.polaroid { /* your styles */ }
```

**Option 3: Override defaults**

Import defaults and override specific properties:

```scss
@import "highlight-cards";

.link-card {
  border-color: red;  // Override
}
```

### Template Customization

Override templates by creating files in your Jekyll site:

**Linkcard template:**
- Create `_includes/highlight-cards/linkcard.html`

**Polaroid template:**
- Create `_includes/highlight-cards/polaroid.html`

Templates receive these variables:

**Linkcard variables:**
- `url`, `display_url`, `title`, `archive_url`
- `escaped_url`, `escaped_display_url`, `escaped_title`, `escaped_archive_url`

**Polaroid variables:**
- `image_url`, `link_url`, `title`, `link_display`, `archive_url`, `width`, `height`
- `escaped_*` versions of all text fields

See default templates in gem's `_includes/` directory for examples.

## Examples

### Blog post with link card

```markdown
---
title: My Blog Post
---

Check out this cool site:

{% linkcard https://jekyllrb.com Jekyll - Simple, blog-aware, static sites %}

More content here...
```

### Gallery with polaroids

```markdown
---
title: Photo Gallery
photos:
  - url: /assets/photo1.jpg
    title: Sunset
  - url: /assets/photo2.jpg
    title: Mountains
---

{% for photo in page.photos %}
  {% polaroid {{ photo.url }} size=300x300 title={{ photo.title }} %}
{% endfor %}
```

### Sized images in Markdown

```markdown
Here's a large image:

![My Photo](photo.jpg =800x600)

And a smaller one:

![Thumbnail](thumb.jpg =150x150)
```

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.
