# Morphix

A concise, expressive DSL for elegantly reshaping and transforming Ruby hashes and JSON structures.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "morphix"
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install morphix
```

## Core Features

- **Fluent DSL**: Clean, readable chainable methods (`rename`, `map`, `reject`, `reshape`, `map_collection`)
- **Nested Transformation**: Easily define transformations inside nested hashes or collections
- **Reusable Transformers**: Define transformations once, reuse them multiple times
- **Functional Style**: Immutable by default—returns new objects, leaving input untouched
- **Flexible & Extensible**: Easy to add custom transformations via Ruby blocks
- **Error Handling**: Robust error handling for edge cases and invalid data
- **Performance Optimized**: Efficiently handles large and complex data structures

## Common Use Cases

### API Response Normalization

```ruby
transformer = Morphix::Transformer.new do
  rename :user_full_name, to: :name
  map :created_at do |timestamp|
    Time.parse(timestamp)
  end
  reshape :address do
    rename :postal_code, to: :postcode
    map :coordinates do |coords|
      { lat: coords[:lat].to_f, lng: coords[:lng].to_f }
    end
  end
end

# Use it to normalize API responses
response = api_client.get_user(123)
normalized_data = transformer.apply(response)
```

### Data Migration

```ruby
transformer = Morphix::Transformer.new do
  map_collection :records do
    rename :legacy_id, to: :id
    map :status do |status|
      case status
      when "ACTIVE" then "active"
      when "INACTIVE" then "inactive"
      else "unknown"
      end
    end
    reshape :metadata do
      map :created_at, &:to_s
      map :updated_at, &:to_s
    end
  end
end

# Transform legacy data format to new format
legacy_data = load_legacy_records()
new_data = transformer.apply(legacy_data)
```

### Data Sanitization

```ruby
transformer = Morphix::Transformer.new do
  reject :password, :ssn, :credit_card
  map :email do |email|
    email.to_s.downcase.strip
  end
  map :phone do |phone|
    phone.to_s.gsub(/[^0-9]/, "")
  end
end

# Sanitize user input before processing
user_data = get_user_input()
sanitized_data = transformer.apply(user_data)
```

## Usage

Morphix provides a simple DSL for transforming data structures. Here are some examples:

### Basic Transformations

#### Renaming Keys

```ruby
transformer = Morphix::Transformer.new do
  rename :old_name, to: :new_name
end

input = { old_name: "Dave" }
result = transformer.apply(input)
# => { new_name: "Dave" }
```

#### Transforming Values

```ruby
transformer = Morphix::Transformer.new do
  map :age, &:to_i
end

input = { age: "40" }
result = transformer.apply(input)
# => { age: 40 }
```

#### Removing Keys

```ruby
transformer = Morphix::Transformer.new do
  reject :password
end

input = { name: "Dave", password: "secret" }
result = transformer.apply(input)
# => { name: "Dave" }
```

### Nested Transformations

#### Transforming Nested Hashes

```ruby
transformer = Morphix::Transformer.new do
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
# => {
#      address: {
#        street: "Main St",
#        postcode: "S2",
#        verified: true
#      }
#    }
```

#### Transforming Collections

```ruby
transformer = Morphix::Transformer.new do
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
# => {
#      users: [
#        { name: "Dave" },
#        { name: "Jason" }
#      ]
#    }
```

### Complex Transformations

#### Combining Multiple Transformations

```ruby
transformer = Morphix::Transformer.new do
  rename :full_name, to: :name
  map :age, &:to_i
  reject :password
  reshape :address do
    rename :postal_code, to: :postcode
    map :coordinates do |coords|
      { lat: coords[:lat].to_f, lng: coords[:lng].to_f }
    end
  end
end

