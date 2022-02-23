# LoopClient

This is client gem for easy working with Integrated projects API

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'loop-client', github: 'TerraCycleUS/loop-client'
```

And then execute:

    $ bundle install

## Configuration

```
require 'loop/client'

LoopClient.configure do |config|
  config.logger = Logger.new(STDOUT) # or your own logger

  config.auth_url = ENV['AUTH0_URL']
  config.client_id = ENV['AUTH0_CLIENT_ID']
  config.client_secret = ENV['AUTH0_CLIENT_SECRET']

  config.add_api :TDS, url: ENV['TDS_URL'], audience: ENV['TDS_AUDIENCE']
  config.add_api :DMS, url: ENV['DMS_URL'], audience: ENV['DMS_AUDIENCE']
  config.add_api :CoMS, url: ENV['COMS_URL'], audience: ENV['COMS_AUDIENCE']
end
```

## Usage

GET request examples: 

`response = LoopClient[:DMS].api.v1.deposits.get`

or

`response = LoopClient[:DMS].api('v1').deposits.get`

or

`response = LoopClient[:DMS].api('v1', 'deposits').get`

Read response:

```
response_body = response.body
response_body[0].net_amount # => 0.35
response_body[0].currency # => EUR
response_body[0].package.name # => Coca-Cola 1L Glass
response_body[0].package.sku # => 1314254645627
```

PUT request examples:

`LoopClient[:CoMS].api.v1.containers('identity_code').freeup.put`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/loop-client.
