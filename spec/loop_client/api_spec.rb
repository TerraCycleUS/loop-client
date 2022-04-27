# frozen_string_literal: true

# rubocop:disable Metrics::BlockLength
RSpec.describe LoopClient::Api do
  before do
    LoopClient.configure do |config|
      config.logger = Logger.new($stdout)

      config.redis = Helpers::FakeRedis.new
      config.auth_url = 'https://test.com'
      config.client_id = 'AUTH0_CLIENT_ID'
      config.client_secret = 'AUTH0_CLIENT_SECRET'

      config.add_api :TDS, url: 'https://test-tds.com', audience: 'TDS_AUDIENCE'
    end

    allow(LoopClient::ApiRequest).to receive(:new).and_return(api_request)
    allow(api_request).to receive(:call).with(method: method)
  end

  let(:api_request) { instance_double(LoopClient::ApiRequest) }
  let(:method) { :get }
  let!(:loop_client_api) { LoopClient[:TDS] }

  it 'defines token_fetcher' do
    expect(loop_client_api.token_fetcher).to be_a LoopClient::TokenFetcher
  end

  describe '#get' do
    let(:params) do
      {
        body: nil,
        params: { query: 'test' },
        path: '',
        token_fetcher: anything,
        url: 'https://test-tds.com'
      }
    end

    it 'call ApiRequest with right params' do
      loop_client_api.get(params: { query: 'test' })

      expect(LoopClient::ApiRequest).to have_received(:new).with(params)
    end
  end

  describe '#post' do
    let(:method) { :post }
    let(:params) do
      {
        body: { query: 'T' },
        params: nil,
        path: '',
        token_fetcher: anything,
        url: 'https://test-tds.com'
      }
    end

    it 'call ApiRequest with right params' do
      loop_client_api.post(body: { query: 'T' })
      expect(LoopClient::ApiRequest).to have_received(:new).with(params)
    end
  end

  describe '#put' do
    let(:method) { :put }
    let(:params) do
      {
        body: { query: 'T' },
        params: nil,
        path: '',
        token_fetcher: anything,
        url: 'https://test-tds.com'
      }
    end

    it 'call on ApiRequest with right params' do
      loop_client_api.put(body: { query: 'T' })
      expect(LoopClient::ApiRequest).to have_received(:new).with(params)
    end
  end

  describe '#patch' do
    let(:method) { :patch }
    let(:params) do
      {
        body: { query: 'T' },
        params: nil,
        path: '',
        token_fetcher: anything,
        url: 'https://test-tds.com'
      }
    end

    it 'call ApiRequest with right params' do
      loop_client_api.patch(body: { query: 'T' })
      expect(LoopClient::ApiRequest).to have_received(:new).with(params)
    end
  end

  describe '#delete' do
    let(:method) { :delete }
    let(:params) do
      {
        body: nil,
        params: { id: 1 },
        path: '',
        token_fetcher: anything,
        url: 'https://test-tds.com'
      }
    end

    it 'call ApiRequest with right params' do
      loop_client_api.delete(params: { id: 1 })
      expect(LoopClient::ApiRequest).to have_received(:new).with(params)
    end
  end

  describe '#method missing' do
    let(:method) { :patch }

    it 'respond to .method call on instance' do
      expect(loop_client_api.method(:lists)).to be_a(Method)
    end

    it 'build right path' do
      loop_client_api.api.v1.user(1).patch(body: { query: 'T' })

      params = { body: { query: 'T' }, params: nil, path: 'api/v1/user/1',
                 token_fetcher: anything, url: 'https://test-tds.com' }
      expect(LoopClient::ApiRequest).to have_received(:new).with(params)
    end
  end
end
# rubocop:enable Metrics::BlockLength
