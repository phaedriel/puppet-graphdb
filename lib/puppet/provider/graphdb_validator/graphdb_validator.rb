# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/util/request_manager'
require 'puppet/exceptions/request_fail'

Puppet::Type.type(:graphdb_validator).provide(:graphdb_validator) do
  desc "A provider for the resource type `graphdb_validator`,
		which checks whether GraphDB instance is running"

  def exists?
    uri = resource[:endpoint]
    uri.path = '/protocol'
    Puppet::Util::RequestManager.perform_http_request(uri, { method: :get }, { codes: [200] }, resource[:timeout])
    true
  rescue Puppet::Exceptions::RequestFailError
    false
  end
end
