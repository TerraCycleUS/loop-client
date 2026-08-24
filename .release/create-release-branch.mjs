import { json, optionalJson, request, requireToken } from './github.mjs'

requireToken()

const dryRun = process.argv.includes('--dry-run')

const release = await optionalJson('/releases/latest')
if (!release) {
  console.log('No published release yet; no branch to create.')
  process.exit(0)
}

const tag = release.tag_name
const { sha } = await json(`/commits/${tag}`)

const existing = await request(`/git/ref/heads/${tag}`)
if (existing.ok) {
  console.log(`${tag}: branch already exists.`)
  process.exit(0)
}

if (dryRun) {
  console.log(`${tag}: would branch from ${sha.slice(0, 8)}.`)
  process.exit(0)
}

const created = await request('/git/refs', {
  method: 'POST',
  body: JSON.stringify({ ref: `refs/heads/${tag}`, sha }),
})
if (!created.ok && created.status !== 422) {
  throw new Error(`GitHub returned ${created.status} while creating branch ${tag}`)
}

console.log(`${tag}: branch created at ${sha.slice(0, 8)}.`)
