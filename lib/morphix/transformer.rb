# frozen_string_literal: true

module Morphix
  class Transformer
    def initialize(&block)
      @transformations = []
      instance_eval(&block) if block_given?
    end

    # Renames a key to a new name, optionally transforming the value
    # @param old_key [Symbol] The key to rename
    # @param to: [Symbol] The new key name
    # @param &block [Proc] Optional block to transform the value
    def rename(old_key, to:, &block)
      @transformations << [:rename, old_key, to, block]
      self
    end

    # Maps a value through a transformation
    # @param key [Symbol] The key to transform
    # @param &block [Proc] The transformation block
    def map(key, &block)
      @transformations << [:map, key, block]
      self
    end

    # Removes a key from the result
    # @param key [Symbol] The key to remove
    def reject(key)
      @transformations << [:reject, key]
      self
    end

    # Reshapes a nested hash structure
    # @param key [Symbol] The key containing the nested hash
    # @param &block [Proc] The transformation block for the nested structure
    def reshape(key, &block)
      nested_transformer = self.class.new(&block)
      @transformations << [:reshape, key, nested_transformer]
      self
    end

    # Maps over a collection of hashes
    # @param key [Symbol] The key containing the array of hashes
    # @param &block [Proc] The transformation block for each hash
    def map_collection(key, &block)
      nested_transformer = self.class.new(&block)
      @transformations << [:map_collection, key, nested_transformer]
      self
    end

    # Applies the transformations to the input hash
    # @param input [Hash] The input hash to transform
    # @return [Hash] The transformed hash
    def apply(input)
      result = input.dup

      @transformations.each do |type, key, *args|
        case type
        when :rename
          new_key, transform_block = args
          if result.key?(key)
            value = result.delete(key)
            value = transform_block.call(value) if transform_block
            result[new_key] = value
          end
        when :map
          transform_block = args.first
          result[key] = transform_block.call(result[key]) if result.key?(key)
        when :reject
          result.delete(key)
        when :reshape
          nested_transformer = args.first
          if result.key?(key) && result[key].is_a?(Hash)
            result[key] = nested_transformer.apply(result[key])
          end
        when :map_collection
          nested_transformer = args.first
          if result.key?(key) && result[key].is_a?(Array)
            result[key] = result[key].map { |item| nested_transformer.apply(item) }
          end
        end
      end

      result
    end
  end
end 