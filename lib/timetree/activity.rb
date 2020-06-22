# frozen_string_literal: true

module TimeTree
  # Model for TimeTree comment.
  class Activity < BaseModel
    # @return [String]
    attr_accessor :content
    # @return [Time]
    attr_accessor :updated_at
    # @return [Time]
    attr_accessor :created_at
    # @return [TimeTree::Calendar#id]
    attr_accessor :calendar_id
    # @return [TimeTree::Event#id]
    attr_accessor :event_id

    TIME_FIELDS = %i[updated_at created_at].freeze

    def create
      return if @client.nil?

      @client.create_activity calendar_id, event_id, data_params
    end

    def data_params
      {
        data: { attributes: { content: content } }
      }
    end
  end
end
