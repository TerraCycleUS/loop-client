const token = process.env.RELEASE_PLEASE_TOKEN
const repository = process.env.RELEASE_REPOSITORY ??
  `${process.env.CIRCLE_PROJECT_USERNAME}/${process.env.CIRCLE_PROJECT_REPONAME}`

async function api(path, options = {}) {
  const response = await fetch(`https://api.github.com/repos/${repository}${path}`, {
    ...options,
    headers: {
      Accept: 'application/vnd.github+json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  })
  return response
}

async function json(path) {
  const response = await api(path)
  if (!response.ok) throw new Error(`GitHub returned ${response.status} for ${path}`)
  return response.json()
}

const dryRun = process.argv.includes('--dry-run')

const release = await json('/releases/latest').catch(() => null)
if (!release) {
  console.log('No published release yet; no branch to create.')
  process.exit(0)
}

const tag = release.tag_name
const { sha } = await json(`/commits/${tag}`)

const existing = await api(`/git/ref/heads/${tag}`)
if (existing.ok) {
  console.log(`${tag}: branch already exists.`)
  process.exit(0)
}

if (dryRun) {
  console.log(`${tag}: would branch from ${sha.slice(0, 8)}.`)
  process.exit(0)
}

const created = await api('/git/refs', {
  method: 'POST',
  body: JSON.stringify({ ref: `refs/heads/${tag}`, sha }),
})
if (!created.ok && created.status !== 422) {
  throw new Error(`GitHub returned ${created.status} while creating branch ${tag}`)
}

console.log(`${tag}: branch created at ${sha.slice(0, 8)}.`)
