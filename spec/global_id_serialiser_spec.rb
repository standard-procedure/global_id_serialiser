# frozen_string_literal: true

require "active_record"
RSpec.describe GlobalIdSerialiser do
  include ActiveRecord::Tasks

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

  class Parent < ActiveRecord::Base
    include GlobalID::Identification
    has_many :children, dependent: :destroy
    serialize :data, coder: GlobalIdSerialiser, type: Hash
    def to_s = name
  end

  class Child < ActiveRecord::Base
    include GlobalID::Identification
    belongs_to :parent
    serialize :data, coder: GlobalIdSerialiser, type: Hash
    def to_s = name
  end
  # standard:enable Lint/ConstantDefinitionInBlock

  before { GlobalID.app = "global_id_serialiser" }

  it "has a version number" do
    expect(GlobalIdSerialiser::VERSION).not_to be nil
  end

  describe "writing data to JSON" do
    it "writes simple types" do
      @data = {hello: "world", number: 999}

      expect(GlobalIdSerialiser.to_h(@data)).to eq @data
    end

    it "writes nested hashes and arrays" do
      @data = {some: {more: "data"}, many: %w[things in this array]}

      expect(GlobalIdSerialiser.to_h(@data)).to eq @data
    end

    it "writes models" do
      @alice = User.new(id: 123, name: "Alice")
      @data = {user: @alice}

      @expected_data = {user: @alice.to_global_id.to_s}
      expect(GlobalIdSerialiser.to_h(@data)).to eq @expected_data
    end

    it "writes nested models" do
      @alice = User.new(id: 123, name: "Alice")
      @bob = User.new(id: 456, name: "Bob")
      @data = {nested: {user: @alice}, people: [@alice, @bob]}

      @expected_data = {nested: {user: @alice.to_global_id.to_s}, people: [@alice.to_global_id.to_s, @bob.to_global_id.to_s]}
      expect(GlobalIdSerialiser.to_h(@data)).to eq @expected_data
    end

    it "writes multiple models" do
      @users = (1..10).collect { |i| User.new(id: i, name: i.to_s) }
      @more_users = (100..110).collect { |i| User.new(id: i, name: i.to_s) }
      @documents = (1..10).collect { |i| Document.new(id: i, filename: "#{i}.pdf") }

      @data = {users: @users, documents: @documents, more_users: {users: @more_users}}

      @user_ids = @users.map { |u| u.to_global_id.to_s }
      @more_user_ids = @more_users.map { |u| u.to_global_id.to_s }
      @document_ids = @documents.map { |d| d.to_global_id.to_s }
      @expected_data = {users: @user_ids, documents: @document_ids, more_users: {users: @more_user_ids}}
      expect(GlobalIdSerialiser.to_h(@data)).to eq @expected_data
    end
  end

  describe "serialising data (as used by ActiveRecord)" do
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

  describe "reads data from JSON" do
    it "reads simple types" do
      @data = {hello: "world", number: 999}

      expect(GlobalIdSerialiser.from_h(@data)).to eq @data
    end

    it "reads nested hashes and arrays" do
      @data = {some: {more: "data"}, many: %w[things in this array]}

      expect(GlobalIdSerialiser.from_h(@data)).to eq @data
    end

    it "reads models" do
      @alice = User.new(id: 123, name: "Alice")
      @data = {user: @alice.to_global_id.to_s}

      @expected_data = {user: @alice}
      expect(GlobalIdSerialiser.from_h(@data)).to eq @expected_data
    end

    it "reads nested models" do
      @alice = User.new(id: 123, name: "Alice")
      @bob = User.new(id: 456, name: "Bob")
      @data = {nested: {user: @alice.to_global_id.to_s}, people: [@alice.to_global_id.to_s, @bob.to_global_id.to_s]}
      @expected_data = {nested: {user: @alice}, people: [@alice, @bob]}

      expect(GlobalIdSerialiser.from_h(@data)).to eq @expected_data
    end

    it "reads multiple models" do
      @users = (1..10).collect { |i| User.new(id: i, name: i.to_s) }
      @more_users = (100..110).collect { |i| User.new(id: i, name: i.to_s) }
      @documents = (1..10).collect { |i| Document.new(id: i, filename: "#{i}.pdf") }

      @user_ids = @users.map { |u| u.to_global_id.to_s }
      @more_user_ids = @more_users.map { |u| u.to_global_id.to_s }
      @document_ids = @documents.map { |d| d.to_global_id.to_s }
      @data = {users: @user_ids, documents: @document_ids, more_users: {users: @more_user_ids}}

      @expected_data = {users: @users, documents: @documents, more_users: {users: @more_users}}

      expect(GlobalIdSerialiser.from_h(@data)).to eq @expected_data
    end
  end

  describe "deserialising data (as used by ActiveRecord)" do
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

  describe "in ActiveRecord" do
    it "reads and handles circular references" do
      FileUtils.rm_f "tmp/test.sqlite3"
      ActiveRecord::Base.establish_connection adapter: "sqlite3", database: "tmp/test.sqlite3"
      ActiveRecord::Base.connection.create_table :parents do |t|
        t.string :name
        t.text :data
      end
      ActiveRecord::Base.connection.create_table :children do |t|
        t.references :parent
        t.string :name
        t.text :data
      end

      @parent = Parent.create name: "Parent"
      @first_child = Child.create name: "First", parent: @parent, data: {also_parent: @parent}
      @second_child = Child.create name: "Second", parent: @parent, data: {also_parent: @parent, sibling: @first_child}

      @parent.update data: {also_children: [@first_child, @second_child]}

      # Reload data with circular references
      @parent_again = Parent.find @parent.id
      @first_child_again = Child.find @first_child.id
      @second_child_again = Child.find @second_child.id

      expect(@parent_again.data[:also_children]).to eq [@first_child_again, @second_child_again]
      expect(@first_child_again.data[:also_parent]).to eq @parent_again
      expect(@second_child_again.data[:sibling]).to eq @first_child_again
    end
  end
end
