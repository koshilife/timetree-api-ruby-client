# frozen_string_literal: true

require 'logger'

module TimeTree
  # TimeTree apis client configuration.
  class Configuration
    # @return [String] OAuthApp's access token
    attr_accessor :oauth_app_token

    # @return [String] CalendarApp's app id
    attr_accessor :calendar_app_application_id
    # @return [String] CalendarApp's private key content#
    # e.g. File.read('<YOUR_PATH_TO_PEM_FILE>')
    attr_accessor :calendar_app_private_key

    # @return [Logger]
    attr_accessor :logger

    def initialize
      @logger = Logger.new $stdout
      @logger.level = :warn
    end
  end
end
