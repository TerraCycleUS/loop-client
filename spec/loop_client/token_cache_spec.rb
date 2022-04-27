# frozen_string_literal: true

# rubocop:disable Metrics::BlockLength
RSpec.describe LoopClient::TokenCache do
  let(:access_token) do
    'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Ik9UZ3lNME0yTnprNE1qazNNek5HTVRZMk9EQXpRVFJF'\
      'TkRreU5rRXlPVFpHUmpoRlFqRkdOdyJ9.eyJpc3MiOiJodHRwczovL2Rldi1kbXMuYXV0aDAuY29tLyIsInN1YiI'\
      '6IjB5ejk4RFlhRDhickJRN0FGQ0lEazJmVnk5NElJbzY3QGNsaWVudHMiLCJhdWQiOiJkZXYtdGRzIiwiaWF0Ijo'\
      'xNTcyMDE1NjYxLCJleHAiOjE1NzIxMDIwNjEsImF6cCI6IjB5ejk4RFlhRDhickJRN0FGQ0lEazJmVnk5NElJbzY'\
      '3Iiwic2NvcGUiOiJyZWFkOnNoaXBwaW5nX2NvbnRhaW5lcnMiLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbHMiLCJ'\
      'wZXJtaXNzaW9ucyI6WyJyZWFkOnNoaXBwaW5nX2NvbnRhaW5lcnMiXX0.AF8omJr8g98fLqUYwxb9P6QLTHfFmz-'\
      'o-uOxoqXW1SAlHA0bGCpIPcxewbWT6xsJhT-2EyIhE0UdHaD0kaZmaSdnIyr4uaW2cXOwE8jWMeQ73CC3gS9eNTm'\
      'tsZK3PIYCDXii8Qsgn7Ze7ROz9MlMVpjn1JdmFiH7BCYA218ChMM2jtNbsjwDgokwBlXrJWub2DtA7c0Hp3iB68T'\
      'Zy1nW82N44cZSj8WGdzA8ZB1vLSLXiVdET4jWCXNq-g18fViT7MGh6mSPIPSITsu-JE9KPK9_AhmeC-i0QqRn4dB'\
      'wWi2GQN5NjOTvBd8Rc-UNLm_lHrDUCm92T5cDvdT7L9hySA'
  end
  let(:token) { LoopClient::Token.new(access_token) }
  let(:redis) { Helpers::FakeRedis.new }
  let(:configuration) { Struct.new(:redis) }

  # rubocop:disable RSpec::AnyInstance
  before do
    redis.flushall
    allow(LoopClient).to receive(:configuration).and_return(configuration.new(redis))
    allow_any_instance_of(LoopClient::Token).to receive(:expiration).and_return(Time.now.to_i + 100)
  end
  # rubocop:enable RSpec::AnyInstance

  context 'with new value' do
    # rubocop:disable Style::EmptyLiteral
    before do
      allow(Array).to receive(:new).and_call_original
      described_class.fetch('token') { Array.new.push(token).first }
    end
    # rubocop:enable Style::EmptyLiteral

    it 'calls block' do
      expect(Array).to have_received(:new).once
    end

    it 'returns token' do
      expect(redis.get('token')).to eq(token)
    end
  end

  context 'with cached value' do
    # rubocop:disable RSpec::AnyInstance
    # rubocop:disable Style::EmptyLiteral
    before do
      allow_any_instance_of(Helpers::FakeRedis).to receive(:ttl).and_return(100)
      allow(Array).to receive(:new).and_call_original
      redis.set('token', token)
      described_class.fetch('token') { Array.new.push(token).first }
    end
    # rubocop:enable RSpec::AnyInstance
    # rubocop:enable Style::EmptyLiteral

    it 'does not calls block' do
      expect(Array).not_to have_received(:new)
    end

    it 'returns token' do
      expect(redis.get('token')).to eq(token)
    end
  end
end
# rubocop:enable Metrics::BlockLength
