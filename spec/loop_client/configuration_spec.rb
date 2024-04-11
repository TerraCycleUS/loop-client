# frozen_string_literal: true

# rubocop:disable Metrics::BlockLength
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
    it 'raises proper exception for blank url' do
      expect { configuration.add_api('TDS', url: nil, audience: 'audience') }
        .to raise_exception LoopClient::Error, "Url can't be blank"
    end

    it 'raises proper exception for blank audience' do
      expect { configuration.add_api('TDS', url: 'https://test.com', audience: nil) }
        .to raise_exception LoopClient::Error, "audience can't be blank"
    end

    context 'with one api' do
      before do
        configuration.add_api('TDS', url: 'https://test.com', audience: 'audience')
      end

      it 'adds api' do
        expect(configuration.apis).to eq({ TDS: { url: 'https://test.com', audience: 'audience' } })
      end
    end

    context 'with multi apis' do
      before do
        configuration.add_api('TDS', url: 'https://test.com', audience: 'audience')
        configuration.add_api('DMS', url: 'https://test2.com', audience: 'audience2')
      end

      it 'adds api' do
        expect(configuration.apis)
          .to eq({ TDS: { url: 'https://test.com', audience: 'audience' },
                   DMS: { url: 'https://test2.com', audience: 'audience2' } })
      end
    end
  end

  describe '#logger' do
    it 'raises proper exception for blank audience' do
      configuration.logger = Logger.new($stdout)
      expect(configuration.logger).to be_a Logger
    end
  end
end
# rubocop:enable Metrics::BlockLength
