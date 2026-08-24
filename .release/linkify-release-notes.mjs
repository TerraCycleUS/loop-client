import { verifyDefinitions, withDefinitions } from './jira-links.mjs'

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
  verifyDefinitions()
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
