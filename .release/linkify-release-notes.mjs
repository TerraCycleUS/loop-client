import { json, optionalJson, requireToken } from './github.mjs'
import { addedLines, withJiraLinks } from './jira-links.mjs'

requireToken()

const dryRun = process.argv.includes('--dry-run')

const release = await optionalJson('/releases/latest')
if (!release) {
  console.log('No published release yet; nothing to link.')
  process.exit(0)
}

const body = withJiraLinks(release.body ?? '')
if (body === release.body) {
  console.log(`${release.tag_name}: every Jira key already resolves.`)
  process.exit(0)
}

if (dryRun) {
  console.log(`${release.tag_name} would gain:\n${addedLines(release.body ?? '', body).join('\n')}`)
  process.exit(0)
}

await json(`/releases/${release.id}`, { method: 'PATCH', body: JSON.stringify({ body }) })
console.log(`${release.tag_name}: linked every Jira key in the release notes.`)
