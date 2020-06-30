# frozen_string_literal: true

require 'time'

module TimeTree
  # TimeTree base model object.
  class BaseModel
    # @return [Array<Hash<String,String>>]
    attr_accessor :relationships
    # @return [String]
    attr_reader :id
    # @return [String]
    attr_reader :type

    # @param data [Hash]
    # TimeTree apis's response data.
    # @param included [Hash]
    # @param client [TimeTree::Client]
    # @return [TimeTree::User, TimeTree::Label, TimeTree::Calendar, TimeTree::Event, TimeTree::Activity]
    # A TimeTree model object that be based on the type.
    # @raise [TimeTree::Error] if the type property is not set or unknown.
    # @since 0.0.1
    def self.to_model(data, included: nil, client: nil)
      id = data[:id]
      type = data[:type]
      raise Error, 'type is required.' if type.nil?

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
      when 'calendar'
        Calendar.new(**params)
      when 'event'
        Event.new(**params)
      when 'activity'
        Activity.new(**params)
      else
        raise Error, "type '#{type}' is unknown."
      end
    end

    def initialize(type:, id: nil, client: nil, attributes: nil, relationships: nil, included: nil)
      @type = type
      @id = id
      @client = client
      set_attributes attributes
      set_relationships relationships, included
    end

    def inspect
      "\#<#{self.class}:#{object_id} id:#{id}>"
    end

    private

    def check_client
      raise Error, '@client is nil.' if @client.nil?
    end

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
end