input = {
  full_name: "Dave Cooper",
  age: "40",
  password: "secret",
  address: {
    street: "123 Main St",
    postal_code: "12345",
    coordinates: { lat: "40.7128", lng: "-74.0060" }
  }
}
result = transformer.apply(input)
# => {
#      name: "Dave Cooper",
#      age: 40,
#      address: {
#        street: "123 Main St",
#        postcode: "12345",
#        coordinates: { lat: 40.7128, lng: -74.0060 }
#      }
#    }
```

### Advanced Features

#### Conditional Transformations

```ruby
transformer = Morphix::Transformer.new do
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
result = transformer.apply(input)
# => { status: 1 }
```

#### Complex Data Type Conversions

```ruby
transformer = Morphix::Transformer.new do
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
# => {
#      dates: {
#        created: #<Time 2024-03-27 10:30:00>,
#        updated: #<Time 2024-03-28 15:45:00>
#      },
#      numbers: { latitude: 40.7128, longitude: -74.0060 },
#      flags: { active: true, deleted: false, archived: true }
#    }
```

#### Handling Complex Data Structures

```ruby
transformer = Morphix::Transformer.new do
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
      }
    ]
  }
}
result = transformer.apply(input)
# => {
#      organization: {
#        departments: [
#          {
#            name: "Engineering",
#            employees: [
#              { name: "Dave Cooper", age: 35 },
#              { name: "Alice Smith", age: 28 }
#            ]
#          }
#        ]
#      }
#    }
```

### Error Handling

Morphix provides robust error handling for various edge cases:

```ruby
transformer = Morphix::Transformer.new do
  map :number do |n|
    Integer(n)
  end
end

input = { number: "not_a_number" }
begin
  transformer.apply(input)
rescue ArgumentError => e
  puts "Invalid number format: #{e.message}"
end
```

### Performance Considerations

Morphix is designed to handle large and complex data structures efficiently:

```ruby
transformer = Morphix::Transformer.new do
  map_collection :numbers do
    map :value, &:to_i
  end
end

# Handles large arrays efficiently
large_array = 1000.times.map { |i| { value: i.to_s } }
input = { numbers: large_array }
result = transformer.apply(input)
```

## Troubleshooting

### Common Issues

1. **Missing Keys**
   ```ruby
   # If a key doesn't exist, it's simply ignored
   transformer = Morphix::Transformer.new do
     rename :missing_key, to: :new_key
   end
   input = { other_key: "value" }
   result = transformer.apply(input)
   # => { other_key: "value" }
   ```

2. **Nil Values**
   ```ruby
   # Handle nil values safely
   transformer = Morphix::Transformer.new do
     map :age do |value|
       value&.to_i
     end
   end
   input = { age: nil }
   result = transformer.apply(input)
   # => { age: nil }
   ```

3. **Invalid Data Types**
   ```ruby
   # Handle unexpected data types gracefully
   transformer = Morphix::Transformer.new do
     reshape :config do
       rename :api_key, to: :key
     end
   end
   input = { config: "invalid" }
   result = transformer.apply(input)
   # => { config: "invalid" }
   ```

### Best Practices

1. **Keep Transformers Focused**
   ```ruby
   # Good: Single responsibility
   user_transformer = Morphix::Transformer.new do
     rename :username, to: :name
     map :age, &:to_i
   end

   # Bad: Too many responsibilities
   transformer = Morphix::Transformer.new do
     rename :username, to: :name
     map :age, &:to_i
     reshape :address do
       rename :postal_code, to: :postcode
     end
     map_collection :orders do
       map :total, &:to_f
     end
   end
   ```

2. **Use Composition for Complex Transformations**
   ```ruby
   # Break down complex transformations into smaller, reusable parts
   name_transformer = Morphix::Transformer.new do
     rename :full_name, to: :name do |name|
       first, last = name.split
       { first: first, last: last }
     end
   end

   address_transformer = Morphix::Transformer.new do
     reshape :address do
       rename :postal_code, to: :postcode
       map :coordinates do |coords|
         { lat: coords[:lat].to_f, lng: coords[:lng].to_f }
       end
     end
   end

   # Combine transformers for complex transformations
   combined_transformer = Morphix::Transformer.new do
     rename :full_name, to: :name do |name|
       first, last = name.split
       { first: first, last: last }
     end
     reshape :address do
       rename :postal_code, to: :postcode
       map :coordinates do |coords|
         { lat: coords[:lat].to_f, lng: coords[:lng].to_f }
       end
     end
   end
   ```

3. **Handle Edge Cases Explicitly**
   ```ruby
   transformer = Morphix::Transformer.new do
     map :status do |status|
       case status&.to_s&.downcase
       when "active", "1", "true" then "active"
       when "inactive", "0", "false" then "inactive"
       else "unknown"
       end
     end
   end
   ```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/OkayDave/morphix.

## License

The gem is available as open source under the terms of the MIT License.
