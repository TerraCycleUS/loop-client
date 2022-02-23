# frozen_string_literal: true

module LoopClient
  module Logger
    def logger
      LoopClient.configuration.logger
    end
  end
end
