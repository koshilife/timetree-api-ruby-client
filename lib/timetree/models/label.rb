# frozen_string_literal: true

require 'timetree/models/base_model'

module TimeTree
  # Model for TimeTree color theme.
  class Label < BaseModel
    # @return [String]
    attr_accessor :name
    # @return [String]
    attr_accessor :color
  end
end
