# frozen_string_literal: true

# rubocop:disable Metrics::BlockLength
RSpec.describe LoopClient::TokenFetcher do
  subject(:token_fetcher) do
    described_class.new(auth_url: 'https://auth.com',
                        audience: 'audience',
                        client_id: '333',
                        client_secret: 'secret')
  end

  let(:access_token) do
    'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Ik9UZ3lNME0yTnprNE1qazNNek5HTVRZMk9EQXpRVFJF'\
      'TkRreU5rRXlPVFpHUmpoRlFqRkdOdyJ9.eyJpc3MiOiJodHRwczovL2Rldi1kbXMuYXV0aDAuY29tLyIsInN1YiI'\
      '6IjB5ejk4RFlhRDhickJRN0FGQ0lEazJmVnk5NElJbzY3QGNsaWVudHMiLCJhdWQiOiJkZXYtdGRzIiwiaWF0Ijo'\
      'xNTcyMDE1NjYxLCJleHAiOjE1NzIxMDIwNjEsImF6cCI6IjB5ejk4RFlhRDhickJRN0FGQ0lEazJmVnk5NElJbzY'\
      '3Iiwic2NvcGUiOiJyZWFkOnNoaXBwaW5nX2NvbnRhaW5lcnMiLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbHMiLCJ'\
      'wZXJtaXNzaW9ucyI6WyJyZWFkOnNoaXBwaW5nX2NvbnRhaW5lcnMiXX0.AF8omJr8g98fLqUYwxb9P6QLTHfFmz-'\
      'o-uOxoqXW1SAlHA0bGCpIPcxewbWT6xsJhT-2EyIhE0UdHaD0kaZmaSdnIyr4uaW2cXOwE8jWMeQ73CC3gS9eNTm'\
      'tsZK3PIYCDXii8Qsgn7Ze7ROz9MlMVpjn1JdmFiH7BCYA218ChMM2jtNbsjwDgokwBlXrJWub2DtA7c0Hp3iB68T'\
      'Zy1nW82N44cZSj8WGdzA8ZB1vLSLXiVdET4jWCXNq-g18fViT7MGh6mSPIPSITsu-JE9KPK9_AhmeC-i0QqRn4dB'\
      'wWi2GQN5NjOTvBd8Rc-UNLm_lHrDUCm92T5cDvdT7L9hySA'
  end
  let(:token) { LoopClient::Token.new(access_token) }

  # rubocop:disable RSpec::AnyInstance
  before do
    allow_any_instance_of(LoopClient::Token).to receive(:expiration).and_return(Time.now.to_i + 100)
  end
  # rubocop:enable RSpec::AnyInstance

  it '#attr_readers secret' do
    expect(token_fetcher.client_secret).to eq 'secret'
  end

  it '#attr_readers auth_url' do
    expect(token_fetcher.auth_url).to eq 'https://auth.com'
  end

  it '#attr_readers audience' do
    expect(token_fetcher.audience).to eq 'audience'
  end

  it '#attr_readers client_id' do
    expect(token_fetcher.client_id).to eq '333'
  end

  describe '#token' do
    let(:key) { 'LoopClient::TokenFetcher:https://auth.com:333:audience' }

    before do
      allow(LoopClient::TokenCache).to receive(:fetch).with(key).and_return(token)
    end

    describe 'token' do
      it 'returns token from LoopClient::Token' do
        expect(token_fetcher.token).to eq(token)
      end

      it 'returns stubbed token' do
        token_fetcher.instance_variable_set(:@access_token, token)
        token_fetcher.token
        expect(LoopClient::TokenCache).not_to have_received(:fetch)
      end
    end

    context 'without cached data' do
      let(:redis) { Helpers::FakeRedis.new }
      let(:configuration) { Struct.new(:redis) }

      before do
        redis.flushall
        allow(LoopClient).to receive(:configuration).and_return(configuration.new(redis))
      end

      # rubocop:disable RSpec::AnyInstance
      it 'returns token from #fetch' do
        allow_any_instance_of(described_class).to receive(:fetch).and_return(token)
        expect(token_fetcher.token).to eq(token)
      end
      # rubocop:enable RSpec::AnyInstance
    end
  end

  describe '#fetch' do
    let(:headers) do
      {
        'Content-Type' => 'application/json',
        'User-Agent' => 'Faraday v2.2.0',
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
      stub_request(:post, 'https://auth.comoauth/token')
        .with(body: post_params, headers: headers)
        .to_return(status: 200,
                   body: { access_token: access_token }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
    end

    it '#attr_readers' do
      expect(token_fetcher.fetch).to eq token
    end
  end
end
# rubocop:enable Metrics::BlockLength
