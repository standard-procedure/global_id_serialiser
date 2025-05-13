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

  class Document
    include GlobalID::Identification
    def initialize id:, filename:
      @id = id
      @filename = filename
      self.class.records[@id.to_s] = self
    end
    attr_reader :id, :filename

    def self.find(id) = records[id.to_s]

    def self.records = @records ||= {}
  end
  # standard:enable Lint/ConstantDefinitionInBlock

  before { GlobalID.app = "global_id_serialiser" }

  it "has a version number" do
    expect(GlobalIdSerialiser::VERSION).not_to be nil
  end

  describe "marshalling data" do
    it "marshals simple types" do
      @data = {hello: "world", number: 999}

      expect(GlobalIdSerialiser.marshal(@data)).to eq @data
    end

    it "marshals nested hashes and arrays" do
      @data = {some: {more: "data"}, many: %w[things in this array]}

      expect(GlobalIdSerialiser.marshal(@data)).to eq @data
    end

    it "marshals models" do
      @alice = User.new(id: 123, name: "Alice")
      @data = {user: @alice}

      @expected_data = {user: @alice.to_global_id.to_s}
      expect(GlobalIdSerialiser.marshal(@data)).to eq @expected_data
    end

    it "marshals nested models" do
      @alice = User.new(id: 123, name: "Alice")
      @bob = User.new(id: 456, name: "Bob")
      @data = {nested: {user: @alice}, people: [@alice, @bob]}

      @expected_data = {nested: {user: @alice.to_global_id.to_s}, people: [@alice.to_global_id.to_s, @bob.to_global_id.to_s]}
      expect(GlobalIdSerialiser.marshal(@data)).to eq @expected_data
    end

    it "marshals multiple models" do
      @users = (1..10).collect { |i| User.new(id: i, name: i.to_s) }
      @more_users = (100..110).collect { |i| User.new(id: i, name: i.to_s) }
      @documents = (1..10).collect { |i| Document.new(id: i, filename: "#{i}.pdf") }

      @data = {users: @users, documents: @documents, more_users: {users: @more_users}}

      @user_ids = @users.map { |u| u.to_global_id.to_s }
      @more_user_ids = @more_users.map { |u| u.to_global_id.to_s }
      @document_ids = @documents.map { |d| d.to_global_id.to_s }
      @expected_data = {users: @user_ids, documents: @document_ids, more_users: {users: @more_user_ids}}
      expect(GlobalIdSerialiser.marshal(@data)).to eq @expected_data
    end
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

  describe "unmarshalling data" do
    it "unmarshals simple types" do
      @data = {hello: "world", number: 999}

      expect(GlobalIdSerialiser.unmarshal(@data)).to eq @data
    end

    it "unmarshals nested hashes and arrays" do
      @data = {some: {more: "data"}, many: %w[things in this array]}

      expect(GlobalIdSerialiser.unmarshal(@data)).to eq @data
    end

    it "unmarshals models" do
      @alice = User.new(id: 123, name: "Alice")
      @data = {user: @alice.to_global_id.to_s}

      @expected_data = {user: @alice}
      expect(GlobalIdSerialiser.unmarshal(@data)).to eq @expected_data
    end

    it "unmarshals nested models" do
      @alice = User.new(id: 123, name: "Alice")
      @bob = User.new(id: 456, name: "Bob")
      @data = {nested: {user: @alice.to_global_id.to_s}, people: [@alice.to_global_id.to_s, @bob.to_global_id.to_s]}
      @expected_data = {nested: {user: @alice}, people: [@alice, @bob]}

      expect(GlobalIdSerialiser.unmarshal(@data)).to eq @expected_data
    end

    it "unmarshals multiple models" do
      @users = (1..10).collect { |i| User.new(id: i, name: i.to_s) }
      @more_users = (100..110).collect { |i| User.new(id: i, name: i.to_s) }
      @documents = (1..10).collect { |i| Document.new(id: i, filename: "#{i}.pdf") }

      @user_ids = @users.map { |u| u.to_global_id.to_s }
      @more_user_ids = @more_users.map { |u| u.to_global_id.to_s }
      @document_ids = @documents.map { |d| d.to_global_id.to_s }
      @data = {users: @user_ids, documents: @document_ids, more_users: {users: @more_user_ids}}

      @expected_data = {users: @users, documents: @documents, more_users: {users: @more_users}}

      expect(GlobalIdSerialiser.unmarshal(@data)).to eq @expected_data
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
