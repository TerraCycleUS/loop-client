# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative 'lib/loop_client/version'

Gem::Specification.new do |spec|
  spec.name = 'loop-client'
  spec.version = LoopClient::VERSION
  spec.authors = ['Loop IT']
  spec.email = ['loopit@terracycle.com']

  spec.summary = 'Loop Client gem for Loop Integrated projects'
  spec.homepage = 'https://github.com/TerraCycleUS/loop-client'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  # TODO: spec.metadata['changelog_uri'] = 'https://source.com'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(/\A(?:(?:bin|test|spec|features)\/|\.(?:git|travis|circleci)|appveyor)/)
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(/\Aexe\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'addressable'
  spec.add_dependency 'faraday'
  spec.add_dependency 'jwt'
  spec.add_dependency 'solid_cache'
  spec.add_dependency 'zeitwerk'
end
