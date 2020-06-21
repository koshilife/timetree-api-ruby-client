# frozen_string_literal: true

require 'logger'

module TimeTree
  class Configuration
    attr_accessor :access_token
    attr_accessor :logger
    def initialize
      logger = Logger.new(STDOUT)
      logger.level = :warn
      @logger = logger
    end
  end
end
