# frozen_string_literal: true

module LoopClient
  class TokenFetcher
    include Logger

    attr_reader :audience, :client_id, :client_secret, :auth_url

    def initialize(auth_url:, audience:, client_id:, client_secret:)
      @auth_url = auth_url
      @audience = audience
      @client_id = client_id
      @client_secret = client_secret
    end

    def token
      return access_token if valid?

      self.access_token = TokenCache.fetch(cache_key) { fetch }
    end

    def fetch
      uri = URI("#{auth_url}oauth/token")

      connection = Faraday.new(
        url: uri,
        headers: { 'content-type' => 'application/json' }
      ) do |f|
        f.response :json, parser_options: { object_class: OpenStruct }
      end

      response = connection.post(uri, request_body)
      Token.new(response.body.access_token)
    end

    private

    attr_accessor :access_token

    def valid?
      !access_token.nil? && Time.at(access_token.expiration) > Time.now
    end

    def request_body
      {
        client_id: client_id,
        client_secret: client_secret,
        audience: audience,
        grant_type: 'client_credentials'
      }.to_json
    end

    def cache_key
      "#{self.class.name}:#{auth_url}:#{client_id}:#{audience}"
    end
  end
end
