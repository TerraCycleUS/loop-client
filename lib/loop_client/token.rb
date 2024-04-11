# frozen_string_literal: true

module LoopClient
  class Token < String
    include Logger

    def payload
      @payload ||= JWT.decode(self, nil, false, algorithm: 'RS256')
    end

    def expiration
      @expiration ||= payload.first['exp']
    end

    def alive?
      Time.at(expiration - 60) > Time.now
    end
  end
end
