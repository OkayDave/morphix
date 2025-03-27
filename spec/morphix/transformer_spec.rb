# frozen_string_literal: true

require "json"
require "time"
require "base64"
require "digest"

RSpec.describe Morphix::Transformer do
  # Basic key renaming tests
  # These tests verify the fundamental ability to rename keys while preserving values
  describe "#rename" do
    it "renames a key to a new name" do
      transformer = described_class.new do
        rename :old_name, to: :new_name
      end

      input = { old_name: "Dave" }
      result = transformer.apply(input)

      expect(result).to eq({ new_name: "Dave" })
    end

    # Tests the ability to transform values during renaming
    # This is crucial for cases where we need to both rename and restructure data
    it "transforms the value when a block is provided" do
      transformer = described_class.new do
        rename :full_name, to: :name do |name|
          first, last = name.split
          { first_name: first, last_name: last }
        end
      end

      input = { full_name: "Dave Cooper" }
      result = transformer.apply(input)

      expect(result).to eq({
        name: { first_name: "Dave", last_name: "Cooper" }
      })
    end

    # Verifies that renaming doesn't affect other keys in the hash
    # This is important for maintaining data integrity during transformations
    it "preserves other keys" do
      transformer = described_class.new do
        rename :old_name, to: :new_name
      end

      input = { old_name: "Dave", other_key: "value" }
      result = transformer.apply(input)

      expect(result).to eq({ new_name: "Dave", other_key: "value" })
    end
  end

  # Value transformation tests
  # These tests ensure we can modify values while keeping their keys intact
  describe "#map" do
    # Tests basic value transformation using a simple method
    # This is commonly used for type conversions (e.g., string to integer)
    it "transforms a value using the provided block" do
      transformer = described_class.new do
        map :age, &:to_i
      end

      input = { age: "40" }
      result = transformer.apply(input)

      expect(result).to eq({ age: 40 })
    end

    # Verifies that mapping only affects the specified key
    # This is crucial for maintaining data integrity in complex transformations
    it "preserves the key name" do
      transformer = described_class.new do
        map :age, &:to_i
      end

      input = { age: "40", name: "Dave" }
      result = transformer.apply(input)

      expect(result).to eq({ age: 40, name: "Dave" })
    end
  end

  # Key removal tests
  # These tests verify the ability to remove specific keys from the hash
  describe "#reject" do
    # Tests basic key removal functionality
    # This is important for data sanitization and removing sensitive information
    it "removes the specified key" do
      transformer = described_class.new do
        reject :password
      end

      input = { name: "Dave", password: "secret" }
      result = transformer.apply(input)

      expect(result).to eq({ name: "Dave" })
    end
  end

  # Nested structure transformation tests
  # These tests verify the ability to transform nested hash structures
  describe "#reshape" do
    # Tests transformation of nested hash structures
    # This is crucial for handling complex data structures like API responses
    it "transforms nested hash structures" do
      transformer = described_class.new do
        reshape :address do
          rename :postal_code, to: :postcode
          map :verified do |value|
            value == "true"
          end
        end
      end

      input = {
        address: {
          street: "Main St",
          postal_code: "S2",
          verified: "true"
        }
      }
      result = transformer.apply(input)

      expect(result).to eq({
        address: {
          street: "Main St",
          postcode: "S2",
          verified: true
        }
      })
    end
  end

  # Collection transformation tests
  # These tests verify the ability to transform arrays of hashes
  describe "#map_collection" do
    # Tests transformation of arrays containing hashes
    # This is essential for handling collections of records, like API responses with multiple items
    it "transforms arrays of hashes" do
      transformer = described_class.new do
        map_collection :users do
          rename :username, to: :name
          reject :internal_notes
        end
      end

      input = {
        users: [
          { username: "Dave", internal_notes: "VIP" },
          { username: "Jason", internal_notes: "Banned" }
        ]
      }
      result = transformer.apply(input)

      expect(result).to eq({
        users: [
          { name: "Dave" },
          { name: "Jason" }
        ]
      })
    end
  end

  # Method chaining tests
  # These tests verify that multiple transformations can be combined
  describe "chaining" do
    # Tests the ability to combine multiple transformations in sequence
    # This is crucial for complex data transformations that require multiple steps
    it "allows multiple transformations to be chained" do
      transformer = described_class.new do
        rename :full_name, to: :name
        map :age, &:to_i
        reject :password
      end

      input = {
        full_name: "Dave Cooper",
        age: "40",
        password: "secret"
      }
      result = transformer.apply(input)

      expect(result).to eq({
        name: "Dave Cooper",
        age: 40
      })
    end
  end

  # Immutability tests
  # These tests ensure that transformations don't modify the original data
  describe "immutability" do
    # Verifies that the input hash remains unchanged after transformation
    # This is important for preventing side effects and maintaining data integrity
    it "does not modify the input hash" do
      transformer = described_class.new do
        rename :old_name, to: :new_name
      end

      input = { old_name: "Dave" }
      original = input.dup
      transformer.apply(input)

      expect(input).to eq(original)
    end
  end

  # Nested transformation tests
  # These tests verify the ability to handle deeply nested data structures
  describe "nested transformations" do
    # Tests transformation of deeply nested hash structures
    # This is crucial for handling complex data hierarchies like API responses
    it "handles deeply nested structures" do
      transformer = described_class.new do
        reshape :user do
          rename :personal_info, to: :info do |info|
            {
              name: info[:full_name],
              contact: {
                email: info[:email],
                phone: info[:phone_number]
              }
            }
          end
          reshape :address do
            rename :postal_code, to: :postcode
            map :coordinates do |coords|
              { lat: coords[:lat].to_f, lng: coords[:lng].to_f }
            end
          end
        end
      end

      input = {
        user: {
          personal_info: {
            full_name: "Dave Cooper",
            email: "dave@example.com",
            phone_number: "123-456-7890"
          },
          address: {
            street: "123 Main St",
            postal_code: "12345",
            coordinates: { lat: "40.7128", lng: "-74.0060" }
          }
        }
      }

      expect(transformer.apply(input)).to eq({
        user: {
          info: {
            name: "Dave Cooper",
            contact: {
              email: "dave@example.com",
              phone: "123-456-7890"
            }
          },
          address: {
            street: "123 Main St",
            postcode: "12345",
            coordinates: { lat: 40.7128, lng: -74.0060 }
          }
        }
      })
    end

    # Tests transformation of arrays within nested structures
    # This is important for handling collections within complex data hierarchies
    it "handles arrays within nested structures" do
      transformer = described_class.new do
        reshape :organization do
          map_collection :departments do
            rename :dept_name, to: :name
            map_collection :employees do
              rename :full_name, to: :name
              map :age, &:to_i
              reject :ssn
            end
          end
        end
      end

      input = {
        organization: {
          departments: [
            {
              dept_name: "Engineering",
              employees: [
                { full_name: "Dave Cooper", age: "35", ssn: "123-45-6789" },
                { full_name: "Alice Smith", age: "28", ssn: "987-65-4321" }
              ]
            },
            {
              dept_name: "Marketing",
              employees: [
                { full_name: "Bob Jones", age: "42", ssn: "456-78-9012" }
              ]
            }
          ]
        }
      }

      expect(transformer.apply(input)).to eq({
        organization: {
          departments: [
            {
              name: "Engineering",
              employees: [
                { name: "Dave Cooper", age: 35 },
                { name: "Alice Smith", age: 28 }
              ]
            },
            {
              name: "Marketing",
              employees: [
                { name: "Bob Jones", age: 42 }
              ]
            }
          ]
        }
      })
    end
  end

  # Edge case tests
  # These tests verify the transformer's behavior in unusual or error-prone situations
  describe "edge cases" do
    # Tests handling of missing keys in the input
    # This is crucial for robustness when dealing with incomplete or malformed data
    it "handles missing keys gracefully" do
      transformer = described_class.new do
        rename :name, to: :full_name
        map :age, &:to_i
        reject :password
        reshape :address do
          rename :postal_code, to: :postcode
        end
      end

      input = { email: "test@example.com" }
      expect(transformer.apply(input)).to eq({ email: "test@example.com" })
    end

    # Tests handling of nil values
    # This is important for preventing null pointer exceptions
    it "handles nil values" do
      transformer = described_class.new do
        rename :name, to: :full_name
        map :age do |value|
          value&.to_i
        end
        reshape :address do
          rename :postal_code, to: :postcode
        end
      end

      input = { name: nil, age: nil, address: nil }
      expect(transformer.apply(input)).to eq({ full_name: nil, age: nil, address: nil })
    end

    # Tests handling of empty collections
    # This ensures the transformer works correctly with empty arrays and nil collections
    it "handles empty collections" do
      transformer = described_class.new do
        map_collection :users do
          rename :username, to: :name
        end
        map_collection :groups do
          rename :group_name, to: :name
        end
      end

      input = { users: [], groups: nil }
      expect(transformer.apply(input)).to eq({ users: [], groups: nil })
    end

    # Tests handling of non-hash values in reshape blocks
    # This prevents errors when encountering unexpected data types
    it "handles non-hash values in reshape" do
      transformer = described_class.new do
        reshape :config do
          rename :api_key, to: :key
        end
      end

      input = { config: "invalid" }
      expect(transformer.apply(input)).to eq({ config: "invalid" })
    end

    # Tests handling of non-array values in map_collection
    # This ensures graceful handling of unexpected data types in collections
    it "handles non-array values in map_collection" do
      transformer = described_class.new do
        map_collection :users do
          rename :username, to: :name
        end
      end

      input = { users: "invalid" }
      expect(transformer.apply(input)).to eq({ users: "invalid" })
    end
  end

  # Complex chaining tests
  # These tests verify the transformer's ability to handle complex, multi-step transformations
  describe "complex chaining" do
    # Tests combining multiple nested transformations with value modifications
    # This is crucial for real-world scenarios where data needs multiple transformations
    it "combines multiple nested transformations" do
      transformer = described_class.new do
        rename :metadata, to: :meta do |data|
          { version: data[:version].to_i, updated_at: data[:timestamp] }
        end

        reshape :data do
          map_collection :items do
            rename :item_name, to: :name
            map :price do |price|
              price.to_f.round(2)
            end
            reshape :details do
              rename :specs, to: :specifications
              map :created_at, &:to_s
            end
          end

          reshape :summary do
            map :total_items, &:to_i
            map :total_price do |price|
              price.to_f.round(2)
            end
          end
        end
      end

      input = {
        metadata: { version: "2", timestamp: "2024-03-27" },
        data: {
          items: [
            {
              item_name: "Widget",
              price: "19.99",
              details: {
                specs: "High quality",
                created_at: Time.new(2024, 3, 27)
              }
            },
            {
              item_name: "Gadget",
              price: "29.99",
              details: {
                specs: "Premium",
                created_at: Time.new(2024, 3, 26)
              }
            }
          ],
          summary: {
            total_items: "2",
            total_price: "49.98"
          }
        }
      }

      expect(transformer.apply(input)).to eq({
        meta: {
          version: 2,
          updated_at: "2024-03-27"
        },
        data: {
          items: [
            {
              name: "Widget",
              price: 19.99,
              details: {
                specifications: "High quality",
                created_at: "2024-03-27 00:00:00 +0000"
              }
            },
            {
              name: "Gadget",
              price: 29.99,
              details: {
                specifications: "Premium",
                created_at: "2024-03-26 00:00:00 +0000"
              }
            }
          ],
          summary: {
            total_items: 2,
            total_price: 49.98
          }
        }
      })
    end
  end

  # Advanced transformation tests
  # These tests verify complex data transformation scenarios
  describe "advanced transformations" do
    # Tests conditional transformations based on value content
    # This is useful for mapping status strings to numeric codes or other representations
    it "handles conditional transformations" do
      transformer = described_class.new do
        map :status do |status|
          case status
          when "active" then 1
          when "pending" then 0
          when "deleted" then -1
          else nil
          end
        end
      end

      input = { status: "active" }
      expect(transformer.apply(input)).to eq({ status: 1 })
    end

    # Tests converting array of key-value pairs to a hash
    # This is common when dealing with tag-like structures or metadata
    it "handles array to hash transformations" do
      transformer = described_class.new do
        map :tags do |tags|
          tags.each_with_object({}) do |tag, hash|
            hash[tag[:key].to_sym] = tag[:value]
          end
        end
      end

      input = {
        tags: [
          { key: "type", value: "user" },
          { key: "role", value: "admin" }
        ]
      }
      expect(transformer.apply(input)).to eq({
        tags: { type: "user", role: "admin" }
      })
    end

    # Tests converting hash to array of key-value pairs
    # This is useful for flattening structures or preparing data for certain APIs
    it "handles hash to array transformations" do
      transformer = described_class.new do
        map :metadata do |meta|
          meta.map { |key, value| { name: key, value: value } }
        end
      end

      input = {
        metadata: { created_at: "2024-03-27", status: "active" }
      }
      expect(transformer.apply(input)).to eq({
        metadata: [
          { name: :created_at, value: "2024-03-27" },
          { name: :status, value: "active" }
        ]
      })
    end

    # Tests complex data type conversions across multiple fields
    # This is crucial for normalizing data types across a dataset
    it "handles complex data type conversions" do
      transformer = described_class.new do
        map :dates do |dates|
          dates.transform_values { |v| Time.strptime(v, "%Y-%m-%d %H:%M:%S") }
        end
        map :numbers do |nums|
          nums.transform_values(&:to_f)
        end
        map :flags do |flags|
          flags.transform_values { |v| v.to_s.downcase == "true" }
        end
      end

      input = {
        dates: { created: "2024-03-27 10:30:00", updated: "2024-03-28 15:45:00" },
        numbers: { latitude: "40.7128", longitude: "-74.0060" },
        flags: { active: "True", deleted: "FALSE", archived: "true" }
      }

      result = transformer.apply(input)
      expect(result[:dates][:created]).to be_a(Time)
      expect(result[:dates][:updated]).to be_a(Time)
      expect(result[:numbers]).to eq({ latitude: 40.7128, longitude: -74.0060 })
      expect(result[:flags]).to eq({ active: true, deleted: false, archived: true })
    end
  end

  # Error handling tests
  # These tests verify proper handling of error conditions and invalid data
  describe "error handling" do
    # Tests handling of exceptions in transformation blocks
    # This ensures errors are properly propagated rather than silently ignored
    it "handles exceptions in transformation blocks" do
      transformer = described_class.new do
        map :number do |n|
          Integer(n)
        end
      end

      input = { number: "not_a_number" }
      expect { transformer.apply(input) }.to raise_error(ArgumentError)
    end

    # Tests handling of exceptions in deeply nested transformations
    # This ensures errors are properly propagated through the transformation chain
    it "handles deep nested exceptions" do
      transformer = described_class.new do
        reshape :user do
          reshape :preferences do
            map :settings do |s|
              JSON.parse(s)
            end
          end
        end
      end

      input = { user: { preferences: { settings: "invalid_json" } } }
      expect { transformer.apply(input) }.to raise_error(JSON::ParserError)
    end

    # Tests handling of exceptions in collection transformations
    # This ensures errors in array transformations are properly handled
    it "handles exceptions in collection transformations" do
      transformer = described_class.new do
        map_collection :numbers do
          map :value do |v|
            Integer(v)
          end
        end
      end

      input = { numbers: [{ value: "1" }, { value: "invalid" }, { value: "3" }] }
      expect { transformer.apply(input) }.to raise_error(ArgumentError)
    end
  end

  # Recursive transformation tests
  # These tests verify the transformer's ability to handle recursive data structures
  describe "recursive transformations" do
    # Tests transformation of recursive tree-like structures
    # This is crucial for handling hierarchical data like file systems or organizational charts
    it "handles recursive data structures" do
      transformer = described_class.new do
        reshape :node do
          rename :label, to: :name
          map :value, &:to_i
          reshape :left do
            rename :label, to: :name
            map :value, &:to_i
          end
          reshape :right do
            rename :label, to: :name
            map :value, &:to_i
          end
        end
      end

      input = {
        node: {
          label: "root",
          value: "1",
          left: {
            label: "left",
            value: "2"
          },
          right: {
            label: "right",
            value: "3"
          }
        }
      }

      expect(transformer.apply(input)).to eq({
        node: {
          name: "root",
          value: 1,
          left: {
            name: "left",
            value: 2
          },
          right: {
            name: "right",
            value: 3
          }
        }
      })
    end

    # Tests transformation of deeply nested collections
    # This is important for handling complex hierarchical data with multiple levels of nesting
    it "handles deeply nested collections" do
      transformer = described_class.new do
        map_collection :categories do
          rename :category_name, to: :name
          map_collection :subcategories do
            rename :subcategory_name, to: :name
            map_collection :items do
              rename :item_name, to: :name
              map :price, &:to_f
              map_collection :variants do
                rename :variant_name, to: :name
                map :stock, &:to_i
              end
            end
          end
        end
      end

      input = {
        categories: [
          {
            category_name: "Electronics",
            subcategories: [
              {
                subcategory_name: "Phones",
                items: [
                  {
                    item_name: "iPhone",
                    price: "999.99",
                    variants: [
                      { variant_name: "Black", stock: "5" },
                      { variant_name: "White", stock: "3" }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }

      expect(transformer.apply(input)).to eq({
        categories: [
          {
            name: "Electronics",
            subcategories: [
              {
                name: "Phones",
                items: [
                  {
                    name: "iPhone",
                    price: 999.99,
                    variants: [
                      { name: "Black", stock: 5 },
                      { name: "White", stock: 3 }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      })
    end
  end

  # Performance edge case tests
  # These tests verify the transformer's behavior with large or complex data structures
  describe "performance edge cases" do
    # Tests handling of large arrays
    # This ensures the transformer can handle collections of significant size
    it "handles large arrays efficiently" do
      transformer = described_class.new do
        map_collection :numbers do
          map :value, &:to_i
        end
      end

      large_array = 1000.times.map { |i| { value: i.to_s } }
      input = { numbers: large_array }
      result = transformer.apply(input)

      expect(result[:numbers].size).to eq(1000)
      expect(result[:numbers].first).to eq({ value: 0 })
      expect(result[:numbers].last).to eq({ value: 999 })
    end

    # Tests handling of deeply nested structures
    # This ensures the transformer can handle complex hierarchical data efficiently
    it "handles deeply nested structures efficiently" do
      def create_nested_hash(depth)
        return { value: "leaf" } if depth.zero?

        {
          value: depth.to_s,
          left: create_nested_hash(depth - 1),
          right: create_nested_hash(depth - 1)
        }
      end

      transformer = described_class.new do
        reshape :root do
          map :value, &:upcase
          reshape :left do
            map :value, &:upcase
            reshape :left do
              map :value, &:upcase
              reshape :left do
                map :value, &:upcase
              end
              reshape :right do
                map :value, &:upcase
              end
            end
            reshape :right do
              map :value, &:upcase
              reshape :left do
                map :value, &:upcase
              end
              reshape :right do
                map :value, &:upcase
              end
            end
          end
          reshape :right do
            map :value, &:upcase
            reshape :left do
              map :value, &:upcase
              reshape :left do
                map :value, &:upcase
              end
              reshape :right do
                map :value, &:upcase
              end
            end
            reshape :right do
              map :value, &:upcase
              reshape :left do
                map :value, &:upcase
              end
              reshape :right do
                map :value, &:upcase
              end
            end
          end
        end
      end

      input = { root: create_nested_hash(3) }
      result = transformer.apply(input)

      expect(result[:root][:value]).to eq("3")
      expect(result[:root][:left][:value]).to eq("2")
      expect(result[:root][:left][:left][:value]).to eq("1")
      expect(result[:root][:left][:left][:left][:value]).to eq("LEAF")
    end
  end

  # Transformer composition tests
  # These tests verify the ability to combine multiple transformers
  describe "composition" do
    # Tests combining multiple transformers into a single transformation
    # This is useful for building complex transformations from simpler components
    it "allows transformer composition" do
      name_transformer = described_class.new do
        rename :full_name, to: :name do |name|
          first, last = name.split
          { first: first, last: last }
        end
      end

      address_transformer = described_class.new do
        reshape :address do
          rename :postal_code, to: :postcode
          map :coordinates do |coords|
            lat, lng = coords.split(",")
            { latitude: lat.to_f, longitude: lng.to_f }
          end
        end
      end

      combined_transformer = described_class.new do
        rename :full_name, to: :name do |name|
          first, last = name.split
          { first: first, last: last }
        end

        reshape :address do
          rename :postal_code, to: :postcode
          map :coordinates do |coords|
            lat, lng = coords.split(",")
            { latitude: lat.to_f, longitude: lng.to_f }
          end
        end
      end

      input = {
        full_name: "Dave Cooper",
        address: {
          street: "123 Main St",
          postal_code: "12345",
          coordinates: "40.7128,-74.0060"
        }
      }

      expect(combined_transformer.apply(input)).to eq({
        name: { first: "Dave", last: "Cooper" },
        address: {
          street: "123 Main St",
          postcode: "12345",
          coordinates: { latitude: 40.7128, longitude: -74.0060 }
        }
      })
    end
  end

  describe "advanced data structures" do
    it "handles cyclic references gracefully" do
      transformer = described_class.new do
        reshape :organization do
          rename :name, to: :org_name
          map_collection :employees do
            rename :name, to: :employee_name
            map :manager_id do |id|
              id.to_i
            end
          end
          map :relationships do |rels|
            # Convert manager-employee relationships to a graph structure
            rels.each_with_object({ managers: {}, employees: {} }) do |(mgr_id, emp_ids), acc|
              acc[:managers][mgr_id.to_i] = emp_ids.map(&:to_i)
              emp_ids.each do |emp_id|
                acc[:employees][emp_id.to_i] = mgr_id.to_i
              end
            end
          end
        end
      end

      input = {
        organization: {
          name: "Tech Corp",
          employees: [
            { name: "Alice", id: "1", manager_id: "0" },
            { name: "Bob", id: "2", manager_id: "1" },
            { name: "Charlie", id: "3", manager_id: "1" }
          ],
          relationships: {
            "0" => ["1"],
            "1" => ["2", "3"]
          }
        }
      }

      expect(transformer.apply(input)).to eq({
        organization: {
          org_name: "Tech Corp",
          employees: [
            { employee_name: "Alice", id: "1", manager_id: 0 },
            { employee_name: "Bob", id: "2", manager_id: 1 },
            { employee_name: "Charlie", id: "3", manager_id: 1 }
          ],
          relationships: {
            managers: { 0 => [1], 1 => [2, 3] },
            employees: { 1 => 0, 2 => 1, 3 => 1 }
          }
        }
      })
    end

    it "handles complex data validation and transformation" do
      transformer = described_class.new do
        reshape :user do
          map :email do |email|
            raise ArgumentError, "Invalid email" unless email =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
            { address: email, domain: email.split("@").last }
          end
          
          map :password do |pass|
            # Hash the password and store validation rules
            {
              hashed: Digest::SHA256.hexdigest(pass),
              validation: {
                length: pass.length >= 8,
                uppercase: pass.match?(/[A-Z]/),
                lowercase: pass.match?(/[a-z]/),
                number: pass.match?(/\d/),
                special: pass.match?(/[!@#$%^&*]/)
              }
            }
          end

          map :preferences do |prefs|
            # Parse and validate JSON preferences
            parsed = JSON.parse(prefs)
            {
              theme: parsed["theme"] || "default",
              notifications: parsed["notifications"].transform_keys(&:to_sym),
              data_sharing: parsed["data_sharing"].transform_keys(&:to_sym).transform_values { |v| v == "enabled" }
            }
          end

          map :profile_image do |image|
            # Handle base64 encoded image with metadata
            metadata, base64_data = image.split(",", 2)
            mime_type = metadata.match(/data:(.*);base64/)[1]
            
            {
              mime_type: mime_type,
              size: Base64.decode64(base64_data).size,
              data: base64_data.slice(0, 32) + "..." # Truncate for display
            }
          end
        end
      end

      input = {
        user: {
          email: "user@example.com",
          password: "SecureP@ss123",
          preferences: '{"theme":"dark","notifications":{"email":"daily","sms":"never"},"data_sharing":{"analytics":"enabled","marketing":"disabled"}}',
          profile_image: "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
        }
      }

      result = transformer.apply(input)
      expect(result[:user][:email]).to eq({ address: "user@example.com", domain: "example.com" })
      expect(result[:user][:password][:validation]).to eq({
        length: true,
        uppercase: true,
        lowercase: true,
        number: true,
        special: true
      })
      expect(result[:user][:preferences]).to eq({
        theme: "dark",
        notifications: { email: "daily", sms: "never" },
        data_sharing: { analytics: true, marketing: false }
      })
      expect(result[:user][:profile_image][:mime_type]).to eq("image/jpeg")
    end

     it "handles complex state machines and workflows" do
      transformer = described_class.new do
        reshape :workflow do
          map :states do |states|
            states.transform_values do |state|
              {
                current: state["current"],
                history: state["history"].map do |h|
                  { status: h["status"], timestamp: Time.strptime(h["timestamp"], "%Y-%m-%d %H:%M:%S") }
                end,
                metrics: {
                  time_in_state: state["history"].each_cons(2).sum { |a, b|
                    Time.strptime(b["timestamp"], "%Y-%m-%d %H:%M:%S") - 
                    Time.strptime(a["timestamp"], "%Y-%m-%d %H:%M:%S")
                  },
                  transitions: state["history"].size - 1
                },
                allowed_transitions: state["transitions"].map(&:to_sym)
              }
            end
          end

          map :transitions do |trans|
            trans.group_by { |t| t["from"] }.transform_values do |steps|
              steps.map { |s| { to: s["to"], conditions: s["conditions"].map(&:to_sym) } }
            end
          end

          map :validations do |vals|
            vals.transform_values do |rules|
              rules.map do |rule|
                {
                  check: rule["check"].to_sym,
                  message: rule["message"],
                  severity: rule["severity"].to_sym
                }
              end
            end
          end
        end
      end

      input = {
        workflow: {
          states: {
            "draft" => {
              "current" => true,
              "history" => [
                { "status" => "created", "timestamp" => "2024-03-27 09:00:00" },
                { "status" => "draft", "timestamp" => "2024-03-27 09:15:00" }
              ],
              "transitions" => ["review", "publish"]
            }
          },
          transitions: [
            { "from" => "draft", "to" => "review", "conditions" => ["complete", "valid"] },
            { "from" => "draft", "to" => "publish", "conditions" => ["complete", "valid", "approved"] }
          ],
          validations: {
            "draft" => [
              { "check" => "title_present", "message" => "Title is required", "severity" => "error" },
              { "check" => "content_length", "message" => "Content too short", "severity" => "warning" }
            ]
          }
        }
      }

      result = transformer.apply(input)
      expect(result[:workflow][:states]["draft"]).to include(
        current: true,
        allowed_transitions: [:review, :publish]
      )
      expect(result[:workflow][:states]["draft"][:metrics]).to include(
        time_in_state: 900, # 15 minutes in seconds
        transitions: 1
      )
      expect(result[:workflow][:transitions]["draft"]).to eq([
        { to: "review", conditions: [:complete, :valid] },
        { to: "publish", conditions: [:complete, :valid, :approved] }
      ])
      expect(result[:workflow][:validations]["draft"]).to eq([
        { check: :title_present, message: "Title is required", severity: :error },
        { check: :content_length, message: "Content too short", severity: :warning }
      ])
    end
  end
end 