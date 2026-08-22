# LoopClient

This is client gem for easy working with Integrated projects API

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'loop_client', github: 'TerraCycleUS/loop-client'
```

And then execute:

    $ bundle install

## Configuration

```
require 'loop_client'

LoopClient.configure do |config|
  config.logger = Logger.new(STDOUT) # or your own logger

  config.cache_store = Rails.cache
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

To install this gem onto your local machine, run `bundle exec rake install`.

GitHub releases are prepared through a reviewable Release Please pull request after the required CircleCI checks pass. Review and edit the generated changelog before merging the release pull request.

RubyGems publishing is not currently part of the release workflow. Do not run `bundle exec rake release`, because Git tags are managed by Release Please.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TerraCycleUS/loop-client.

## Secret scanning

The repository is guarded by [gitleaks](https://github.com/gitleaks/gitleaks):

- **Pre-commit hook** (`.githooks/pre-commit`) scans staged changes and blocks
  the commit when a secret is detected. `bin/setup` enables the hook; in a
  clone where it has not been run yet:

  ```sh
  brew install gitleaks
  git config core.hooksPath .githooks
  ```

- **CI hard gate**: the `secret-scan` CircleCI job runs on every branch and fails
  the pipeline on any leak in the commits that branch adds on top of `master`.

Findings that pre-date secret scanning are allowlisted by fingerprint in
`.gitleaksignore` and are tracked for rotation. Never add a fingerprint there to
silence a fresh leak — remove the secret and rotate it instead. A genuine false
positive is suppressed inline with a `gitleaks:allow` comment on the flagged line.
