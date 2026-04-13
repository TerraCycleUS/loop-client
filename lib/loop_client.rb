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
].each(&method(:require))

module LoopClient
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def [](key)
      @apis ||= {}
      @apis[key] ||= Api.new(api: key)
    end
  end
end

Zeitwerk::Loader
  .for_gem
  .tap(&:setup)
  .tap(&:eager_load)
