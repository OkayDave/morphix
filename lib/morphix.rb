# frozen_string_literal: true

# Morphix provides a concise, expressive DSL for elegantly reshaping and transforming Ruby hashes and JSON structures.
# It offers a fluent interface for data transformation with support for nested structures,
# collections, and complex transformations.
module Morphix
  class Error < StandardError; end

  autoload :Transformer, "morphix/transformer"
  autoload :VERSION, "morphix/version"

  class << self
    # Defines a new transformer with the given block
    # @return [Transformer] A new transformer instance
    def define(&)
      Transformer.new(&)
    end
  end
end
