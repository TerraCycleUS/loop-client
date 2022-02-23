# frozen_string_literal: true

module LoopClient
  class Api
    attr_reader :token_fetcher

    def initialize(api:)
      raise Error, "Unknown api with name '#{api}'" if LoopClient.configuration.apis[api].blank?

      @api = api
      @path_parts = []

      @token_fetcher = TokenFetcher.new \
        auth_url: LoopClient.configuration.auth_url,
        client_id: LoopClient.configuration.client_id,
        client_secret: LoopClient.configuration.client_secret,
        audience: LoopClient.configuration.apis[api][:audience]
    end

    def method_missing(method, *args)
      path_parts << method.to_s.downcase
      path_parts << args if args.length.positive?
      path_parts.flatten!
      self
    end

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end

    def get(params: nil)
      request(method: :get, params: params)
    end

    def post(params: nil, body: nil)
      request(method: :post, params: params, body: body)
    end

    def put(params: nil, body: nil)
      request(method: :put, params: params, body: body)
    end

    def patch(params: nil, body: nil)
      request(method: :patch, params: params, body: body)
    end

    def delete(params: nil)
      request(method: :delete, params: params, body: body)
    end

    private

    attr_reader :api, :path_parts

    def reset
      @path_parts = []
    end

    def path
      path_parts.join('/')
    end

    def request(method:, params: nil, body: nil)
      api_request = ApiRequest.new \
        token_fetcher: token_fetcher,
        url: LoopClient.configuration.apis[api][:url],
        path: path,
        params: params,
        body: body

      api_request.call(method: method)
    ensure
      reset
    end
  end
end
