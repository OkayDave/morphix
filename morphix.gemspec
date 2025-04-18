# frozen_string_literal: true

require_relative "lib/morphix/version"

Gem::Specification.new do |spec|
  spec.name = "morphix"
  spec.version = Morphix::VERSION
  spec.authors = ["Dave Russell"]
  spec.email = ["dave.kerr@gmail.com"]

  spec.summary = "A powerful DSL for transforming data structures like hashes and JSON. " \
                 "Perfect for API response normalization, JSON reshaping, and ETL pipelines."
  spec.description = "Morphix provides a clear, expressive DSL for transforming data structures in Ruby. " \
                     "Perfect for API response normalization, JSON reshaping, and ETL pipelines."
  spec.homepage = "https://github.com/OkayDave/morphix"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/OkayDave/morphix"
  spec.metadata["changelog_uri"] = "https://github.com/OkayDave/morphix/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "base64", "~> 0.2.0"
end
