# frozen_string_literal: true

RSpec.describe 'gem packaging' do
  subject(:files) { Gem::Specification.load('loop_client.gemspec').files }

  it 'ships the library' do
    expect(files).to include('lib/loop_client.rb', 'lib/loop_client/version.rb')
  end

  it 'keeps tooling and hooks out of the package' do
    expect(files.grep(%r{\A(?:\.release|\.circleci|\.githooks|\.github)/})).to be_empty
  end

  it 'keeps release configuration out of the package' do
    expect(files).not_to include('release-please-config.json', '.release-please-manifest.json')
  end
end
