# frozen_string_literal: true

module TimeTree
  class BaseClient
    API_HOST = 'https://timetreeapis.com'
    # @return [Integer]
    attr_reader :ratelimit_limit
    # @return [Integer]
    attr_reader :ratelimit_remaining
    # @return [Time]
    attr_reader :ratelimit_reset_at

    #
    # update ratelimit properties
    #
    # @param res [Faraday::Response]
    # apis http response.
    def update_ratelimit(res)
      limit = res.headers['x-ratelimit-limit']
      remaining = res.headers['x-ratelimit-remaining']
      reset = res.headers['x-ratelimit-reset']
      @ratelimit_limit = limit.to_i if limit
      @ratelimit_remaining = remaining.to_i if remaining
      @ratelimit_reset_at = Time.at reset.to_i if reset
    end

    private

    def check_event_id(value)
      check_required_property(value, 'event_id')
    end

    def check_required_property(value, name)
      err = Error.new "#{name} is required."
      raise err if value.nil?
      raise err if value.to_s.empty?

      true
    end

    def to_model(data, included: nil)
      TimeTree::BaseModel.to_model data, client: self, included: included
    end

    def relationships_params(relationships, default)
      params = {}
      relationships ||= default
      params[:include] = relationships.join ',' if relationships.is_a? Array
      params
    end
  end
end
