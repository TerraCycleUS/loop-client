const token = process.env.RELEASE_PLEASE_TOKEN
const repository = process.env.RELEASE_REPOSITORY ??
  `${process.env.CIRCLE_PROJECT_USERNAME}/${process.env.CIRCLE_PROJECT_REPONAME}`

export function request(path, options = {}) {
  return fetch(`https://api.github.com/repos/${repository}${path}`, {
    ...options,
    headers: {
      Accept: 'application/vnd.github+json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  })
}

export async function json(path, options = {}) {
  const response = await request(path, options)
  if (!response.ok) throw new Error(`GitHub returned ${response.status} for ${path}`)
  return response.json()
}

// A missing or unauthorised token must not read as "nothing published yet", which is
// what every caller would conclude from the 404 GitHub answers.
export function requireToken() {
  if (!token) throw new Error('RELEASE_PLEASE_TOKEN is not set.')
}

export async function optionalJson(path, options = {}) {
  const response = await request(path, options)
  if (response.status === 404) return null
  if (!response.ok) throw new Error(`GitHub returned ${response.status} for ${path}`)
  return response.json()
}

export function releasePullRequest(pulls) {
  return pulls.find(pull => pull.head?.ref?.startsWith('release-please--')) ?? null
}
