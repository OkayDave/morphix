# frozen_string_literal: true

require_relative "morphix/version"
require_relative "morphix/transformer"

module Morphix
  class Error < StandardError; end

  # Defines a new transformer with the given block
  # @return [Transformer] A new transformer instance
  def self.define(&block)
    Transformer.new(&block)
  end
end
