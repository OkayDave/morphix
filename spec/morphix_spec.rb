# frozen_string_literal: true

RSpec.describe Morphix do
  it "has a version number" do
    expect(Morphix::VERSION).not_to be nil
  end

  it "creates a transformer with the DSL" do
    transformer = Morphix.define do
      rename :old_name, to: :new_name
    end

    input = { old_name: "test" }
    result = transformer.apply(input)

    expect(result).to eq({ new_name: "test" })
  end
end
