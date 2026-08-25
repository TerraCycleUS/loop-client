# frozen_string_literal: true

RSpec.describe LoopClient::Configuration do
  let(:configuration) { described_class.new }

  describe '#attr_accessor' do
    before do
      configuration.auth_url = 'https://auth_url.com'
      configuration.client_id = '1'
      configuration.client_secret = 'SECRET'
      configuration.cache_store = Helpers::FakeSolidCache.new
    end

    it 'attr_accessor auth_url' do
      expect(configuration.auth_url).to eq('https://auth_url.com')
    end

    it 'attr_accessor client_id' do
      expect(configuration.client_id).to eq('1')
    end

    it 'attr_accessor client_secret' do
      expect(configuration.client_secret).to eq('SECRET')
    end

    it 'attr_accessor cache_store' do
      expect(configuration.cache_store).to be_a Helpers::FakeSolidCache
    end
  end

  describe '#add_api' do
    it 'raises error for blank url' do
      expect { configuration.add_api('TDS', url: nil, audience: 'audience') }
        .to raise_error LoopClient::Error, "url can't be blank"
    end

    it 'raises error for empty string url' do
      expect { configuration.add_api('TDS', url: '', audience: 'audience') }
        .to raise_error LoopClient::Error, "url can't be blank"
    end

    it 'raises error for blank audience' do
      expect { configuration.add_api('TDS', url: 'https://test.com', audience: nil) }
        .to raise_error LoopClient::Error, "audience can't be blank"
    end

    it 'raises error for empty string audience' do
      expect { configuration.add_api('TDS', url: 'https://test.com', audience: '') }
        .to raise_error LoopClient::Error, "audience can't be blank"
    end

    context 'with one api' do
      before { configuration.add_api('TDS', url: 'https://test.com', audience: 'audience') }

      it 'adds api with symbolized key' do
        expect(configuration.apis).to eq({ TDS: { url: 'https://test.com', audience: 'audience' } })
      end
    end

    context 'with multiple apis' do
      before do
        configuration.add_api('TDS', url: 'https://test.com', audience: 'audience')
        configuration.add_api('DMS', url: 'https://test2.com', audience: 'audience2')
      end

      it 'adds all apis' do
        expect(configuration.apis)
          .to eq({ TDS: { url: 'https://test.com', audience: 'audience' },
                   DMS: { url: 'https://test2.com', audience: 'audience2' } })
      end
    end
  end

  describe '#logger' do
    it 'returns default Logger when not configured' do
      expect(configuration.logger).to be_a Logger
    end

    it 'returns custom logger when explicitly set' do
      custom_logger = Logger.new($stderr)
      configuration.logger = custom_logger
      expect(configuration.logger).to be custom_logger
    end
  end
end
