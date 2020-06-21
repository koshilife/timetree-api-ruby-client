# frozen_string_literal: true

Dir[
  File.join(
    File.dirname(__FILE__),
    'timetree',
    '*'
  )
].sort.each do |f|
  require f
end

module TimeTree
  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end

  class Error < StandardError
  end
end
