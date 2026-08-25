# frozen_string_literal: true

RSpec.describe LoopClient::TokenCache do
  let(:access_token) { Helpers::JWT_ACCESS_TOKEN }
  let(:token) { LoopClient::Token.new(access_token) }
  let(:cache_store) { Helpers::FakeSolidCache.new }
  let(:configuration) { Struct.new(:cache_store) }

  # rubocop:disable-next RSpec/AnyInstance
  before do
    cache_store.clear
    allow(LoopClient).to receive(:configuration).and_return(configuration.new(cache_store))
    allow_any_instance_of(LoopClient::Token).to receive(:expiration).and_return(Time.now.to_i + 120)
  end

  describe '.fetch' do
    context 'when no cache store is configured' do
      before { allow(LoopClient).to receive(:configuration).and_return(configuration.new(nil)) }

      it 'names the missing setting' do
        expect { described_class.fetch('token') { token } }
          .to raise_error LoopClient::Error, 'cache_store is not configured'
      end
    end

    context 'when cache is empty' do
      it 'calls the block' do
        block_called = false
        described_class.fetch('token') { block_called = true; token } # rubocop:disable Style/Semicolon
        expect(block_called).to be true
      end

      it 'returns the token from block' do
        result = described_class.fetch('token') { token }
        expect(result).to eq(token)
      end

      it 'writes token to cache' do
        described_class.fetch('token') { token }
        expect(cache_store.read('token')).to eq(token)
      end
    end

    context 'when cache has alive token' do
      before { cache_store.write('token', token) }

      it 'does not call the block' do
        block_called = false
        described_class.fetch('token') { block_called = true; token } # rubocop:disable Style/Semicolon
        expect(block_called).to be false
      end

      it 'returns the cached token' do
        result = described_class.fetch('token') { token }
        expect(result).to eq(token)
      end
    end

    context 'when cache has expired token' do
      # rubocop:disable-next RSpec/AnyInstance
      before do
        cache_store.write('token', token)
        allow_any_instance_of(LoopClient::Token).to receive(:alive?).and_return(false)
      end

      it 'calls the block for a fresh token' do
        block_called = false
        described_class.fetch('token') { block_called = true; token } # rubocop:disable Style/Semicolon
        expect(block_called).to be true
      end
    end
  end
end
