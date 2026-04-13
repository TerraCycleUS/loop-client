# frozen_string_literal: true

RSpec.describe LoopClient::Token do
  let(:access_token) { Helpers::JWT_ACCESS_TOKEN }
  let(:token) { described_class.new(access_token) }
  let(:encoded_data) do
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

  it '#payload' do
    expect(token.payload).to eq(encoded_data)
  end

  it '#expiration' do
    expect(token.expiration).to eq(1_572_102_061)
  end

  # rubocop:disable RSpec/PredicateMatcher
  it '#alive?' do
    expect(token.alive?).to be_falsey
  end
  # rubocop:enable RSpec/PredicateMatcher
end
