# frozen_string_literal: true

require_relative "global_id_serialiser/version"

require "global_id"

class GlobalIdSerialiser
  def self.dump(data) = pack(data)

  def self.load(json) = unpack(json)

  private def pack argument
    case argument
    when GlobalID::Identification then pack_global_id argument
    when Array then pack_array argument
    when Hash then pack_hash argument
    else argument
    end
  end

  private def unpack argument
    case argument
    when String then unpack_string argument
    when Array then unpack_array argument
    when Hash then unpack_hash argument
    else argument
    end
  end

  private def pack_array(arguments) = arguments.map { |a| pack a }

  private def pack_hash(arguments) = arguments.transform_values { |v| pack v }

  private def pack_global_id(argument) = argument.to_global_id.to_s

  private def unpack_array(arguments) = arguments.map { |a| unpack a }

  private def unpack_hash(arguments) = arguments.to_h { |key, value| [key, unpack(value)] }

  private def unpack_string(argument) = argument.start_with?("gid://") ? unpack_global_id(argument) : argument

  private def unpack_global_id argument
    GlobalID::Locator.locate(argument)
  rescue
    nil
  end
end
