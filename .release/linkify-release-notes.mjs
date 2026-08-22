import assert from 'node:assert/strict'

const JIRA_PROJECT = process.env.JIRA_PROJECT ?? 'ITG'
const JIRA_BROWSE_URL = process.env.JIRA_BROWSE_URL ?? 'https://terracycle.atlassian.net/browse'
const REFERENCE = new RegExp(`\\[(${JIRA_PROJECT}-\\d+)\\]`, 'g')

export function withDefinitions(body) {
  const keys = [...new Set([...body.matchAll(REFERENCE)].map(match => match[1]))]
  const missing = keys.filter(key => !body.includes(`\n[${key}]: `))
  if (!missing.length) return body

  const definitions = missing.map(key => `[${key}]: ${JIRA_BROWSE_URL}/${key}`).join('\n')
  return `${body.replace(/\s+$/, '')}\n\n${definitions}\n`
}

function selfTest() {
  const plain = '### Features\n\n* **api:** [ITG-1] add retries\n'
  assert.equal(
    withDefinitions(plain),
    '### Features\n\n* **api:** [ITG-1] add retries\n\n[ITG-1]: https://terracycle.atlassian.net/browse/ITG-1\n',
  )

  const twice = '* [ITG-1] one\n* [ITG-1] two\n* [ITG-2] three\n'
  const linked = withDefinitions(twice)
  assert.equal(linked.match(/^\[ITG-1\]: /gm).length, 1)
  assert.equal(linked.match(/^\[ITG-2\]: /gm).length, 1)

  assert.equal(withDefinitions(linked), linked)
  assert.equal(withDefinitions('* no keys here\n'), '* no keys here\n')
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

if (process.argv.includes('--self-test')) {
  selfTest()
  console.log('Release note linking verified.')
  process.exit(0)
}

const dryRun = process.argv.includes('--dry-run')
const token = process.env.RELEASE_PLEASE_TOKEN
const repository = process.env.RELEASE_REPOSITORY ??
  `${process.env.CIRCLE_PROJECT_USERNAME}/${process.env.CIRCLE_PROJECT_REPONAME}`

const release = await api('/releases/latest').catch(() => null)
if (!release) {
  console.log('No published release yet; nothing to link.')
  process.exit(0)
}

const body = withDefinitions(release.body ?? '')
if (body === release.body) {
  console.log(`${release.tag_name}: every Jira key already resolves.`)
  process.exit(0)
}

if (dryRun) {
  console.log(`${release.tag_name} would gain:\n${body.slice(release.body.length)}`)
  process.exit(0)
}

await api(`/releases/${release.id}`, { method: 'PATCH', body: JSON.stringify({ body }) })
console.log(`${release.tag_name}: linked every Jira key in the release notes.`)
