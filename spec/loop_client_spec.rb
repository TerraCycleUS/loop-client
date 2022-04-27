# frozen_string_literal: true

# rubocop:disable Metrics::BlockLength
RSpec.describe LoopClient do
  it 'has a version number' do
    expect(LoopClient::VERSION).not_to be_nil
  end

  context 'without configured api' do
    it 'has a configuration' do
      expect(described_class.configuration).to be_a LoopClient::Configuration
    end

    it 'accepts configure' do
      expect(described_class.configure { 'a' }).to eq 'a'
    end

    it 'raise exception with unknown api' do
      expect { described_class['test'] }.to raise_error LoopClient::Error, "Unknown api with name 'test'"
    end
  end

  context 'with configured api' do
    before do
      described_class.configure do |config|
        config.logger = Logger.new($stdout)

        config.auth_url = 'AUTH0_URL'
        config.client_id = 'AUTH0_CLIENT_ID'
        config.client_secret = 'AUTH0_CLIENT_SECRET'

        config.add_api :TDS, url: 'TDS_URL', audience: 'TDS_AUDIENCE'
        config.add_api :DMS, url: 'DMS_URL', audience: 'DMS_AUDIENCE'
        config.add_api :CoMS, url: 'COMS_URL', audience: 'COMS_AUDIENCE'
      end
    end

    let(:apis) do
      {
        TDS: { url: 'TDS_URL', audience: 'TDS_AUDIENCE' },
        DMS: { url: 'DMS_URL', audience: 'DMS_AUDIENCE' },
        CoMS: { url: 'COMS_URL', audience: 'COMS_AUDIENCE' }
      }
    end

    it 'has a right configuration' do
      expect(described_class.configuration.apis).to eq(apis)
    end

    it 'returns right api configs for TDS' do
      expect(described_class[:TDS]).to be_a LoopClient::Api
    end

    it 'returns right api configs for DMS' do
      expect(described_class[:DMS]).to be_a LoopClient::Api
    end

    it 'returns right api configs CoMS' do
      expect(described_class[:CoMS]).to be_a LoopClient::Api
    end
  end
end
# rubocop:enable Metrics::BlockLength
