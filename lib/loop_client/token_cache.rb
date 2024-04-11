# frozen_string_literal: true

module LoopClient
  class TokenCache
    extend Logger

    def self.fetch(key)
      cache_store = LoopClient.configuration.cache_store

      access_token = cache_store.read(key)

      unless access_token.blank?
        token = Token.new(access_token)
        return token if token.alive?
      end

      yield.tap do |x|
        cache_store.write(key, x, expires_at: Time.at(x.expiration))
      end
    end
  end
end
