# frozen_string_literal: true

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'timetree' => 'TimeTree'
)
loader.collapse('**/models')
loader.setup

# module for TimeTree apis client
module TimeTree
  class Error < StandardError
  end
  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end
