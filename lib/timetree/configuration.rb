# frozen_string_literal: true

require 'logger'

module TimeTree
  # TimeTree apis client configuration.
  class Configuration
    # @return [String]
    attr_accessor :token
    # @return [String]
    attr_accessor :application_id
    # @return [String]
    attr_accessor :private_key
    # @return [Logger]
    attr_accessor :logger

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = :warn
    end
  end
end
