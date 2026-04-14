# frozen_string_literal: true

RSpec.describe LoopClient::Api do
  before do
    LoopClient.configure do |config|
      config.logger = Logger.new($stdout)
      config.cache_store = Helpers::FakeSolidCache.new
      config.auth_url = 'https://test.com'
      config.client_id = 'AUTH0_CLIENT_ID'
      config.client_secret = 'AUTH0_CLIENT_SECRET'
      config.add_api :TDS, url: 'https://test-tds.com', audience: 'TDS_AUDIENCE'
    end

    allow(LoopClient::ApiRequest).to receive(:new).and_return(api_request)
    allow(api_request).to receive(:call).with(method: http_method).and_return(response)
  end

  let(:api_request) { instance_double(LoopClient::ApiRequest) }
  let(:response) { instance_double(Faraday::Response, status: 200) }
  let(:http_method) { :get }
  let(:loop_client_api) { LoopClient[:TDS] }

  it 'defines token_fetcher' do
    expect(loop_client_api.token_fetcher).to be_a LoopClient::TokenFetcher
  end

  it 'caches url from configuration at initialization' do
    loop_client_api
    LoopClient.configuration.apis[:TDS][:url] = 'https://changed-url.com'

    loop_client_api.get
    expect(LoopClient::ApiRequest).to have_received(:new).with(hash_including(url: 'https://test-tds.com'))
  end

  describe '#get' do
    let(:expected_params) do
      { body: nil, params: { query: 'test' }, path: '', token_fetcher: anything, url: 'https://test-tds.com' }
    end

    it 'calls ApiRequest with right params' do
      loop_client_api.get(params: { query: 'test' })
      expect(LoopClient::ApiRequest).to have_received(:new).with(expected_params)
    end
  end

  describe '#post' do
    let(:http_method) { :post }
    let(:expected_params) do
      { body: { query: 'T' }, params: nil, path: '', token_fetcher: anything, url: 'https://test-tds.com' }
    end

    it 'calls ApiRequest with right params' do
      loop_client_api.post(body: { query: 'T' })
      expect(LoopClient::ApiRequest).to have_received(:new).with(expected_params)
    end
  end

  describe '#put' do
    let(:http_method) { :put }
    let(:expected_params) do
      { body: { query: 'T' }, params: nil, path: '', token_fetcher: anything, url: 'https://test-tds.com' }
    end

    it 'calls ApiRequest with right params' do
      loop_client_api.put(body: { query: 'T' })
      expect(LoopClient::ApiRequest).to have_received(:new).with(expected_params)
    end
  end

  describe '#patch' do
    let(:http_method) { :patch }
    let(:expected_params) do
      { body: { query: 'T' }, params: nil, path: '', token_fetcher: anything, url: 'https://test-tds.com' }
    end

    it 'calls ApiRequest with right params' do
      loop_client_api.patch(body: { query: 'T' })
      expect(LoopClient::ApiRequest).to have_received(:new).with(expected_params)
    end
  end

  describe '#delete' do
    let(:http_method) { :delete }
    let(:expected_params) do
      { body: nil, params: { id: 1 }, path: '', token_fetcher: anything, url: 'https://test-tds.com' }
    end

    it 'calls ApiRequest with right params' do
      loop_client_api.delete(params: { id: 1 })
      expect(LoopClient::ApiRequest).to have_received(:new).with(expected_params)
    end
  end

  describe '#method_missing' do
    let(:http_method) { :patch }

    it 'responds to arbitrary methods' do
      expect(loop_client_api.method(:lists)).to be_a(Method)
    end

    it 'builds path from chained calls' do
      loop_client_api.api.v1.user(1).patch(body: { query: 'T' })

      expected = { body: { query: 'T' }, params: nil, path: 'api/v1/user/1',
                   token_fetcher: anything, url: 'https://test-tds.com' }
      expect(LoopClient::ApiRequest).to have_received(:new).with(expected)
    end

    it 'does not add empty args to path' do
      loop_client_api.api.v1.deposits.patch(body: {})

      expect(LoopClient::ApiRequest).to have_received(:new).with(hash_including(path: 'api/v1/deposits'))
    end

    it 'handles multiple arguments in path segment' do
      loop_client_api.api.v1.user(1, 'details').patch(body: {})

      expect(LoopClient::ApiRequest).to have_received(:new).with(hash_including(path: 'api/v1/user/1/details'))
    end
  end

  describe 'logging' do
    let(:logger) { instance_double(Logger) }

    before do
      allow(logger).to receive(:info)
      allow(logger).to receive(:error)
      LoopClient.configuration.logger = logger
    end

    it 'logs successful request as structured JSON' do
      loop_client_api.api.v1.test.get

      expect(logger).to have_received(:info).with(a_string_matching(/"message":"LoopClient Request"/))
    end

    it 'logs error request as structured JSON' do
      allow(api_request).to receive(:call).and_raise(StandardError, 'timeout')

      loop_client_api.api.v1.test.get rescue nil # rubocop:disable Style/RescueModifier

      expect(logger).to have_received(:error).with(a_string_matching(/"error":"timeout"/))
    end
  end

  describe 'error handling' do
    let(:http_method) { :get }

    before do
      allow(api_request).to receive(:call).and_raise(StandardError, 'connection refused')
    end

    it 'logs error and re-raises exception' do
      expect { loop_client_api.get }.to raise_error(StandardError, 'connection refused')
    end

    it 'resets path after error' do
      loop_client_api.api.v1.test
      loop_client_api.get rescue nil # rubocop:disable Style/RescueModifier

      allow(api_request).to receive(:call).with(method: :get).and_return(response)
      loop_client_api.api.v2.other.get
      expect(LoopClient::ApiRequest).to have_received(:new).with(hash_including(path: 'api/v2/other'))
    end
  end
end
