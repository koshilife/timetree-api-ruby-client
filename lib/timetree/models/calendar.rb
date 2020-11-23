# frozen_string_literal: true

require 'timetree/models/base_model'

module TimeTree
  # Model for TimeTree calendar.
  class Calendar < BaseModel
    # @return [String]
    attr_accessor :name
    # @return [String]
    attr_accessor :description
    # @return [String]
    attr_accessor :color
    # @return [Integer]
    attr_accessor :order
    # @return [String]
    attr_accessor :image_url
    # @return [Time]
    attr_accessor :created_at

    TIME_FIELDS = %i[created_at].freeze
    RELATIONSHIPS = %i[labels members].freeze

    #
    # Get the event's information.
    #
    # @param event_id [String]
    # event's id.
    # @return [TimeTree::Event]
    # @raise [TimeTree::Error] if @client, @id or the event_id arg is empty.
    # @raise [TimeTree::ApiError] if the http response status will not success.
    # @since 0.0.1
    def event(event_id)
      check_client
      get_event(event_id)
    end

    #
    # Get the events' information after a request date.
    #
    # @param days [Integer]
    # The number of days to get.
    # @param timezone [String]
    # Timezone.
    # @return [Array<TimeTree::Event>]
    # @raise [TimeTree::Error] if @client or @id is empty.
    # @raise [TimeTree::ApiError] if the http response status will not success.
    # @since 0.0.1
    def upcoming_events(days: 7, timezone: 'UTC')
      check_client
      get_upcoming_event(days, timezone)
    end

    #
    # Get a calendar's member information.
    #
    # @return [Array<TimeTree::User>]
    # @raise [TimeTree::Error] if @client or @id is empty.
    # @raise [TimeTree::ApiError] if the http response status will not success.
    # @since 0.0.1
    def members
      return @members if defined? @members

      check_client
      @members = get_members
    end

    #
    # Get a calendar's label information used in event.
    #
    # @return [Array<TimeTree::Label>]
    # @raise [TimeTree::Error] if @client or @id is empty.
    # @raise [TimeTree::ApiError] if the http response status will not success.
    # @since 0.0.1
    def labels
      return @labels if defined? @labels

      check_client
      @labels = get_labels
    end

  private

    def get_event(event_id)
      if @client.is_a?(CalendarApp::Client)
        @client.event(event_id)
      else
        @client.event(id, event_id)
      end
    end

    def get_upcoming_event(days, timezone)
      if @client.is_a?(CalendarApp::Client)
        @client.upcoming_events(days: days, timezone: timezone)
      else
        @client.upcoming_events(id, days: days, timezone: timezone)
      end
    end

    def get_members
      if @client.is_a?(CalendarApp::Client)
        @client.calendar_members
      else
        @client.calendar_members(id)
      end
    end

    def get_labels
      if @client.is_a?(CalendarApp::Client)
        raise Error.new 'CalendarApp does not support label api'
      else
        @client.calendar_labels(id)
      end
    end
  end
end
