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
    # @return [String]
    attr_accessor :recurrences
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
    # @return [TimeTree::Calendar#id]
    attr_accessor :calendar_id

    # @return [TimeTree::User]
    attr_reader :creator
    # @return [TimeTree::Label]
    attr_reader :label
    # @return [Array<TimeTree::User>]
    attr_reader :attendees

    TIME_FIELDS = %i[start_at end_at updated_at created_at].freeze
    RELATIONSHIPS = %i[creator label attendees].freeze

    def create
      return if @client.nil?

      @client.create_event calendar_id, data_params
    end

    def create_comment(message)
      return if @client.nil?

      params = { type: 'activity', attributes: { calendar_id: calendar_id, event_id: id, content: message } }
      activity = to_model params
      return if activity.nil?

      activity.create
    end

    def update
      return if @client.nil?
      return if id.nil?

      @client.update_event calendar_id, id, data_params
    end

    def delete
      return if @client.nil?
      return if id.nil?

      @client.delete_event calendar_id, id
    end

    def data_params
      attributes_params = {
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
      }
      relationhips_params = {}
      if @relationships[:label]
        label_data = { id: @relationships[:label], type: 'label' }
        relationhips_params[:label] = { data: label_data }
      end
      if @relationships[:attendees]
        attendees_data = @relationships[:attendees].map { |_id| { id: _id, type: 'user' } }
        relationhips_params[:attendees] = { data: attendees_data }
      end
      {
        data: {
          attributes: attributes_params,
          relationships: relationhips_params
        }
      }
    end
  end
end
