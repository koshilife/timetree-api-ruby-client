# frozen_string_literal: true

require 'logger'

module TimeTree
  # TimeTree apis client configuration.
  class Configuration
    # @return [String]
    attr_accessor :token
    # @return [Logger]
    attr_accessor :logger

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = :warn
    end
  end
end
