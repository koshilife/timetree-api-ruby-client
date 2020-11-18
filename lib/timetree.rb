# frozen_string_literal: true

Dir[
  File.join(
    File.dirname(__FILE__),
    'timetree',
    '**',
    '*'
  )
].sort.each do |f|
  next if File.directory? f

  require f
end

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
