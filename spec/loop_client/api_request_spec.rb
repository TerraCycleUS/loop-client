# frozen_string_literal: true

# rubocop:disable Metrics::BlockLength
RSpec.describe LoopClient::ApiRequest do
  # rubocop:disable RSpec::AnyInstance
  before do
    LoopClient.configure do |config|
      config.logger = Logger.new($stdout)

      config.cache_store = Helpers::FakeSolidCache.new
      config.auth_url = 'https://test.com'
      config.client_id = 'AUTH0_CLIENT_ID'
      config.client_secret = 'AUTH0_CLIENT_SECRET'

      config.add_api :TDS, url: url, audience: 'TDS_AUDIENCE'
    end

    allow_any_instance_of(LoopClient::TokenFetcher).to receive(:token).and_return(token)
  end
  # rubocop:enable RSpec::AnyInstance

  let!(:loop_client_api) { LoopClient[:TDS]              }
  let(:token)            { '333'                         }
  let(:url)              { 'https://test-tds.com'        }
  let(:headers) do
    {
      'Content-Type' => 'application/json',
      'User-Agent' => 'Faraday v2.9.0',
      'Authorization' => "Bearer #{token}",
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Accept' => '*/*'
    }
  end

  it 'calls get request' do
    stub_request(:get, "#{url}/?query=test")
      .with(headers: headers)
      .to_return(status: 200, body: '{}')

    expect(loop_client_api.get(params: { query: 'test' }).status).to eq 200
  end

  it 'calls post request' do
    stub_request(:post, "#{url}/")
      .with(body: a_hash_including({ query: 'T' }), headers: headers)
      .to_return(status: 200, body: '{}')

    expect(loop_client_api.post(body: { query: 'T' }).status).to eq 200
  end

  it 'calls put request' do
    stub_request(:put, "#{url}/")
      .with(body: a_hash_including({ query: 'T' }), headers: headers)
      .to_return(status: 200, body: '{}')

    expect(loop_client_api.put(body: { query: 'T' }).status).to eq 200
  end

  it 'calls patch request' do
    stub_request(:patch, "#{url}/")
      .with(body: a_hash_including({ query: 'T' }), headers: headers)
      .to_return(status: 200, body: '{}')

    expect(loop_client_api.patch(body: { query: 'T' }).status).to eq 200
  end

  it 'calls delete request' do
    stub_request(:delete, "#{url}/?id=1")
      .with(headers: headers)
      .to_return(status: 200, body: '{}')

    expect(loop_client_api.delete(params: { id: 1 }).status).to eq 200
  end
end
# rubocop:enable Metrics::BlockLength
