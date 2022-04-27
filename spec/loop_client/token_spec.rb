# frozen_string_literal: true

# rubocop:disable Metrics::BlockLength
RSpec.describe LoopClient::Token do
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

  # rubocop:disable RSpec::PredicateMatcher
  it '#alive?' do
    expect(token.alive?).to be_falsey
  end
  # rubocop:enable RSpec::PredicateMatcher
end
# rubocop:enable Metrics::BlockLength
