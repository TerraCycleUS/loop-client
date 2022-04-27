# frozen_string_literal: true

module Helpers
  class FakeRedis
    def set(key, value, _options = {})
      @container[key] = value
    end

    def get(key)
      @container[key]
    end

    def ttl(_key)
      10
    end

    def flushall
      @container = {}
    end

    private

    def container
      @container ||= {}
    end
  end
end
