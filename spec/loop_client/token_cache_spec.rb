# frozen_string_literal: true

RSpec.describe LoopClient::TokenCache do
  let(:access_token) { Helpers::JWT_ACCESS_TOKEN }
  let(:token) { LoopClient::Token.new(access_token) }
  let(:cache_store) { Helpers::FakeSolidCache.new }
  let(:configuration) { Struct.new(:cache_store) }

  # rubocop:disable RSpec/AnyInstance
  before do
    cache_store.clear
    allow(LoopClient).to receive(:configuration).and_return(configuration.new(cache_store))
    allow_any_instance_of(LoopClient::Token).to receive(:expiration).and_return(Time.now.to_i + 100)
  end
  # rubocop:enable RSpec/AnyInstance

  context 'with new value' do
    # rubocop:disable Style/EmptyLiteral
    before do
      allow(Array).to receive(:new).and_call_original
      described_class.fetch('token') { Array.new.push(token).first }
    end
    # rubocop:enable Style/EmptyLiteral

    it 'calls block' do
      expect(Array).to(have_received(:new).once)
    end

    it 'returns token' do
      expect(cache_store.read('token')).to(eq(token))
    end
  end

  context 'with cached value' do
    before do
      allow(cache_store).to(receive(:ttl).and_return(100))
      allow(Array).to(receive(:new).and_call_original)
      cache_store.write('token', token)
      described_class.fetch('token') { [].push(token).first }
    end

    it 'does not calls block' do
      expect(Array).not_to(have_received(:new))
    end

    it 'returns token' do
      expect(cache_store.read('token')).to(eq(token))
    end
  end
end
