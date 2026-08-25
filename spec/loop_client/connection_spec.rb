# frozen_string_literal: true

RSpec.describe LoopClient::Connection do
  subject(:connection) { described_class.build(url: url, headers: { 'content-type' => 'application/json' }) }

  let(:url) { 'https://example.test' }

  describe '.build' do
    it 'defaults the request timeout' do
      expect(connection.options.timeout).to eq LoopClient::Configuration::DEFAULT_TIMEOUT
    end

    it 'defaults the connection timeout' do
      expect(connection.options.open_timeout).to eq LoopClient::Configuration::DEFAULT_OPEN_TIMEOUT
    end

    context 'with timeouts configured' do
      before do
        LoopClient.configure do |config|
          config.timeout = 12
          config.open_timeout = 3
        end
      end

      it 'takes the request timeout from the configuration' do
        expect(connection.options.timeout).to eq 12
      end

      it 'takes the connection timeout from the configuration' do
        expect(connection.options.open_timeout).to eq 3
      end
    end

    it 'sends a hash body as json' do
      stub_request(:post, "#{url}/x").to_return(status: 200, body: '{}')

      connection.post('x', { query: 'T' })

      expect(WebMock).to have_requested(:post, "#{url}/x").with(body: '{"query":"T"}')
    end

    it 'leaves an already serialised body alone' do
      stub_request(:post, "#{url}/x").to_return(status: 200, body: '{}')

      connection.post('x', '{"query":"T"}')

      expect(WebMock).to have_requested(:post, "#{url}/x").with(body: '{"query":"T"}')
    end

    it 'parses a json response into an OpenStruct' do
      stub_request(:get, "#{url}/x")
        .to_return(status: 200, body: '{"net_amount":0.35}', headers: { 'Content-Type' => 'application/json' })

      expect(connection.get('x').body.net_amount).to eq 0.35
    end
  end
end
