# LoopClient

Ruby client gem for the Loop Integrated services API. It turns a chained method call into an HTTP request, handles Auth0 machine-to-machine authentication, caches the access token across processes, and logs every call as structured JSON.

Requires Ruby >= 4.0.

## Installation

The gem is not published to RubyGems. Add it from GitHub:

```ruby
gem 'loop_client', github: 'TerraCycleUS/loop-client'
```

Every published release is also available as a `vX.Y.Z` tag and a branch of the same name, so a deployment can be pinned to one:

```ruby
gem 'loop_client', github: 'TerraCycleUS/loop-client', tag: 'v2.0.1'
```

Then run:

```sh
bundle install
```

## Configuration

```ruby
require 'loop_client'

LoopClient.configure do |config|
  config.logger = Logger.new($stdout) # or your own logger
  config.cache_store = Rails.cache

  config.auth_url = ENV['AUTH0_URL']
  config.client_id = ENV['AUTH0_CLIENT_ID']
  config.client_secret = ENV['AUTH0_CLIENT_SECRET']

  config.add_api :TDS, url: ENV['TDS_URL'], audience: ENV['TDS_AUDIENCE']
  config.add_api :DMS, url: ENV['DMS_URL'], audience: ENV['DMS_AUDIENCE']
  config.add_api :CoMS, url: ENV['COMS_URL'], audience: ENV['COMS_AUDIENCE']
end
```

| Setting | Purpose |
| --- | --- |
| `logger` | Anything responding to `info` and `error`. Defaults to `Logger.new($stdout)`. |
| `cache_store` | Where access tokens are cached. Must respond to `read(key)` and `write(key, value, expires_at:)` — `Rails.cache` and `solid_cache` both qualify. |
| `auth_url` | Auth0 tenant URL. **Must end with a slash**: the token endpoint is built as `"#{auth_url}oauth/token"`. |
| `client_id`, `client_secret` | Auth0 machine-to-machine application credentials. |
| `add_api(key, url:, audience:)` | Registers one service. Both `url` and `audience` are required; a blank value raises `LoopClient::Error`. |

`LoopClient.reset!` clears the configuration and every memoised API object. It is meant for test suites.

## Usage

### Building a path

Chained methods and their arguments become path segments, in order:

```ruby
LoopClient[:DMS].api.v1.deposits.get        # GET  <DMS_URL>/api/v1/deposits
LoopClient[:DMS].api('v1').deposits.get     # same
LoopClient[:DMS].api('v1', 'deposits').get  # same
```

Method names are downcased, arguments are appended as-is, and the finished path is URL-escaped. The segments accumulate per thread and are cleared after every request — including one that raised — so an object returned by `LoopClient[:DMS]` can be reused and shared safely.

### Requests

```ruby
LoopClient[:DMS].api.v1.deposits.get(params: { country: 'USA' })
LoopClient[:CoMS].api.v1.containers('identity_code').freeup.put
LoopClient[:TDS].api.v1.shipments.post(body: { reference: 'ABC' }.to_json)
LoopClient[:TDS].api.v1.shipments('ABC').patch(body: { state: 'sent' }.to_json)
LoopClient[:TDS].api.v1.shipments('ABC').delete(params: { force: true })
```

`get` and `delete` take `params:`; `post`, `put` and `patch` take `body:`. Every request carries `content-type: application/json` and the bearer token.

Serialise the body yourself. There is no request-side JSON middleware, so `body:` is handed to Faraday untouched — pass a Hash and the server receives its Ruby inspect output, not JSON.

### Reading a response

The return value is the `Faraday::Response`. A JSON body is parsed into `OpenStruct`, so fields are read as methods:

```ruby
response = LoopClient[:DMS].api.v1.deposits.get

response.status                    # => 200
response.body[0].net_amount        # => 0.35
response.body[0].currency          # => 'EUR'
response.body[0].package.name      # => 'Coca-Cola 1L Glass'
response.body[0].package.sku       # => '1314254645627'
```

### Failures

An HTTP error status is **not** raised — check `response.status` yourself. `LoopClient::Error` is raised for a request the client cannot make at all: an unregistered service key, a blank `url` or `audience`, or an unsupported HTTP method. Transport and parsing failures surface as the underlying Faraday exception, logged and re-raised.

## Authentication and token caching

Each registered service gets its own token, fetched from Auth0 with the `client_credentials` grant against its audience. Tokens are cached under `LoopClient::TokenFetcher:<auth_url>:<client_id>:<audience>` and written with the JWT's own `exp` as the expiry, so every process sharing the cache store shares one token.

A token is considered spent 60 seconds before it actually expires, which keeps a request from being sent with a token that dies in flight. The `exp` claim is read by decoding the JWT without verification — the token is Auth0's to validate, not the client's.

## Logging

Every request is logged as a single JSON line:

```json
{"message":"LoopClient Request","service":"DMS","method":"GET","path":"api/v1/deposits","duration_ms":42.5,"status":200}
```

A failed request logs at `error` level with an `error` key holding the exception message instead of `status`.

## Development

```sh
bin/setup            # bundle install, and point git at .githooks
bundle exec rake     # rspec + rubocop — what CI runs
bundle exec rspec    # tests only
bin/console          # irb with the gem loaded
```

Coverage is enforced by SimpleCov at 90% of lines and 80% of branches; the suite fails below either. RuboCop inherits the shared TerraCycleUS configuration and targets Ruby 4.0.

## Releases

Releases are prepared by [Release Please](https://github.com/googleapis/release-please). Merging a change to `master` opens or updates a draft release pull request that carries the next version number, the updated `CHANGELOG.md`, `lib/loop_client/version.rb` and `Gemfile.lock`. Review and edit that pull request before merging it — merging is what publishes the tag and the GitHub Release.

Jira keys in the changelog and in the release notes are turned into links to the issue automatically.

Do not run `bundle exec rake release`: tags belong to Release Please, and the gem is not pushed to RubyGems.

CircleCI runs `build`, `secret-scan`, `release_rules` and `pr_rules` on every branch; the release job runs on `master` only.

Commit, branch and pull request rules are in [CONTRIBUTING.md](CONTRIBUTING.md).

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

## Contributing

Bug reports and pull requests are welcome at https://github.com/TerraCycleUS/loop-client.
