# frozen_string_literal: true

module JekyllHighlightCards
  # Evaluate Liquid expressions and handle string values
  #
  # Provides utilities for evaluating Liquid variables (e.g., `{{ page.title }}`)
  # and processing string values with quote stripping and fallback behavior.
  #
  # @example Evaluate a Liquid variable
  #   result = evaluate_expression("{{ page.title }}", context)
  #
  # @example Evaluate a quoted string
  #   result = evaluate_expression('"My Title"', context)  #=> "My Title"
  module ExpressionEvaluator
    # Evaluate a token as a Liquid expression or literal string
    #
    # @param token [String] the token to evaluate
    # @param context [Liquid::Context] the Liquid context for variable resolution
    # @param allow_nil [Boolean] whether to allow nil results
    # @return [String, nil] evaluated value or nil if evaluation fails
    def evaluate_expression(token, context, allow_nil: true)
      # Strip outer quotes if present
      stripped = strip_outer_quotes(token)

      # If the original token was quoted, treat as literal string
      if !token.nil? && quote_wrapped?(token)
        return stripped if allow_nil

        return stripped.empty? ? nil : stripped
      end

      # Try to evaluate as Liquid expression
      if variable_lookup?(token)
        begin
          # Parse and evaluate the Liquid expression
          template = Liquid::Template.parse(token)
          result = template.render(context)
          return result if allow_nil

          return nil if result.empty?

          result
        rescue Liquid::SyntaxError, StandardError => e
          log_debug("Failed to evaluate '#{token}' as Liquid expression: #{e.class}: #{e}")
          token
        end
      else
        token
      end
    end

    # Check if an expression looks like a Liquid variable lookup
    #
    # @param expression [String] the expression to check
    # @return [Boolean] true if expression contains Liquid syntax
    def variable_lookup?(expression)
      return false if expression.nil?

      expression.include?("{{") || expression.include?("{%")
    end

    # Strip outer quotes from a string (both single and double quotes)
    #
    # @param value [String] the string to process
    # @return [String] string with outer quotes removed if present
    def strip_outer_quotes(value)
      return nil if value.nil?
      return value[1..-2] if quote_wrapped?(value)

      value
    end

    # Whether value has matching outer quotes and more than one character
    #
    # @param value [String] the string to inspect
    # @return [Boolean]
    def quote_wrapped?(value)
      return false unless value.length >= 2

      (value.start_with?('"') && value.end_with?('"')) ||
        (value.start_with?("'") && value.end_with?("'"))
    end

    # Log debug message
    #
    # @param message [String] message to log
    def log_debug(message)
      Jekyll.logger.debug("HighlightCards:", message)
    end

    # Log info message
    #
    # @param message [String] message to log
    def log_info(message)
      Jekyll.logger.info("HighlightCards:", message)
    end

    # Log warning message
    #
    # @param message [String] message to log
    def log_warn(message)
      Jekyll.logger.warn("HighlightCards:", message)
    end

    # Log error message
    #
    # @param message [String] message to log
    def log_error(message)
      Jekyll.logger.error("HighlightCards:", message)
    end
  end
end
