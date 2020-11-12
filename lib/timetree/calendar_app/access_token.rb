# frozen_string_literal: true

module TimeTree
  module CalendarApp
    class AccessToken
      # @return [String]
      attr_reader :token
      # @return [Integer]
      attr_reader :expire_at

      def initialize(token, expire_at)
        @token = token
        @expire_at = expire_at
      end

      def expired?
        Time.now.to_i > expire_at
      end
    end
  end
end
