# frozen_string_literal: true

require 'time'

module TimeTree
  class BaseModel
    attr_reader :id
    attr_reader :type
    attr_accessor :relationships

    # @param data [Hash]
    # @param client [TimeTree::Client]
    # @return [TimeTree::BaseModel]
    def self.to_model(data, included: nil, client: nil)
      id = data[:id]
      type = data[:type]
      return if type.nil?

      attributes = data[:attributes] || {}
      relationships = data[:relationships] || {}
      params = {
        id: id,
        type: type,
        client: client,
        attributes: attributes,
        relationships: relationships,
        included: included
      }

      case type
      when 'user'
        User.new(**params)
      when 'label'
        Label.new(**params)
      when 'event'
        Event.new(**params)
      when 'calendar'
        Calendar.new(**params)
      when 'activity'
        Activity.new(**params)
      end
    end

    def initialize(id:, type:, client: nil, attributes: nil, relationships: nil, included: nil)
      @id = id
      @type = type
      @client = client
      set_attributes attributes
      set_relationships relationships, included
    end

    def inspect
      "\#<#{self.class}:#{object_id} id:#{id}>"
    end

    private

    def to_model(data)
      self.class.to_model data, client: @client
    end

    def set_attributes(attributes)
      return unless attributes.is_a? Hash
      return if attributes.empty?

      setter_methods = self.class.instance_methods.select { |method| method.to_s.end_with? '=' }
      attributes.each do |key, value|
        setter = "#{key.to_sym}=".to_sym
        next unless setter_methods.include? setter

        if defined?(self.class::TIME_FIELDS) && self.class::TIME_FIELDS.include?(key)
          value = Time.parse value
        end
        instance_variable_set "@#{key}", value
      end
    end

    def set_relationships(relationships, included)
      return unless relationships.is_a? Hash
      return if relationships.empty?
      return unless defined? self.class::RELATIONSHIPS
      return if self.class::RELATIONSHIPS.empty?

      self.class::RELATIONSHIPS.each do |key|
        relation = relationships[key]
        next unless relation
        next unless relation[:data]

        @relationships ||= {}
        @relationships[key] = relation[:data]
      end

      return if included.nil?
      return unless included.is_a? Array
      return if included.empty?

      set_relationship_data_if_included(included)
    end

    def set_relationship_data_if_included(included)
      @_relation_data_dic = {}
      included.each do |data|
        item = to_model(data)
        next unless item

        @_relation_data_dic[item.type] ||= {}
        @_relation_data_dic[item.type][item.id] = item
      end
      detect_relation_data = lambda { |type, id|
        return unless @_relation_data_dic[type]

        @_relation_data_dic[type][id]
      }
      @relationships.each do |key, id_data|
        relation_data = nil
        if id_data.is_a? Array
          relation_data = []
          id_data.each do |d|
            item = detect_relation_data.call(d[:type], d[:id])
            relation_data << item if item
          end
        elsif id_data.is_a? Hash
          relation_data = detect_relation_data.call(id_data[:type], id_data[:id])
        end
        instance_variable_set "@#{key}", relation_data if relation_data
      end
    end
  end

  class User < BaseModel
    attr_accessor :name
    attr_accessor :description
    attr_accessor :image_url
  end

  class Label < BaseModel
    attr_accessor :name
    attr_accessor :color
  end

  class Calendar < BaseModel
    attr_accessor :name
    attr_accessor :description
    attr_accessor :color
    attr_accessor :order
    attr_accessor :image_url
    attr_accessor :created_at

    TIME_FIELDS = %i[created_at].freeze
    RELATIONSHIPS = %i[labels members].freeze

    def event(event_id)
      return if @client.nil?

      @client.event id, event_id
    end

    def upcoming_events(days: 7, timezone: 'UTC')
      return if @client.nil?

      @client.upcoming_events id, days: days, timezone: timezone
    end

    def labels
      return @labels if defined? @labels
      return if @client.nil?

      @labels = @client.calendar_labels id
    end

    def members
      return @members if defined? @members
      return if @client.nil?

      @members = @client.calendar_members id
    end
  end

  class Event < BaseModel
    attr_accessor :category
    attr_accessor :title
    attr_accessor :all_day
    attr_accessor :start_at
    attr_accessor :start_timezone
    attr_accessor :end_at
    attr_accessor :end_timezone
    attr_accessor :recurrences
    attr_accessor :recurring_uuid
    attr_accessor :description
    attr_accessor :location
    attr_accessor :url
    attr_accessor :updated_at
    attr_accessor :created_at
    attr_accessor :calendar_id

    attr_reader :creator
    attr_reader :label
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
        data: { attributes: attributes_params, relationships: relationhips_params }
      }
    end
  end

  class Activity < BaseModel
    attr_accessor :content
    attr_accessor :updated_at
    attr_accessor :created_at
    attr_accessor :calendar_id
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
