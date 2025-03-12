# frozen_string_literal: true

require_relative "global_id_serialiser/version"

require "global_id"
require "json"

class GlobalIdSerialiser
  def self.marshal(data) = pack(data)

  def self.dump(data) = JSON.generate(marshal(data))

  def self.unmarshal(data) = unpack(data)

  def self.load(json) = unmarshal(JSON.parse(json))

  private_class_method def self.pack argument
    case argument
    when GlobalID::Identification then pack_global_id argument
    when Array then pack_array argument
    when Hash then pack_hash argument
    else argument
    end
  end

  private_class_method def self.unpack argument
    case argument
    when String then unpack_string argument
    when Array then unpack_array argument
    when Hash then unpack_hash argument
    else argument
    end
  end

  private_class_method def self.pack_array(arguments) = arguments.map { |a| pack a }

  private_class_method def self.pack_hash(arguments) = arguments.transform_values { |v| pack v }

  private_class_method def self.pack_global_id(argument) = argument.to_global_id.to_s

  private_class_method def self.unpack_array(arguments) = arguments.map { |a| unpack a }

  private_class_method def self.unpack_hash(arguments) = arguments.to_h { |key, value| [key.to_sym, unpack(value)] }

  private_class_method def self.unpack_string(argument) = argument.start_with?("gid://") ? unpack_global_id(argument) : argument

  private_class_method def self.unpack_global_id argument
    GlobalID::Locator.locate(argument)
  rescue
    nil
  end
end
