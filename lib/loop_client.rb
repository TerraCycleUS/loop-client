# frozen_string_literal: true

%w[
  jwt
  redis
  logger
  faraday
  zeitwerk
  addressable
].each(&method(:require))

class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end
end

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
