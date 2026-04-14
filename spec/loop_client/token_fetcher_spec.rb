# frozen_string_literal: true

RSpec.describe LoopClient::TokenFetcher do
  subject(:token_fetcher) do
    described_class.new(auth_url: 'https://auth.com/',
                        audience: 'audience',
                        client_id: '333',
                        client_secret: 'secret')
  end

  let(:access_token) { Helpers::JWT_ACCESS_TOKEN }
  let(:token) { LoopClient::Token.new(access_token) }

  # rubocop:disable RSpec/AnyInstance
  before do
    allow_any_instance_of(LoopClient::Token).to receive(:expiration).and_return(Time.now.to_i + 120)
  end
  # rubocop:enable RSpec/AnyInstance

  describe 'attr_readers' do
    it { expect(token_fetcher.auth_url).to eq 'https://auth.com/' }
    it { expect(token_fetcher.audience).to eq 'audience' }
    it { expect(token_fetcher.client_id).to eq '333' }
    it { expect(token_fetcher.client_secret).to eq 'secret' }
  end

  describe '#token' do
    let(:key) { 'LoopClient::TokenFetcher:https://auth.com/:333:audience' }

    before do
      allow(LoopClient::TokenCache).to receive(:fetch).with(key).and_return(token)
    end

    it 'fetches token via TokenCache' do
      expect(token_fetcher.token).to eq(token)
    end

    it 'returns in-memory cached token when alive' do
      token_fetcher.instance_variable_set(:@access_token, token)
      token_fetcher.token
      expect(LoopClient::TokenCache).not_to have_received(:fetch)
    end

    it 'refetches when in-memory token is expired' do
      expired_token = LoopClient::Token.new(access_token)
      allow(expired_token).to receive(:alive?).and_return(false)
      token_fetcher.instance_variable_set(:@access_token, expired_token)

      token_fetcher.token
      expect(LoopClient::TokenCache).to have_received(:fetch).with(key)
    end

    it 'fetches via TokenCache when access_token is nil' do
      token_fetcher.instance_variable_set(:@access_token, nil)
      token_fetcher.token
      expect(LoopClient::TokenCache).to have_received(:fetch).with(key)
    end

    context 'without cached data' do
      let(:cache_store) { Helpers::FakeSolidCache.new }
      let(:configuration) { Struct.new(:cache_store) }

      before do
        cache_store.clear
        allow(LoopClient).to receive(:configuration).and_return(configuration.new(cache_store))
      end

      # rubocop:disable RSpec/AnyInstance
      it 'calls fetch to get a new token' do
        allow_any_instance_of(described_class).to receive(:fetch).and_return(token)
        expect(token_fetcher.token).to eq(token)
      end
      # rubocop:enable RSpec/AnyInstance
    end
  end

  describe '#cache_key' do
    it 'returns a key composed of class name, auth_url, client_id, and audience' do
      expected = 'LoopClient::TokenFetcher:https://auth.com/:333:audience'
      expect(token_fetcher.send(:cache_key)).to eq(expected)
    end

    it 'memoizes the key' do
      first_call = token_fetcher.send(:cache_key)
      expect(token_fetcher.send(:cache_key)).to be(first_call)
    end
  end

  describe '#fetch' do
    let(:headers) do
      {
        'Content-Type' => 'application/json',
        'User-Agent' => /Faraday/,
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Accept' => '*/*'
      }
    end

    let(:post_params) do
      {
        client_id: '333',
        client_secret: 'secret',
        audience: 'audience',
        grant_type: 'client_credentials'
      }
    end

    before do
      stub_request(:post, 'https://auth.com/oauth/token')
        .with(body: post_params, headers: headers)
        .to_return(status: 200,
                   body: { access_token: access_token }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
    end

    it 'fetches token from Auth0' do
      expect(token_fetcher.send(:fetch)).to eq token
    end
  end
end
