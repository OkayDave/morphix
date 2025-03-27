# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-03-27

### Added
- Initial release of Morphix
- Core transformation methods:
  - `rename`: Rename keys with optional value transformation
  - `map`: Transform values while preserving keys
  - `reject`: Remove specific keys from the hash
  - `reshape`: Transform nested hash structures
  - `map_collection`: Transform arrays of hashes
- Support for complex data transformations:
  - Nested structure handling
  - Collection transformations
  - Conditional transformations
  - Data type conversions
- Robust error handling for edge cases
- Performance optimizations for large data structures
- Comprehensive test suite with RSpec
- Detailed documentation and examples

### Features
- Fluent DSL for data transformation
- Immutable transformations (original data remains unchanged)
- Support for deeply nested data structures
- Efficient handling of large collections
- Flexible and extensible transformation blocks
- Type-safe transformations with error handling

### Documentation
- Comprehensive README with examples
- Best practices and troubleshooting guide
- Common use cases documentation
- API documentation
- Performance considerations

### Development
- Ruby 3.1.0 or higher required
- RSpec for testing
- RuboCop for code style enforcement
- Base64 dependency for encoding/decoding support

[0.1.0]: https://github.com/OkayDave/morphix/releases/tag/v0.1.0
