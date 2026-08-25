# frozen_string_literal: true

module LoopClient
  class Api
    include Logger

    attr_reader :token_fetcher

    def initialize(api:)
      config = LoopClient.configuration
      raise Error, "Unknown api with name '#{api}'" if config.apis[api].blank?

      @api = api
      @url = config.apis[api][:url]
      @path_parts = Concurrent::ThreadLocalVar.new { [] }

      @token_fetcher = TokenFetcher.new \
        auth_url: config.auth_url,
        client_id: config.client_id,
        client_secret: config.client_secret,
        audience: config.apis[api][:audience]
    end

    def method_missing(method, *args)
      path_parts.value << method.to_s.downcase
      path_parts.value << args if args.any?
      path_parts.value.flatten!
      self
    end

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end

    def get(params: nil)
      request(method: :get, params: params)
    end

    def post(body: nil)
      request(method: :post, body: body)
    end

    def put(body: nil)
      request(method: :put, body: body)
    end

    def patch(body: nil)
      request(method: :patch, body: body)
    end

    def delete(params: nil)
      request(method: :delete, params: params)
    end

    private

    attr_reader :api, :url, :path_parts

    def reset
      path_parts.value = []
    end

    def build_path_and_reset
      path = path_parts.value.join('/')
      reset
      path
    end

    def request(method:, params: nil, body: nil)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      path = build_path_and_reset

      api_request = ApiRequest.new \
        token_fetcher: token_fetcher,
        url: url,
        path: path,
        params: params,
        body: body

      response = api_request.call(method: method)
      log_request(method: method, path: path, status: response.status, started_at: started_at)
      response
    rescue StandardError => e
      log_request(method: method, path: path, error: e.message, started_at: started_at)
      raise
    ensure
      reset
    end

    def log_request(method:, path:, started_at:, status: nil, error: nil)
      duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round(2)
      payload = { message: 'LoopClient Request', service: api, method: method.to_s.upcase,
                  path: path, duration_ms: duration }

      if error
        logger.error(payload.merge(error: error).to_json)
      else
        logger.info(payload.merge(status: status).to_json)
      end
    end
  end
end
