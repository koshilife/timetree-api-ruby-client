# frozen_string_literal: true

module TimeTree
  # TimeTree apis client error object.
  class ApiError < StandardError
    # @return [Faraday::Response]
    attr_reader :response
    # @return [String]
    attr_reader :type
    # @return [String]
    attr_reader :title
    # @return [String]
    attr_reader :errors
    # @return [Integer]
    attr_reader :status

    def initialize(response)
      @response = response
      @type = response.body[:type]
      @title = response.body[:title]
      @errors = response.body[:errors]
      @status = response.status
    end

    def inspect
      "\#<#{self.class}:#{object_id} title:#{title}, status:#{status}>"
    end
  end
end
