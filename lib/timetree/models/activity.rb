# frozen_string_literal: true

require 'timetree/models/base_model'

module TimeTree
  # Model for TimeTree comment.
  class Activity < BaseModel
    # @return [String]
    attr_accessor :content
    # @return [Time]
    attr_accessor :updated_at
    # @return [Time]
    attr_accessor :created_at
    # calendar's id.
    # @return [String]
    attr_accessor :calendar_id
    # event's id.
    # @return [String]
    attr_accessor :event_id

    TIME_FIELDS = %i[updated_at created_at].freeze

    #
    # Creates a comment to the associated event.
    #
    # @return [TimeTree::Activity]
    # @raise [TimeTree::Error] if @client is not set.
    # @raise [TimeTree::Error] if the calendar_id property is not set.
    # @raise [TimeTree::Error] if the event_id property is not set.
    # @raise [TimeTree::ApiError] if the http response status will not success.
    # @since 0.0.1
    def create
      check_client
      _create
    end

    #
    # convert to a TimeTree request body format.
    #
    # @return [Hash]
    # @since 0.0.1
    def data_params
      {
        data: {attributes: {content: content}}
      }
    end

  private

    def _create
      if @cilent.is_a?(CalendarApp::Client)
        @client.create_activity(event_id, data_params)
      else
        @client.create_activity(calendar_id, event_id, data_params)
      end
    end
  end
end
