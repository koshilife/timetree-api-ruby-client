# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

module TimeTree
  # Command for HTTP request.
  class HttpCommand
    def initialize(host, client)
      @host = host
      @client = client
      @logger = TimeTree.configuration.logger
    end

    # @param path [String] String or URI to access.
    # @param params [Hash] Hash of URI query unencoded key/value pairs.
    def get(path, params = {})
      @logger.info "GET #{connection.build_url("#{@host}#{path}", params)}"
      res = connection.get path, params
      @client.update_ratelimit(res)
      @logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    # @param path [String] String or URI to access.
    # @param body_params [Hash]
    # The request bodythat will eventually be converted to JSON.
    def post(path, body_params = {})
      @logger.debug "POST #{@host}#{path} body:#{body_params}"
      headers = {'Content-Type' => 'application/json'}
      res = connection.run_request :post, path, body_params.to_json, headers
      @client.update_ratelimit(res)
      @logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    # @param path [String] String or URI to access.
    # @param body_params [Hash]
    # The request bodythat will eventually be converted to JSON.
    def put(path, body_params = {})
      @logger.debug "PUT #{@host}#{path} body:#{body_params}"
      headers = {'Content-Type' => 'application/json'}
      res = connection.run_request :put, path, body_params.to_json, headers
      @client.update_ratelimit(res)
      @logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    # @param path [String] String or URI to access.
    # @param params [Hash] Hash of URI query unencoded key/value pairs.
    def delete(path, params = {})
      @logger.debug "DELETE #{@host}#{path} params:#{params}"
      res = connection.delete path, params
      @client.update_ratelimit(res)
      @logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

  private

    def connection
      Faraday.new(
        url: @host,
        headers: base_request_headers
      ) do |builder|
        builder.response :json, parser_options: {symbolize_names: true}, content_type: /\bjson$/
      end
    end

    def base_request_headers
      {
        'Accept' => 'application/vnd.timetree.v1+json',
        'Authorization' => "Bearer #{@client.token}"
      }
    end
  end
end
