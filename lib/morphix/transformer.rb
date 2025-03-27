# frozen_string_literal: true

module Morphix
  # The Transformer class provides a DSL for transforming data structures like hashes and JSON.
  # It allows you to define transformation rules that can be applied to input data,
  # making it perfect for API response normalization, JSON reshaping, and ETL pipelines.
  class Transformer
    # Creates a new transformer with the given block
    # @param block [Proc] The block defining the transformations
    def initialize(&)
      @transformations = []
      instance_eval(&) if block_given?
    end

    # Renames a key to a new name, optionally transforming its value
    # @param old_key [Symbol] The key to rename
    # @param to [Symbol] The new key name
    # @param block [Proc, nil] Optional block to transform the value
    # @return [self] Returns self for method chaining
    def rename(old_key, to:, &block)
      @transformations << { type: :rename, old_key:, new_key: to, block: }
      self
    end

    # Transforms a value while preserving its key
    # @param key [Symbol] The key whose value to transform
    # @param block [Proc] The block to transform the value
    # @return [self] Returns self for method chaining
    def map(key, &block)
      @transformations << { type: :map, key:, block: }
      self
    end

    # Removes a key from the hash
    # @param key [Symbol] The key to remove
    # @return [self] Returns self for method chaining
    def reject(key)
      @transformations << { type: :reject, key: }
      self
    end

    # Transforms a nested hash structure
    # @param key [Symbol] The key containing the nested hash
    # @param block [Proc] The block defining the nested transformations
    # @return [self] Returns self for method chaining
    def reshape(key, &block)
      @transformations << { type: :reshape, key:, block: }
      self
    end

    # Transforms an array of hashes
    # @param key [Symbol] The key containing the array
    # @param block [Proc] The block defining the transformations for each hash
    # @return [self] Returns self for method chaining
    def map_collection(key, &block)
      @transformations << { type: :map_collection, key:, block: }
      self
    end

    # Applies the transformations to the input hash
    # @param input [Hash] The input hash to transform
    # @return [Hash] The transformed hash
    def apply(input)
      result = input.dup
      @transformations.each { |transformation| apply_transformation(result, transformation) }
      result
    end

    private

    def apply_transformation(result, transformation)
      case transformation[:type]
      when :rename then apply_rename(result, transformation)
      when :map then apply_map(result, transformation)
      when :reject then apply_reject(result, transformation)
      when :reshape then apply_reshape(result, transformation)
      when :map_collection then apply_map_collection(result, transformation)
      end
    end

    def apply_rename(result, transformation)
      return unless result.key?(transformation[:old_key])

      value = result[transformation[:old_key]]
      new_value = transformation[:block] ? transformation[:block].call(value) : value
      result[transformation[:new_key]] = new_value
      result.delete(transformation[:old_key])
    end

    def apply_map(result, transformation)
      return unless result.key?(transformation[:key])

      result[transformation[:key]] = transformation[:block].call(result[transformation[:key]])
    end

    def apply_reject(result, transformation)
      result.delete(transformation[:key])
    end

    def apply_reshape(result, transformation)
      return unless result.key?(transformation[:key]) && result[transformation[:key]].is_a?(Hash)

      nested_transformer = self.class.new(&transformation[:block])
      result[transformation[:key]] = nested_transformer.apply(result[transformation[:key]])
    end

    def apply_map_collection(result, transformation)
      return unless result.key?(transformation[:key]) && result[transformation[:key]].is_a?(Array)

      collection_transformer = self.class.new(&transformation[:block])
      result[transformation[:key]] = result[transformation[:key]].map do |item|
        collection_transformer.apply(item)
      end
    end
  end
end
