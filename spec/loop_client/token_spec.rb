# frozen_string_literal: true

RSpec.describe LoopClient::Token do
  let(:access_token) { Helpers::JWT_ACCESS_TOKEN }
  let(:token) { described_class.new(access_token) }

  describe '#payload' do
    let(:expected_payload) do
      [{ 'aud' => 'dev-tds',
         'azp' => '0yz98DYaD8brBQ7AFCIDk2fVy94IIo67',
         'exp' => 1_572_102_061,
         'gty' => 'client-credentials',
         'iat' => 1_572_015_661,
         'iss' => 'https://dev-dms.auth0.com/',
         'permissions' => ['read:shipping_containers'],
         'scope' => 'read:shipping_containers',
         'sub' => '0yz98DYaD8brBQ7AFCIDk2fVy94IIo67@clients' },
       { 'alg' => 'RS256',
         'kid' => 'OTgyM0M2Nzk4Mjk3MzNGMTY2ODAzQTRENDkyNkEyOTZGRjhFQjFGNw',
         'typ' => 'JWT' }]
    end

    it 'decodes JWT payload' do
      expect(token.payload).to eq(expected_payload)
    end

    it 'memoizes the result' do
      token.payload
      allow(JWT).to receive(:decode)
      token.payload
      expect(JWT).not_to have_received(:decode)
    end
  end

  describe '#expiration' do
    it 'returns exp claim from payload' do
      expect(token.expiration).to eq(1_572_102_061)
    end
  end

  describe '#alive?' do
    context 'when token is expired' do
      it 'returns false' do
        expect(token).not_to be_alive
      end
    end

    context 'when token is valid' do
      before do
        allow(token).to receive(:expiration).and_return(Time.now.to_i + 120)
      end

      it 'returns true' do
        expect(token).to be_alive
      end
    end

    context 'when token expires within 60 seconds' do
      before do
        allow(token).to receive(:expiration).and_return(Time.now.to_i + 30)
      end

      it 'returns false due to 60-second buffer' do
        expect(token).not_to be_alive
      end
    end
  end
end
