import assert from 'node:assert/strict'

import { branchErrors, loadRules, titleErrors } from './pull-request-rules.mjs'

const rules = await loadRules()

const accept = title => assert.deepEqual(titleErrors(title, rules), [], `should accept: ${title}`)
const reject = title => assert.notEqual(titleErrors(title, rules).length, 0, `should reject: ${title}`)

accept('maintenance(deps): [ITG-123][ITG-999] update dependencies')
accept('feat(api): [ITG-123] add request retries')
accept('fix(api)!: [ITG-123] replace the response contract')
accept('revert: [ITG-123] "feat(api): add request retries"')
accept('chore(master): prepare 1.0.1')
accept('chore(master): prepare loop_client 2.10.0')
reject('feat(ITG-123,ITG-999): add request retries')
reject('feat(itg-123): add request retries')
reject('maintenance(deps): [ITG-123] Update dependencies')
reject('change(api): [ITG-123] update the response')
reject('fix(api): correct the response (ITG-123, ITG-999)')
reject('fix(api): [ITG-123, ITG-999] correct the response')
reject('fix(api): [ITG-123] [ITG-999] correct the response')
reject('fix(api): (ITG-123) correct the response')
reject('fix(api): [ITG-123] correct the ITG-999 response')
reject('Revert "feat(api): add request retries"')
reject('feat(api): add request retries')
reject('chore(master): prepare')

for (const branch of ['ITG-123-add-request-retries', 'ITG-1-fix', 'master', 'v1.0.2', 'v10.20.30',
  'release-please--branches--master--components--loop_client',
  'dependabot/bundler/rack-3.1.0', 'revert-8-maintenance/release-please-circleci']) {
  assert.deepEqual(branchErrors(branch), [], `should accept branch: ${branch}`)
}
for (const branch of ['maintenance/release-please-circleci', 'itg-123-add-retries', 'ITG123-add-retries',
  'ITG-123', 'ITG-123-Add-Retries', 'add-retries', 'feature/ITG-123-add-retries']) {
  assert.notEqual(branchErrors(branch).length, 0, `should reject branch: ${branch}`)
}

console.log('Pull request rules verified.')
