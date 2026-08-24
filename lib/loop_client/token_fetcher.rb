# frozen_string_literal: true

module LoopClient
  class TokenFetcher
    attr_reader :audience, :client_id, :client_secret, :auth_url

    def initialize(auth_url:, audience:, client_id:, client_secret:)
      @auth_url = auth_url
      @audience = audience
      @client_id = client_id
      @client_secret = client_secret
    end

    def token
      return access_token if access_token&.alive?

      self.access_token = TokenCache.fetch(cache_key) { fetch }
    end

    private

    attr_accessor :access_token

    def fetch
      url = "#{auth_url}oauth/token"
      connection = Connection.build(url: url, headers: { 'content-type' => 'application/json' })
      response = connection.post(url, request_body)

      raise Error, "Auth0 returned #{response.status} for audience '#{audience}'" unless response.success?

      access_token = response.body.try(:access_token)
      raise Error, "Auth0 returned no access_token for audience '#{audience}'" if access_token.blank?

      Token.new(access_token)
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
      @cache_key ||= "#{self.class.name}:#{auth_url}:#{client_id}:#{audience}"
    end
  end
end
