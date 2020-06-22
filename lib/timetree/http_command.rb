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

    def get(path, params = {})
      logger.info "GET #{connection.build_url("#{@host}#{path}", params)}"
      res = connection.get path, params
      @client.update_ratelimit(res)
      logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    def put(path, params = {})
      logger.debug "PUT #{@host}#{path} body:#{params}"
      res = connection.put path do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end
      @client.update_ratelimit(res)
      logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    def post(path, params = {})
      @logger.debug "POST #{@host}#{path} body:#{params}"
      res = connection.post path, params do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end
      @client.update_ratelimit(res)
      logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    def delete(path, params = {})
      @logger.debug "DELETE #{@host}#{path} params:#{params}"
      res = connection.delete path, params
      @client.update_ratelimit(res)
      logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    private

    attr_reader :logger

    def connection
      Faraday.new(
        url: @host,
        headers: {
          'Accept' => 'application/vnd.timetree.v1+json',
          'Authorization' => "Bearer #{@client.access_token}"
        }
      ) do |builder|
        builder.response :json, parser_options: { symbolize_names: true }, content_type: /\bjson$/
      end
    end
  end
end
