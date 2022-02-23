# frozen_string_literal: true

module LoopClient
  class ApiRequest
    attr_reader :url, :path, :params, :body, :token_fetcher

    def initialize(token_fetcher:, url:, path:, params: nil, body: nil)
      @url = url
      @path = Addressable::URI.escape(path)
      @params = params
      @body = body
      @token_fetcher = token_fetcher
    end

    def call(method:)
      raise Error, "unknown method '#{method}'" unless ALLOCATE_METHODS.include?(method)

      send(method)
    end

    private

    ALLOCATE_METHODS = [:get, :post, :put, :patch, :delete].freeze

    def get
      connection.get(path, params)
    end

    def post
      connection.post(path, body)
    end

    def put
      connection.put(path, body)
    end

    def patch
      connection.patch(path, body)
    end

    def delete
      connection.delete(path, params)
    end

    def connection
      @connection ||= Faraday.new(url: url, headers: headers) do |f|
        f.response :json, parser_options: { object_class: OpenStruct }
      end
    end

    def headers
      {
        'content-type' => 'application/json',
        'Authorization' => "Bearer #{token_fetcher.token}"
      }
    end
  end
end
