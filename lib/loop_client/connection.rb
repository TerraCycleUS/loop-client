# frozen_string_literal: true

module LoopClient
  class Connection
    def self.build(url:, headers:)
      config = LoopClient.configuration

      Faraday.new(
        url: url,
        headers: headers,
        request: { timeout: config.timeout, open_timeout: config.open_timeout }
      ) do |f|
        f.request :json
        f.response :json, parser_options: { object_class: OpenStruct }
      end
    end
  end
end
