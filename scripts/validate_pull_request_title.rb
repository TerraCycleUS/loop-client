# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module PullRequestTitleValidator
  ALLOWED_TYPES = %w[build chore ci docs feat fix maintenance perf refactor revert style test].freeze
  SCOPE = '(?:\([a-z0-9][a-z0-9._/-]*\))?!?'
  CONVENTIONAL_PATTERN = /\A(?:#{ALLOWED_TYPES.join('|')})#{SCOPE}: [a-z].+\z/
  REVERT_PATTERN = /\Arevert#{SCOPE}: "[^"]+"\z/
  JIRA_PREFIX_PATTERN = /\A(?:\[ITG-\d+\])+ /
  JIRA_KEY_PATTERN = /ITG-\d+/i

  module_function

  def errors(title:)
    conventional_prefix, subject = title.split(': ', 2)
    jira_prefix = subject&.[](JIRA_PREFIX_PATTERN)
    base_subject = jira_prefix ? subject.delete_prefix(jira_prefix) : subject
    base_title = [conventional_prefix, base_subject].compact.join(': ')
    validation_errors = []

    unless base_title.match?(CONVENTIONAL_PATTERN) || base_title.match?(REVERT_PATTERN)
      validation_errors << 'Use type(scope): lowercase summary with an allowed Conventional Commit type.'
    end

    if base_title.match?(JIRA_KEY_PATTERN)
      validation_errors << 'Place Jira keys at the start of the subject: [ITG-123][ITG-999] summary. ' \
                           'Do not use Jira keys as the scope.'
    end

    validation_errors
  end

  def validate!(title:)
    validation_errors = errors(title: title)
    return if validation_errors.empty?

    raise ArgumentError, "Invalid pull request title: #{title}\n- #{validation_errors.join("\n- ")}"
  end

  def pull_request_number
    pull_request_url = ENV.fetch('CIRCLE_PULL_REQUEST', '').split(',').first.to_s
    return pull_request_url.split('/').last unless pull_request_url.empty?

    pull_request_urls = ENV.fetch('CIRCLE_PULL_REQUESTS', '').split(',')
    pull_request_urls.first.to_s.split('/').last unless pull_request_urls.empty?
  end

  def fetch_title(repository:, pull_request_number:)
    uri = URI.parse("https://api.github.com/repos/#{repository}/pulls/#{pull_request_number}")
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/vnd.github+json'
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

    return JSON.parse(response.body).fetch('title') if response.is_a?(Net::HTTPSuccess)

    raise read_error(response: response, pull_request_number: pull_request_number)
  end

  def read_error(response:, pull_request_number:)
    if response.is_a?(Net::HTTPForbidden) && response['x-ratelimit-remaining'] == '0'
      return 'GitHub rejected the unauthenticated request: rate limit reached for this CircleCI IP. Rerun the job.'
    end

    "GitHub returned #{response.code} while reading pull request #{pull_request_number}"
  end

  def self_test!
    valid_titles = [
      'maintenance(deps): [ITG-123][ITG-999] update dependencies',
      'feat(api): [ITG-123] add request retries',
      'fix(api)!: [ITG-123] replace the response contract',
      'revert: [ITG-123] "feat(api): add request retries"',
      'revert(api): "feat(api): add request retries"',
      'chore(master): prepare 1.0.1'
    ]
    invalid_titles = [
      'feat(ITG-123,ITG-999): add request retries',
      'feat(itg-123): add request retries',
      'maintenance(deps): [ITG-123] Update dependencies',
      'change(api): [ITG-123] update the response',
      'fix(api): correct the response (ITG-123, ITG-999)',
      'fix(api): [ITG-123, ITG-999] correct the response',
      'fix(api): [ITG-123] [ITG-999] correct the response',
      'fix(api): (ITG-123) correct the response',
      'Revert "feat(api): add request retries"'
    ]

    valid_titles.each { |title| validate!(title: title) }
    invalid_titles.each do |title|
      raise "Expected invalid title to fail: #{title}" if errors(title: title).empty?
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.include?('--self-test')
    PullRequestTitleValidator.self_test!
    puts 'Pull request title rules verified.'
    exit 0
  end

  title = ENV.fetch('PR_TITLE', nil)
  pull_request_number = PullRequestTitleValidator.pull_request_number

  if title.nil? && pull_request_number
    repository = "#{ENV.fetch('CIRCLE_PROJECT_USERNAME')}/#{ENV.fetch('CIRCLE_PROJECT_REPONAME')}"
    title = PullRequestTitleValidator.fetch_title(
      repository: repository,
      pull_request_number: pull_request_number
    )
  end

  if title.nil?
    puts 'No pull request context detected; title validation skipped.'
    exit 0
  end

  PullRequestTitleValidator.validate!(title: title)
  puts "Pull request title is valid: #{title}"
end
