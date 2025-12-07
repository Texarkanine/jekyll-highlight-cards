# frozen_string_literal: true

module JekyllHighlightCards
  # Module for evaluating Liquid expressions and handling string values
  module ExpressionEvaluator
    # Evaluate a token as a Liquid expression or literal string
    #
    # @param token [String] the token to evaluate
    # @param context [Liquid::Context] the Liquid context for variable resolution
    # @param allow_nil [Boolean] whether to allow nil results
    # @return [String, nil] evaluated value or nil if evaluation fails
    def evaluate_expression(token, context, allow_nil: true)
      return nil if token.nil?
      return "" if token.empty?

      # Strip outer quotes if present
      stripped = strip_outer_quotes(token)

      # If the original token was quoted, treat as literal string
      if stripped != token
        return allow_nil ? stripped : (stripped.empty? ? nil : stripped)
      end

      # Try to evaluate as Liquid expression
      if variable_lookup?(token)
        begin
          # Parse and evaluate the Liquid expression
          template = Liquid::Template.parse(token)
          result = template.render(context)
          return allow_nil ? result : (result.to_s.empty? ? nil : result)
        rescue Liquid::SyntaxError, StandardError => e
          log_debug("Failed to evaluate '#{token}' as Liquid expression: #{e.message}")
          # Fall back to literal string
          return allow_nil ? token : (token.empty? ? nil : token)
        end
      end

      # Return as literal string
      allow_nil ? token : (token.empty? ? nil : token)
    end

    # Check if an expression looks like a Liquid variable lookup
    #
    # @param expression [String] the expression to check
    # @return [Boolean] true if expression contains Liquid syntax
    def variable_lookup?(expression)
      return false if expression.nil? || expression.empty?

      expression.include?("{{") || expression.include?("{%")
    end

    # Strip outer quotes from a string (both single and double quotes)
    #
    # @param value [String] the string to process
    # @return [String] string with outer quotes removed if present
    def strip_outer_quotes(value)
      return value if value.nil? || value.empty?

      # Check for matching outer quotes
      if (value.start_with?('"') && value.end_with?('"')) ||
         (value.start_with?("'") && value.end_with?("'"))
        return value[1..-2] if value.length > 1
      end

      value
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
