# Contributing to jekyll-highlight-cards

## Development Setup

### Prerequisites

- Ruby 3.1 or higher
- Bundler

### Clone and Setup

```bash
git clone https://github.com/texarkanine/jekyll-highlight-cards.git
cd jekyll-highlight-cards
bundle install
```

### Running Tests

Run the full test suite:

```bash
bundle exec rspec
```

Run specific test file:

```bash
bundle exec rspec spec/linkcard_tag_spec.rb
```

Run with documentation format:

```bash
bundle exec rspec --format documentation
```

### Code Quality

Check code style:

```bash
bundle exec rubocop
```

Auto-fix style issues:

```bash
bundle exec rubocop --autocorrect
```

### Building the Gem

```bash
gem build jekyll-highlight-cards.gemspec
```

This creates `jekyll-highlight-cards-VERSION.gem`.

### Installing Locally

```bash
gem install ./jekyll-highlight-cards-*.gem
```

Or in a test Jekyll site's Gemfile:

```ruby
gem 'jekyll-highlight-cards', path: '/path/to/jekyll-highlight-cards'
```

## Project Structure

```
jekyll-highlight-cards/
├── lib/
│   ├── jekyll-highlight-cards.rb          # Main entry point
│   └── jekyll-highlight-cards/
│       ├── version.rb                     # Version constant
│       ├── archive_helper.rb              # Archive integration
│       ├── dimension_parser.rb            # Image sizing utilities
│       ├── expression_evaluator.rb        # Liquid expression evaluation
│       ├── template_renderer.rb           # Template rendering
│       ├── linkcard_tag.rb               # Linkcard Liquid tag
│       ├── polaroid_tag.rb               # Polaroid Liquid tag
│       └── image_sizing_hooks.rb         # Markdown image sizing
├── _includes/highlight-cards/
│   ├── linkcard.html                     # Default linkcard template
│   └── polaroid.html                     # Default polaroid template
├── assets/css/
│   └── highlight-cards.scss              # Default styles
├── spec/                                  # Test files
│   ├── spec_helper.rb
│   ├── *_spec.rb                         # Tests for each module
│   └── fixtures/                         # Test fixtures
└── jekyll-highlight-cards.gemspec        # Gem specification
```

## Development Workflow

### TDD Approach

This project follows Test-Driven Development:

1. **Write tests first** - Define expected behavior in specs
2. **Run tests** - Watch them fail (red)
3. **Write code** - Implement to make tests pass (green)
4. **Refactor** - Improve code while keeping tests green
5. **Verify** - Run full suite and Rubocop

### Adding Features

1. Create feature branch: `git checkout -b feature/my-feature`
2. Write tests in `spec/`
3. Implement feature in `lib/`
4. Run tests: `bundle exec rspec`
5. Check style: `bundle exec rubocop`
6. Commit with descriptive message
7. Push and create pull request

### Commit Messages

Use conventional commit format of type `chore`, `feat`, or `fix`:

- `feat: Add new feature`
- `fix: Fix bug in XYZ`
- `chore(docs): Update README`
- `chore(test): Add tests for ABC`
- `feat(refactor): Improve XYZ`
- `chore(style): Fix Rubocop issues`

## Testing Guidelines

### Test Coverage

- Aim for >95% line coverage
- Cover happy paths and edge cases
- Test error handling
- Mock external dependencies (HTTP requests, file I/O)

### Test Structure

```ruby
RSpec.describe MyModule do
  describe ".method_name" do
    context "with valid input" do
      it "returns expected result" do
        # test code
      end
    end
    
    context "with invalid input" do
      it "raises appropriate error" do
        # test code
      end
    end
  end
end
```

### Running Specific Tests

```bash
# Run single test file
bundle exec rspec spec/linkcard_tag_spec.rb

# Run single test (by line number)
bundle exec rspec spec/linkcard_tag_spec.rb:42

# Run tests matching pattern
bundle exec rspec spec/linkcard_tag_spec.rb -e "renders with title"
```

## Code Style

### Ruby Style Guide

Follow standard Ruby conventions:

- 2 space indentation
- Snake_case for methods and variables
- CamelCase for classes and modules
- SCREAMING_SNAKE_CASE for constants
- Maximum 120 characters per line

### Module Organization

- One class/module per file
- File names match class names (snake_case)
- Public methods documented with YARD comments
- Private methods below `private` keyword

## Troubleshooting

### Tests failing after changes

1. Run full suite: `bundle exec rspec`
2. Check specific failing test
3. Review recent changes
4. Verify test fixtures are correct

### Rubocop errors

```bash
bundle exec rubocop --autocorrect
```

If auto-correct doesn't work, manually fix reported issues.

### Gem won't build

1. Check `jekyll-highlight-cards.gemspec` for errors
2. Verify all required files exist
3. Check Ruby version compatibility

## Questions?

Open an issue on GitHub for questions, bug reports, or feature requests.

