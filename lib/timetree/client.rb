# frozen_string_literal: true

require 'time'
require 'faraday'
require 'faraday_middleware'

module TimeTree
  class Client
    API_HOST = 'https://timetreeapis.com'

    attr_reader :ratelimit_limit
    attr_reader :ratelimit_remaining
    attr_reader :ratelimit_reset_at

    def initialize(access_token = nil)
      config = TimeTree.configuration
      @access_token = access_token || config.access_token
      @logger = config.logger
    end

    def inspect
      limit_info = nil
      if @ratelimit_limit
        limit_info = " ratelimit:#{@ratelimit_remaining}/#{@ratelimit_limit}"
      end
      if @ratelimit_reset_at
        limit_info = "#{limit_info}, reset_at:#{@ratelimit_reset_at.strftime('%m/%d %R')}"
      end
      "\#<#{self.class}:#{object_id}#{limit_info}>"
    end

    #
    # User
    #

    def user
      res = get '/user'
      raise if res.status != 200

      to_model res.body[:data]
    end

    #
    # Calendar
    #

    def calendar(cal_id, include_relationships: nil)
      params = relationships_params(include_relationships, Calendar::RELATIONSHIPS)
      res = get "/calendars/#{cal_id}", params
      raise if res.status != 200

      to_model(res.body[:data], included: res.body[:included])
    end

    def calendars(include_relationships: nil)
      params = relationships_params(include_relationships, Calendar::RELATIONSHIPS)
      res = get '/calendars', params
      raise if res.status != 200

      included = res.body[:included]
      res.body[:data].map { |item| to_model(item, included: included) }
    end

    def calendar_labels(cal_id)
      res = get "/calendars/#{cal_id}/labels"
      raise if res.status != 200

      res.body[:data].map { |item| to_model(item) }
    end

    def calendar_members(cal_id)
      res = get "/calendars/#{cal_id}/members"
      raise if res.status != 200

      res.body[:data].map { |item| to_model item }
    end

    #
    # Schedule/Keep
    #

    def event(cal_id, event_id, include_relationships: nil)
      params = relationships_params(include_relationships, Event::RELATIONSHIPS)
      res = get "/calendars/#{cal_id}/events/#{event_id}", params
      raise if res.status != 200

      ev = to_model(res.body[:data], included: res.body[:included])
      ev.calendar_id = cal_id
      ev
    end

    def upcoming_events(cal_id, days: 7, timezone: 'UTC', include_relationships: nil)
      params = relationships_params(include_relationships, Event::RELATIONSHIPS)
      params.merge!(days: days, timezone: timezone)
      res = get "/calendars/#{cal_id}/upcoming_events", params
      raise if res.status != 200

      included = res.body[:included]
      res.body[:data].map do |item|
        ev = to_model(item, included: included)
        ev.calendar_id = cal_id
        ev
      end
    end

    def create_event(cal_id, params)
      res = post "/calendars/#{cal_id}/events", params
      raise if res.status != 201

      ev = to_model res.body[:data]
      ev.calendar_id = cal_id
      ev
    end

    def update_event(cal_id, event_id, params)
      res = put "/calendars/#{cal_id}/events/#{event_id}", params
      raise if res.status != 200

      ev = to_model res.body[:data]
      ev.calendar_id = cal_id
      ev
    end

    def delete_event(cal_id, event_id)
      res = delete "/calendars/#{cal_id}/events/#{event_id}"
      raise if res.status != 204

      true
    end

    #
    # Activity
    #

    def create_activity(cal_id, event_id, params)
      res = post "/calendars/#{cal_id}/events/#{event_id}/activities", params
      raise if res.status != 201

      activity = to_model res.body[:data]
      activity.calendar_id = cal_id
      activity.event_id = event_id
      activity
    end

    private

    attr_reader :logger

    def to_model(data, included: nil)
      TimeTree::BaseModel.to_model data, client: self, included: included
    end

    def relationships_params(relationships, default)
      params = {}
      relationships ||= default
      params[:include] = relationships.join ',' if relationships.is_a? Array
      params
    end

    def update_ratelimit(res)
      limit = res.headers['x-ratelimit-limit']
      remaining = res.headers['x-ratelimit-remaining']
      reset = res.headers['x-ratelimit-reset']
      @ratelimit_limit = limit.to_i if limit
      @ratelimit_remaining = remaining.to_i if remaining
      @ratelimit_reset_at = Time.at reset.to_i if reset
    end

    def get(path, params = {})
      logger.info "GET #{connection.build_url("#{API_HOST}#{path}", params)}"
      res = connection.get path, params
      update_ratelimit(res)
      logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    def put(path, params = {})
      logger.debug "PUT #{API_HOST}#{path} body:#{params}"
      res = connection.put path do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end
      update_ratelimit(res)
      logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    def post(path, params = {})
      @logger.debug "POST #{API_HOST}#{path} body:#{params}"
      res = connection.post path, params do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end
      update_ratelimit(res)
      logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    def delete(path, params = {})
      @logger.debug "DELETE #{API_HOST}#{path} params:#{params}"
      res = connection.delete path, params
      update_ratelimit(res)
      logger.debug "Response status:#{res.status}, body:#{res.body}"
      res
    end

    def connection
      Faraday.new(
        url: API_HOST,
        headers: {
          'Accept' => 'application/vnd.timetree.v1+json',
          'Authorization' => "Bearer #{@access_token}"
        }
      ) do |builder|
        builder.response :json, parser_options: { symbolize_names: true }, content_type: /\bjson$/
      end
    end
  end
end
