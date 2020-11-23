# frozen_string_literal: true

require 'openssl'
require 'jwt'

module TimeTree
  module CalendarApp
    # TimeTree API CalendarApp client.
    class Client < BaseClient
      # @return [Integer]
      attr_reader :installation_id
      # @return [String]
      attr_reader :application_id
      # @return [String]
      attr_reader :private_key
      # @return [String]
      attr_reader :token

      # @param installation_id [Integer] CalendarApp's installation id
      # @param application_id [String] CalendarApp id
      # @param private_key [String] RSA private key for CalendarApp
      def initialize(installation_id, application_id = nil, private_key = nil)
        @installation_id = installation_id
        @application_id = application_id || TimeTree.configuration.calendar_app_application_id
        @private_key = OpenSSL::PKey::RSA.new((private_key || TimeTree.configuration.calendar_app_private_key).to_s)
        check_client_requirement
        @http_cmd = HttpCommand.new(API_HOST, self)
      rescue OpenSSL::PKey::RSAError
        raise Error.new 'private_key must be RSA private key.'
      end

      #
      # Get a calendar information related to CalendarApp
      #
      # @param include_relationships [Array<symbol>]
      # includes association's object in the response.
      # @return [TimeTree::Calendar]
      # @raise [TimeTree::ApiError] if the http response status will not success.
      # @since 1.0.0
      def calendar(include_relationships: nil)
        check_access_token
        params = relationships_params(include_relationships, Calendar::RELATIONSHIPS)
        res = http_cmd.get('/calendar', params)
        raise ApiError.new(res) if res.status != 200

        to_model(res.body[:data], included: res.body[:included])
      end

      #
      # Get a calendar's member information.
      #
      # @return [Array<TimeTree::User>]
      # @raise [TimeTree::ApiError] if the http response status will not success.
      # @since 1.0.0
      def calendar_members
        check_access_token
        res = http_cmd.get('/calendar/members')
        raise ApiError.new(res) if res.status != 200

        res.body[:data].map { |item| to_model(item) }
      end

      #
      # Get an event's information.
      #
      # @param event_id [String] event's id.
      # @param include_relationships [Array<symbol>]
      # includes association's object in the response.
      # @return [TimeTree::Event]
      # @raise [TimeTree::Error] if the event_id arg is empty.
      # @raise [TimeTree::ApiError] if the http response status will not success.
      # @since 1.0.0
      def event(event_id, include_relationships: nil)
        check_event_id event_id
        check_access_token
        params = relationships_params(include_relationships, Event::RELATIONSHIPS)
        res = http_cmd.get("/calendar/events/#{event_id}", params)
        raise ApiError.new(res) if res.status != 200

        to_model(res.body[:data], included: res.body[:included])
      end

      #
      # Get events' information after a request date.
      #
      # @param days [Integer] The number of days to get.
      # @param timezone [String] Timezone.
      # @param include_relationships [Array<symbol>]
      # includes association's object in the response.
      # @return [Array<TimeTree::Event>]
      # @raise [TimeTree::ApiError] if the http response status will not success.
      # @since 1.0.0
      def upcoming_events(days: 7, timezone: 'UTC', include_relationships: nil)
        check_access_token
        params = relationships_params(include_relationships, Event::RELATIONSHIPS)
        params.merge!(days: days, timezone: timezone)
        res = http_cmd.get('/calendar/upcoming_events', params)
        raise ApiError.new(res) if res.status != 200

        included = res.body[:included]
        res.body[:data].map { |item| to_model(item, included: included) }
      end

      #
      # Creates an event.
      #
      # @param params [Hash] TimeTree request body format.
      # @return [TimeTree::Event]
      # @raise [TimeTree::Error] if the cal_id arg is empty.
      # @raise [TimeTree::ApiError] if the http response status will not success.
      # @since 1.0.0
      def create_event(params)
        check_access_token
        res = http_cmd.post('/calendar/events', params)
        raise ApiError.new(res) if res.status != 201

        to_model(res.body[:data])
      end

      #
      # Updates an event.
      #
      # @param event_id [String] event's id.
      # @param params [Hash]
      # event's information specified in TimeTree request body format.
      # @return [TimeTree::Event]
      # @raise [TimeTree::Error] if the event_id arg is empty.
      # @raise [TimeTree::ApiError] if the http response status will not success.
      # @since 1.0.0
      def update_event(event_id, params)
        check_event_id event_id
        check_access_token
        res = http_cmd.put("/calendar/events/#{event_id}", params)
        raise ApiError.new(res) if res.status != 200

        to_model(res.body[:data])
      end

      #
      # Deletes an event.
      #
      # @param event_id [String] event's id.
      # @return [true] if the operation succeeded.
      # @raise [TimeTree::Error] if the event_id arg is empty.
      # @raise [TimeTree::ApiError] if the http response status will not success.
      # @since 1.0.0
      def delete_event(event_id)
        check_event_id event_id
        check_access_token
        res = http_cmd.delete("/calendar/events/#{event_id}")
        raise ApiError.new(res) if res.status != 204

        true
      end

      #
      # Creates a comment.
      #
      # @param event_id [String] event's id.
      # @param params [Hash]
      # comment's information specified in TimeTree request body format.
      # @return [TimeTree::Activity]
      # @raise [TimeTree::Error] if the event_id arg is empty.
      # @raise [TimeTree::ApiError] if the http response status is not success.
      # @since 1.0.0
      def create_activity(event_id, params)
        check_event_id event_id
        check_access_token
        res = http_cmd.post("/calendar/events/#{event_id}/activities", params)
        raise ApiError.new(res) if res.status != 201

        activity = to_model(res.body[:data])
        activity.event_id = event_id
        activity
      end

      def inspect
        limit_info = nil
        if defined?(@ratelimit_limit) && @ratelimit_limit
          limit_info = " ratelimit:#{ratelimit_remaining}/#{ratelimit_limit}"
        end
        if defined?(@ratelimit_reset_at) && @ratelimit_reset_at
          limit_info = "#{limit_info}, reset_at:#{ratelimit_reset_at.strftime('%m/%d %R')}"
        end
        "\#<#{self.class}:#{object_id}#{limit_info}>"
      end

    private

      attr_reader :http_cmd, :access_token

      def check_client_requirement
        check_required_property(installation_id, 'installation_id')
        check_required_property(application_id, 'application_id')
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
