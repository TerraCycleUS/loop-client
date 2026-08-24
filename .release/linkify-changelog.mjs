import assert from 'node:assert/strict'

import { addedLines, verifyLinks, withJiraLinks } from './jira-links.mjs'

const CHANGELOG = 'CHANGELOG.md'
const MESSAGE = 'chore(master): link jira keys in the changelog'

export function releasePullRequest(pulls) {
  return pulls.find(pull => pull.head?.ref?.startsWith('release-please--')) ?? null
}

async function api(path, options = {}) {
  const response = await fetch(`https://api.github.com/repos/${repository}${path}`, {
    ...options,
    headers: {
      Accept: 'application/vnd.github+json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  })
  if (!response.ok) throw new Error(`GitHub returned ${response.status} for ${path}`)
  return response.json()
}

function selfTest() {
  verifyLinks()

  const release = { number: 42, head: { ref: 'release-please--branches--master--components--loop_client' } }
  assert.equal(releasePullRequest([]), null)
  assert.equal(releasePullRequest([{ head: { ref: 'ITG-409-link-jira-keys' } }]), null)
  assert.equal(releasePullRequest([{ head: {} }, { head: { ref: 'ITG-1-x' } }, release]), release)
}

if (process.argv.includes('--self-test')) {
  selfTest()
  console.log('Changelog linking verified.')
  process.exit(0)
}

const dryRun = process.argv.includes('--dry-run')
const token = process.env.RELEASE_PLEASE_TOKEN
const repository = process.env.RELEASE_REPOSITORY ??
  `${process.env.CIRCLE_PROJECT_USERNAME}/${process.env.CIRCLE_PROJECT_REPONAME}`

const pull = releasePullRequest(await api('/pulls?state=open&per_page=100'))
if (!pull) {
  console.log('No open release pull request; nothing to link.')
  process.exit(0)
}

const branch = pull.head.ref
const file = await api(`/contents/${CHANGELOG}?ref=${encodeURIComponent(branch)}`).catch(() => null)
if (!file) {
  console.log(`#${pull.number}: ${CHANGELOG} is missing on ${branch}; nothing to link.`)
  process.exit(0)
}

const current = Buffer.from(file.content, 'base64').toString('utf8')
const linked = withJiraLinks(current)
if (linked === current) {
  console.log(`#${pull.number}: every Jira key in ${CHANGELOG} already resolves.`)
  process.exit(0)
}

if (dryRun) {
  console.log(`#${pull.number} would rewrite ${CHANGELOG}:\n${addedLines(current, linked).join('\n')}`)
  process.exit(0)
}

await api(`/contents/${CHANGELOG}`, {
  method: 'PUT',
  body: JSON.stringify({
    branch,
    message: MESSAGE,
    sha: file.sha,
    content: Buffer.from(linked, 'utf8').toString('base64'),
  }),
})
console.log(`#${pull.number}: linked every Jira key in ${CHANGELOG}.`)
