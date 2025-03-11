# frozen_string_literal: true

RSpec.describe GlobalIdSerialiser do
  # standard:disable Lint/ConstantDefinitionInBlock
  class User
    include GlobalID::Identification
    def initialize id:, name:
      @id = id
      @name = name
      self.class.records[@id.to_s] = self
    end
    attr_reader :id, :name

    def self.find(id) = records[id.to_s]

    def self.records = @records ||= {}
  end
  # standard:enable Lint/ConstantDefinitionInBlock

  before { GlobalID.app = "global_id_serialiser" }

  it "has a version number" do
    expect(GlobalIdSerialiser::VERSION).not_to be nil
  end

  describe "serialising data" do
    it "serialises simple types" do
      @data = {hello: "world", number: 999}

      expect(GlobalIdSerialiser.dump(@data)).to eq JSON.generate(@data)
    end

    it "serialises nested hashes and arrays" do
      @data = {some: {more: "data"}, many: %w[things in this array]}

      expect(GlobalIdSerialiser.dump(@data)).to eq JSON.generate(@data)
    end

    it "serialises models" do
      @alice = User.new(id: 123, name: "Alice")
      @data = {user: @alice}

      @expected_data = {user: @alice.to_global_id.to_s}
      expect(GlobalIdSerialiser.dump(@data)).to eq JSON.generate(@expected_data)
    end

    it "serialises nested models" do
      @alice = User.new(id: 123, name: "Alice")
      @bob = User.new(id: 456, name: "Bob")
      @data = {nested: {user: @alice}, people: [@alice, @bob]}

      @expected_data = {nested: {user: @alice.to_global_id.to_s}, people: [@alice.to_global_id.to_s, @bob.to_global_id.to_s]}
      expect(GlobalIdSerialiser.dump(@data)).to eq JSON.generate(@expected_data)
    end
  end

  describe "deserialising data" do
    it "deserialises simple types" do
      @json = JSON.generate({hello: "world", number: 999})

      @expected_data = {hello: "world", number: 999}
      expect(GlobalIdSerialiser.load(@json)).to eq @expected_data
    end

    it "deserialises nested hashes and arrays" do
      @json = JSON.generate({some: {more: "data"}, many: %w[things in this array]})

      @expected_data = {some: {more: "data"}, many: %w[things in this array]}
      expect(GlobalIdSerialiser.load(@json)).to eq @expected_data
    end

    it "deserialises models" do
      @alice = User.new(id: 123, name: "Alice")
      @json = JSON.generate({user: @alice.to_global_id.to_s})

      @expected_data = {user: @alice}
      expect(GlobalIdSerialiser.load(@json)).to eq @expected_data
    end

    it "deserialises nested models" do
      @alice = User.new(id: 123, name: "Alice")
      @bob = User.new(id: 456, name: "Bob")
      @json = JSON.generate({nested: {user: @alice.to_global_id.to_s}, people: [@alice.to_global_id.to_s, @bob.to_global_id.to_s]})
      @expected_data = {nested: {user: @alice}, people: [@alice, @bob]}

      expect(GlobalIdSerialiser.load(@json)).to eq @expected_data
    end
  end
end
