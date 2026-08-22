import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const JIRA_PROJECT = process.env.JIRA_PROJECT ?? 'ITG'
const ALLOWED_TYPES = (process.env.ALLOWED_TYPES ?? 'build,chore,ci,docs,feat,fix,maintenance,perf,refactor,revert,style,test').split(',')

const KEY = `${JIRA_PROJECT}-\\d+`
const SCOPE = '(?:\\([a-z0-9][a-z0-9._/-]*\\))?!?'
const KEYS = `(?:\\[${KEY}\\])+`
const TITLE = new RegExp(`^(?:${ALLOWED_TYPES.join('|')})${SCOPE}: ${KEYS} [a-z].+$`)
const REVERT = new RegExp(`^revert${SCOPE}: ${KEYS} "[^"]+"$`)
const PREFIX = new RegExp(`^(?:${ALLOWED_TYPES.join('|')})${SCOPE}: (?:${KEYS} )?`)
const ANY_KEY = new RegExp(KEY, 'i')

const BRANCH = new RegExp(`^${JIRA_PROJECT}-\\d+-[a-z0-9]+(?:[-_][a-z0-9]+)*$`)
const BRANCH_EXEMPT = [/^master$/, /^v\d+\.\d+\.\d+$/, /^release-please--/, /^dependabot\//, /^revert-\d+-/]

const PLACEHOLDERS = { scope: '(?:\\([^)]+\\))?', component: '(?: \\S+)?', version: '\\d+\\.\\d+\\.\\d+' }

async function releaseTitlePattern() {
  if (process.env.TITLE_EXEMPT_PATTERN) return new RegExp(process.env.TITLE_EXEMPT_PATTERN)

  const path = resolve(dirname(fileURLToPath(import.meta.url)), '../release-please-config.json')
  const config = await readFile(path, 'utf8').then(JSON.parse, () => ({}))
  const pattern = config['pull-request-title-pattern']
  if (!pattern) return /$^/

  const source = pattern
    .split(/\$\{(\w+)\}/)
    .map((part, index) => (index % 2 ? PLACEHOLDERS[part] : part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')))
    .join('')
  return new RegExp(`^${source}$`)
}

export function branchErrors(branch) {
  if (BRANCH_EXEMPT.some(rule => rule.test(branch)) || BRANCH.test(branch)) return []

  return [`Name the branch after its Jira issue: ${JIRA_PROJECT}-123-short-description. ` +
    'That name is what links the branch and its pull request to the issue.']
}

export function titleErrors(title, exempt) {
  if (exempt.test(title)) return []

  const errors = []
  if (!TITLE.test(title) && !REVERT.test(title)) {
    errors.push('Use type(scope): [ITG-123] lowercase summary with an allowed Conventional Commit type.')
  }
  if (ANY_KEY.test(title.replace(PREFIX, ''))) {
    errors.push(`Put every Jira key in the prefix group: [${JIRA_PROJECT}-123][${JIRA_PROJECT}-999] summary. ` +
      'A key may not sit in the scope or inside the summary.')
  }
  return errors
}

function selfTest(exempt) {
  const accept = title => assert.deepEqual(titleErrors(title, exempt), [], `should accept: ${title}`)
  const reject = title => assert.notEqual(titleErrors(title, exempt).length, 0, `should reject: ${title}`)

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
}

async function pullRequestTitle() {
  if (process.env.PR_TITLE) return process.env.PR_TITLE

  const urls = process.env.CIRCLE_PULL_REQUEST || process.env.CIRCLE_PULL_REQUESTS || ''
  const number = urls.split(',')[0]?.split('/').pop()
  if (!number) return null

  const repository = `${process.env.CIRCLE_PROJECT_USERNAME}/${process.env.CIRCLE_PROJECT_REPONAME}`
  const response = await fetch(`https://api.github.com/repos/${repository}/pulls/${number}`, {
    headers: { Accept: 'application/vnd.github+json' },
  })
  if (response.status === 403 && response.headers.get('x-ratelimit-remaining') === '0') {
    throw new Error('GitHub rejected the unauthenticated request: rate limit reached for this CircleCI IP. Rerun the job.')
  }
  if (!response.ok) throw new Error(`GitHub returned ${response.status} while reading pull request ${number}`)
  return (await response.json()).title
}

const exempt = await releaseTitlePattern()

if (process.argv.includes('--self-test')) {
  selfTest(exempt)
  console.log('Pull request rules verified.')
  process.exit(0)
}

const failures = []

const branch = process.env.CIRCLE_BRANCH
if (branch) {
  failures.push(...branchErrors(branch).map(error => `${branch}: ${error}`))
  if (!failures.length) console.log(`Branch name is valid: ${branch}`)
} else {
  console.log('No branch context detected; branch validation skipped.')
}

const title = await pullRequestTitle()
if (title) {
  failures.push(...titleErrors(title, exempt).map(error => `${title}: ${error}`))
} else {
  console.log('No pull request context detected; title validation skipped.')
}

if (failures.length) {
  console.error(failures.map(failure => `- ${failure}`).join('\n'))
  process.exit(1)
}

if (title) console.log(`Pull request title is valid: ${title}`)
