# frozen_string_literal: true

module LoopClient
  class Configuration
    DEFAULT_TIMEOUT = 30
    DEFAULT_OPEN_TIMEOUT = 5

    attr_reader :apis
    attr_writer :logger
    attr_accessor :auth_url, :client_id, :client_secret, :cache_store, :timeout, :open_timeout

    def initialize
      @apis = {}
      @timeout = DEFAULT_TIMEOUT
      @open_timeout = DEFAULT_OPEN_TIMEOUT
    end

    def add_api(key, url:, audience:)
      raise Error, "url can't be blank" if url.blank?
      raise Error, "audience can't be blank" if audience.blank?

      apis[key.to_sym] = { url: url, audience: audience }
    end

    def logger
      @logger ||= ::Logger.new($stdout)
    end
  end
end
