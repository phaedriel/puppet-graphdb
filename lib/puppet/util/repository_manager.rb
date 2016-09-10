$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/util/request_manager'

module Puppet
  module Util
    # GraphDB repository manager
    class RepositoryManager
      DATA_TYPE_CONTENT_TYPE = { rdfxml: 'application/rdf+xml; charset=utf-8',
                                 ntriples: 'application/n-triples; charset=utf-8',
                                 turtle: 'application/x-turtle; charset=utf-8',
                                 n3: 'text/n3; charset=utf-8',
                                 trix: 'application/trix; charset=utf-8',
                                 trig: 'application/x-trig; charset=utf-8',
                                 binary: 'application/x-binary-rdf; charset=utf-8',
                                 nquads: 'application/n-quads; charset=utf-8',
                                 jsonld: 'application/ld+json; charset=utf-8',
                                 rdfjson: 'application/rdf+json; charset=utf-8',
                                 rdfa: 'application/html; charset=utf-8' }.freeze

      attr_reader :endpoint
      attr_reader :repository_id

      def initialize(endpoint, repository_id)
        @endpoint = endpoint
        @repository_id = repository_id
      end

      def check_repository(timeout)
        uri = endpoint.dup
        uri.path = "/repositories/#{repository_id}/size"

        Puppet.debug "Checking repository [#{endpoint}/repositories/#{repository_id}]"

        unless repository_exists?(uri)
          Puppet.debug("Repository [#{endpoint}/repositories/#{repository_id}] doesn't exists")
          return false
        end

        if repository_up?(uri, timeout)
          Puppet.debug("Repository [#{endpoint}/repositories/#{repository_id}] up and running")
          return true
        end

        false
      end

      def repository_exists?(uri)
        Puppet::Util::RequestManager.perform_http_request(uri, { method: :get }, { codes: [404] }, 0)
      end

      def repository_up?(uri, timeout)
        Puppet::Util::RequestManager.perform_http_request(uri,
                                                          { method: :get },
                                                          { messages: ['No workers configured', '\d+'],
                                                            codes: [200, 500] }, timeout)
      end

      def create_repository(repository_template, repository_context, timeout)
        Puppet.debug "Trying to create repository [#{endpoint}/repositories/#{repository_id}]"
        uri = endpoint.dup
        uri.path = '/repositories/SYSTEM/rdf-graphs/service'

        result = Puppet::Util::RequestManager.perform_http_request(uri,
                                                                   { method: :post,
                                                                     params: { 'graph' => repository_context },
                                                                     body_data: repository_template,
                                                                     content_type: 'application/x-turtle' },
                                                                   { codes: [204] },
                                                                   timeout)
        if result
          Puppet.notice("Repository [#{endpoint}/repositories/#{repository_id}] creation passed.")
          return true
        end

        Puppet.notice("Repository creation failed [#{endpoint}/repositories/#{repository_id}]")
        false
      end

      def delete_repository(timeout)
        uri = endpoint.dup
        uri.path = "/repositories/#{repository_id}"

        Puppet.debug "Trying to delete repository [#{endpoint}/repositories/#{repository_id}]"
        Puppet::Util::RequestManager.perform_http_request(uri,
                                                          { method: :delete, content_type: 'application/x-turtle' },
                                                          { codes: [204] },
                                                          timeout)
      end

      def ask(query, expected_response, timeout)
        uri = endpoint.dup
        uri.path = "/repositories/#{repository_id}"

        Puppet.debug "Trying to ask repository [#{endpoint}/#{repository_id}]"
        Puppet::Util::RequestManager.perform_http_request(uri, { method: :get,
                                                                 params: { 'query' => query },
                                                                 content_type: 'application/x-www-form-urlencoded',
                                                                 accept_type: 'text/boolean' },
                                                          { messages: [expected_response.to_s], codes: [200] },
                                                          timeout)
      end

      def update_query(query, timeout)
        uri = endpoint.dup
        uri.path = "/repositories/#{repository_id}/statements"

        Puppet.debug "Trying to post update query to repository [#{endpoint}/#{repository_id}]"
        Puppet::Util::RequestManager.perform_http_request(uri,
                                                          { method: :post,
                                                            body_params: { 'update' => query },
                                                            content_type: 'application/x-www-form-urlencoded' },
                                                          { codes: [204] },
                                                          timeout)
      end

      def load_data(data, data_format, data_context, overwrite, timeout)
        method = overwrite == true ? :put : :post
        uri = endpoint.dup
        uri.path = "/repositories/#{repository_id}/statements"

        context = data_context.nil? ? 'null' : data_context

        Puppet.debug "Trying to load data into repository [#{endpoint}/#{repository_id}]"
        Puppet::Util::RequestManager.perform_http_request(uri,
                                                          { method: method,
                                                            params: { 'context' => context },
                                                            body_data: data,
                                                            content_type: resolve_content_type(data_format) },
                                                          { codes: [204] },
                                                          timeout)
      end

      def resolve_content_type(data_format)
        return DATA_TYPE_CONTENT_TYPE[data_format.to_sym] if DATA_TYPE_CONTENT_TYPE.key?(data_format.to_sym)
        raise ArgumentError, "Uknown data format #{data_format}, please check"
      end
    end
  end
end
