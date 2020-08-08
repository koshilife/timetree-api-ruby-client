# frozen_string_literal: true

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
      @client.event id, event_id
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
      @client.upcoming_events id, days: days, timezone: timezone
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
      @members = @client.calendar_members id
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
      @labels = @client.calendar_labels id
    end
  end
end
