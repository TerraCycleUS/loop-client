# frozen_string_literal: true

module LoopClient
  class Configuration
    attr_reader :apis
    attr_writer :logger
    attr_accessor :auth_url, :client_id, :client_secret, :redis

    def initialize
      @apis = {}
    end

    def add_api(key, url:, audience:)
      raise Error, "Url can't be blank" if url.blank?
      raise Error, "audience can't be blank" if audience.blank?

      apis[key.to_sym] = { url: url, audience: audience }
    end

    def logger
      @logger ||= Logger.new($stdout)
    end
  end
end
