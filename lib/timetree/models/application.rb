# frozen_string_literal: true

require 'timetree/models/base_model'

module TimeTree
  # Model for TimeTree application.
  class Application < BaseModel
    # @return [String]
    attr_accessor :name
    # @return [String]
    attr_accessor :description
    # @return [String]
    attr_accessor :image_url
  end
end
