# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  enable_coverage :branch
  minimum_coverage line: 90, branch: 80
end

require 'loop_client'
require 'webmock/rspec'
require 'helpers/fake_solid_cache'
require 'helpers/test_data'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after do
    LoopClient.reset!
  end
end
