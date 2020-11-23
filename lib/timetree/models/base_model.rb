# frozen_string_literal: true

require 'time'

module TimeTree
  # TimeTree base model object.
  class BaseModel # rubocop:disable Metrics/ClassLength
    # @return [Array<Hash<String,String>>]
    attr_accessor :relationships
    # @return [String]
    attr_reader :id
    # @return [String]
    attr_reader :type

    # @param data [Hash]
    # TimeTree apis's response data.
    # @param included [Hash]
    # @param client [TimeTree::OAuthApp::Client]
    # @return [TimeTree::User, TimeTree::Label, TimeTree::Calendar, TimeTree::Event, TimeTree::Activity, Hash]
    # A TimeTree model object that be based on the type.
    # @raise [TimeTree::Error] if the type property is not set.
    # @since 0.0.1
    def self.to_model(data, included: nil, client: nil) # rubocop:disable all
      id = data[:id]
      type = data[:type]
      raise Error.new('type is required.') if type.nil?

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
      when 'activity'
        Activity.new(**params)
      when 'application'
        Application.new(**params)
      when 'calendar'
        Calendar.new(**params)
      when 'event'
        Event.new(**params)
      when 'label'
        Label.new(**params)
      when 'user'
        User.new(**params)
      else
        TimeTree.configuration.logger.warn("type '#{type}' is unknown. id:#{id}")
        # when unexpected model type, return the 'data' argument.
        data
      end
    end

    def initialize(type:, id: nil, client: nil, attributes: nil, relationships: nil, included: nil) # rubocop:disable Metrics/ParameterLists
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
      raise Error.new('@client is nil.') if @client.nil?
    end

    def to_model(data)
      self.class.to_model data, client: @client
    end

    def set_attributes(attributes) # rubocop:disable Naming/AccessorMethodName
      return unless attributes.is_a? Hash
      return if attributes.empty?

      attributes.each do |key, value|
        next unless respond_to?("#{key}=".to_sym)

        value = Time.parse value if defined?(self.class::TIME_FIELDS) && self.class::TIME_FIELDS.include?(key)
        instance_variable_set "@#{key}", value
      end
    end

    def set_relationships(relationships, included) # rubocop:disable all
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

    def set_relationship_data_if_included(included) # rubocop:disable all
      @_relation_data_dic = {}
      included.each do |data|
        item = to_model(data)
        next unless item

        if item.is_a? Hash
          item_id = item[:id]
          item_type = item[:type]
        else
          item_id = item.id
          item_type = item.type
        end
        next unless item_id && item_type

        @_relation_data_dic[item_type] ||= {}
        @_relation_data_dic[item_type][item_id] = item
      end
      detect_relation_data = lambda { |type, id|
        return unless @_relation_data_dic[type]

        @_relation_data_dic[type][id]
      }
      relationships.each do |key, id_data|
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
