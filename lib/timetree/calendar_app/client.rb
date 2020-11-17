# frozen_string_literal: true

require 'openssl'
require 'jwt'

module TimeTree
  module CalendarApp
    # TimeTree API CalendarApp client.
    class Client
      API_HOST = 'https://timetreeapis.com'
      # @return [Integer]
      attr_reader :installation_id
      # @return [String]
      attr_reader :application_id
      # @return [String]
      attr_reader :private_key
      # @return [String]
      attr_reader :token
      # @return [Integer]
      attr_reader :ratelimit_limit
      # @return [Integer]
      attr_reader :ratelimit_remaining
      # @return [Time]
      attr_reader :ratelimit_reset_at

      # @param installation_id [Integer] CalendarApp's installation id
      # @param application_id [String] CalendarApp id

      def initialize(installation_id, application_id = nil , private_key = nil)
        @installation_id = installation_id
        @application_id = application_id || TimeTree.configuration.application_id
        @private_key = OpenSSL::PKey::RSA.new(private_key || TimeTree.configuration.private_key)
        @http_cmd = HttpCommand.new(API_HOST, self)
      end

      def calendar(include_relationships: nil)
        check_access_token
        rels = Array(include_relationships).map(&:to_sym)
        params = {include: (rels & Calendar::RELATIONSHIPS).join(',')}
        res = http_cmd.get('/calendar', params)
        raise ApiError.new(res) if res.status != 200

        to_model(res.body[:data], included: res.body[:included])
      end

      def calendar_members
        check_access_token
        res = http_cmd.get('/calendar/members')
        raise ApiError.new(res) if res.status != 200

        res.body[:data].map { |item| to_model(item) }
      end

      def event(event_id, include_relationships: nil)
        check_access_token
        rels = Array(include_relationships).map(&:to_sym)
        params = {include: (rels & Event::RELATIONSHIPS).join(',')}
        res = http_cmd.get("/calendar/events/#{event_id}", params)
        raise ApiError.new(res) if res.status != 200

        to_model(res.body[:data], included: res.body[:included])
      end

      def upcoming_events(days: 7, timezone: 'UTC', include_relationships: nil)
        check_access_token
        rels = Array(include_relationships).map(&:to_sym)
        params = {
          days: days,
          timezone: timezone,
          include: (rels & Event::RELATIONSHIPS).join(',')
        }
        res = http_cmd.get('/calendar/upcoming_events', params)
        raise ApiError.new(res) if res.status != 200

        included = res.body[:included]
        res.body[:data].map { |item| to_model(item, included: included) }
      end

      def create_event(params)
        check_access_token
        res = http_cmd.post('/calendar/events', params)
        raise ApiError.new(res) if res.status != 201

        to_model(res.body[:data])
      end

      def update_event(event_id, params)
        check_access_token
        res = http_cmd.put("/calendar/events/#{event_id}", params)
        raise ApiError.new(res) if res.status != 200

        to_model(res.body[:data])
      end

      def delete_event(event_id)
        check_access_token
        res = http_cmd.delete("/calendar/events/#{event_id}")
        raise ApiError.new(res) if res.status != 204

        true
      end

      def create_activity(event_id, params)
        check_access_token
        res = http_cmd.post("/calendar/events/#{event_id}/activities", params)
        raise ApiError.new(res) if res.status != 201

        to_model(res.body[:data])
      end

      def update_ratelimit(res)
        limit = res.headers['x-ratelimit-limit']
        remaining = res.headers['x-ratelimit-remaining']
        reset = res.headers['x-ratelimit-reset']
        @ratelimit_limit = limit.to_i if limit
        @ratelimit_remaining = remaining.to_i if remaining
        @ratelimit_reset_at = Time.at reset.to_i if reset
      end

    private

      attr_reader :http_cmd, :access_token

      def to_model(data, included: nil)
        TimeTree::BaseModel.to_model data, client: self, included: included
      end

      def check_access_token
        return if access_token?
        get_access_token
      end

      def access_token?
        access_token && !access_token.expired?
      end

      def get_access_token
        res = http_cmd.post("/installations/#{installation_id}/access_tokens") do |req|
          req.headers['Authorization'] = "Bearer #{jwt}"
        end
        raise ApiError.new(res) if res.status != 200

        @access_token = AccessToken.new(res.body[:access_token], res.body[:expire_at])
        @token = access_token.token
      end

      def jwt
        now = Time.now.to_i
        payload = {
          iat: now,
          exp: now + (10 * 60), # JWT expires in 10 minutes
          iss: application_id
        }
        JWT.encode(payload, private_key, 'RS256')
      end
    end
  end
end
