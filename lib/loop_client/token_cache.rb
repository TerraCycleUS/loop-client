# frozen_string_literal: true

module LoopClient
  class TokenCache
    extend Logger

    def self.fetch(key)
      redis = LoopClient.configuration.redis

      ttl = redis.ttl(key)

      # logger.debug("#{self.name}: ttl by key '#{key}': #{ttl}")

      # buffer time 1.minutes
      if ttl >= 60
        access_token = redis.get(key)
        token = Token.new(access_token)

        return token if token.alive?
      end

      yield.tap do |x|
        redis.set(key, x, exat: x.expiration)
      end
    end
  end
end
