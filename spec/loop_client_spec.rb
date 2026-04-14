# frozen_string_literal: true

RSpec.describe LoopClient do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(described_class.configuration).to be_a LoopClient::Configuration
    end

    it 'memoizes the instance' do
      config = described_class.configuration
      expect(described_class.configuration).to be config
    end
  end

  describe '.configure' do
    it 'yields configuration' do
      described_class.configure do |config|
        expect(config).to be_a LoopClient::Configuration
      end
    end
  end

  describe '.[]' do
    before do
      described_class.configure do |config|
        config.auth_url = 'AUTH0_URL'
        config.client_id = 'AUTH0_CLIENT_ID'
        config.client_secret = 'AUTH0_CLIENT_SECRET'
        config.add_api :TDS, url: 'TDS_URL', audience: 'TDS_AUDIENCE'
        config.add_api :DMS, url: 'DMS_URL', audience: 'DMS_AUDIENCE'
        config.add_api :CoMS, url: 'COMS_URL', audience: 'COMS_AUDIENCE'
      end
    end

    it 'raises error for unknown api' do
      expect { described_class[:UNKNOWN] }.to raise_error LoopClient::Error, "Unknown api with name 'UNKNOWN'"
    end

    it 'returns Api instance for TDS' do
      expect(described_class[:TDS]).to be_a LoopClient::Api
    end

    it 'returns Api instance for DMS' do
      expect(described_class[:DMS]).to be_a LoopClient::Api
    end

    it 'returns Api instance for CoMS' do
      expect(described_class[:CoMS]).to be_a LoopClient::Api
    end

    it 'caches Api instances per key' do
      first_call = described_class[:TDS]
      expect(described_class[:TDS]).to be first_call
    end
  end

  describe '.reset!' do
    before do
      described_class.configure do |config|
        config.auth_url = 'AUTH0_URL'
        config.client_id = 'AUTH0_CLIENT_ID'
        config.client_secret = 'AUTH0_CLIENT_SECRET'
        config.add_api :TDS, url: 'TDS_URL', audience: 'TDS_AUDIENCE'
      end
      described_class[:TDS]
    end

    it 'resets configuration' do
      described_class.reset!
      expect(described_class.configuration.apis).to be_empty
    end

    it 'resets cached apis' do
      described_class.reset!
      expect { described_class[:TDS] }.to raise_error LoopClient::Error
    end
  end
end
