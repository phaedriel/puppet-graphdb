# frozen_string_literal: true

Puppet::Type.newtype(:graphdb_validator) do
  @doc = 'Checks whether GraphDB instance is running'

  ensurable do
    desc 'Ensure value.'
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'An arbitrary name used as the identity of the resource.'
  end

  newparam(:endpoint) do
    desc 'Sesame endpoint of GraphDB instance'
    validate do |value|
      URI(value)
    rescue StandardError
      raise(ArgumentError, "endpoint should be valid url: #{value}")
    end
    munge do |value|
      URI(value)
    end
  end

  newparam(:timeout) do
    desc 'The max number of seconds that the validator should wait before giving up
    and deciding that the GraphDB is not running; default: 60 seconds.'
    defaultto 60
    validate do |value|
      Integer(value)
    rescue StandardError
      raise(ArgumentError, "timeout should be valid integer: #{value}")
    end
    munge do |value|
      Integer(value)
    end
  end

  # Autorequire the relevant service if available
  autorequire(:service) do
    repositories = catalog.resources.select do |res|
      next unless res.type == :service

      res if res[:name] == self[:name]
    end
    repositories.collect do |res|
      res[:name]
    end
  end
end
