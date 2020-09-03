# frozen_string_literal: true

module TimeTree
  # Model for TimeTree event or keep.
  class Event < BaseModel
    # @return [Striing]
    attr_accessor :category
    # @return [Striing]
    attr_accessor :title
    # @return [Boolean]
    attr_accessor :all_day
    # @return [Time]
    attr_accessor :start_at
    # @return [Striing]
    attr_accessor :start_timezone
    # @return [Time]
    attr_accessor :end_at
    # @return [String]
    attr_accessor :end_timezone
    # @return [Array<String>]
    attr_accessor :recurrence
    # @return [String]
    attr_accessor :recurring_uuid
    # @return [String]
    attr_accessor :description
    # @return [String]
    attr_accessor :location
    # @return [String]
    attr_accessor :url
    # @return [Time]
    attr_accessor :updated_at
    # @return [Time]
    attr_accessor :created_at
    # calendar's id.
    # @return [String]
    attr_accessor :calendar_id

    # @return [TimeTree::User]
    attr_reader :creator
    # @return [TimeTree::Label]
    attr_accessor :label
    # @return [Array<TimeTree::User>]
    attr_accessor :attendees

    TIME_FIELDS = %i[start_at end_at updated_at created_at].freeze
    RELATIONSHIPS = %i[creator label attendees].freeze

    #
    # Creates an event to the associated calendar.
    #
    # @return [TimeTree::Event]
    # @raise [TimeTree::Error] if @client or @calendar_id is empty.
    # @raise [TimeTree::ApiError] if the http response status will not success.
    # @since 0.0.1
    def create
      check_client
      @client.create_event calendar_id, data_params
    end

    #
    # Updates the event.
    #
    # @return [TimeTree::Event]
    # @raise [TimeTree::Error] if @client, @calendar_id or @id is empty.
    # @raise [TimeTree::ApiError] if the http response status will not success.
    # @since 0.0.1
    def update
      check_client
      @client.update_event calendar_id, id, data_params
    end

    #
    # Deletes the event.
    #
    # @return [true] if the operation succeeded.
    # @raise [TimeTree::Error] if @client, @calendar_id or @id is empty.
    # @raise [TimeTree::ApiError] if the http response status will not success.
    # @since 0.0.1
    def delete
      check_client
      @client.delete_event calendar_id, id
    end

    #
    # Creates comment to the event.
    #
    # @return [TimeTree::Activity]
    # @raise [TimeTree::Error] if @client, @calendar_id or @id is empty.
    # @raise [TimeTree::ApiError] if the http response status will not success.
    # @since 0.0.1
    def create_comment(message)
      check_client
      params = {type: 'activity', attributes: {calendar_id: calendar_id, event_id: id, content: message}}
      activity = to_model params
      activity.create
    end

    #
    # convert to a TimeTree request body format.
    #
    # @return [Hash]
    # @since 0.0.1
    def data_params
      {
        data: {
          attributes: {
            category: category,
            title: title,
            all_day: all_day,
            start_at: start_at.iso8601,
            start_timezone: start_timezone,
            end_at: end_at.iso8601,
            end_timezone: end_timezone,
            description: description,
            location: location,
            url: url
          },
          relationships: relationships_params
        }
      }
    end

  private

    def relationships_params
      current_label = label ? {type: 'label', id: label.id} : relationships[:label]
      current_attendees = attendees ? attendees.map { |u| {type: 'user', id: u.id} } : relationships[:attendees]
      {
        label: {data: current_label},
        attendees: {data: current_attendees}
      }
    end
  end
end
