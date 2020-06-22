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

    # @return [TimeTree::Event]
    def event(event_id)
      return if @client.nil?

      @client.event id, event_id
    end

    # @return [Array<TimeTree::Event>]
    def upcoming_events(days: 7, timezone: 'UTC')
      return if @client.nil?

      @client.upcoming_events id, days: days, timezone: timezone
    end

    # @return [Array<TimeTree::Label>]
    def labels
      return @labels if defined? @labels
      return if @client.nil?

      @labels = @client.calendar_labels id
    end

    # @return [Array<TimeTree::User>]
    def members
      return @members if defined? @members
      return if @client.nil?

      @members = @client.calendar_members id
    end
  end
end
