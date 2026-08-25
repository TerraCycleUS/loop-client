# frozen_string_literal: true

%w[
  jwt
  logger
  faraday
  ostruct
  zeitwerk
  addressable
  concurrent
  active_support
  active_support/core_ext/object/blank
  active_support/core_ext/object/try
].each(&method(:require))

module LoopClient
  @apis = Concurrent::Map.new

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def [](key)
      @apis.compute_if_absent(key) { Api.new(api: key) }
    end

    def reset!
      @configuration = Configuration.new
      @apis = Concurrent::Map.new
    end
  end
end

Zeitwerk::Loader
  .for_gem
  .tap(&:setup)
  .tap(&:eager_load)
