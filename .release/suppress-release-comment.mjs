import assert from 'node:assert/strict'
import { readFile, writeFile } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const scriptDirectory = dirname(fileURLToPath(import.meta.url))
const manifestPath = resolve(
  scriptDirectory,
  './node_modules/release-please/build/src/manifest.js',
)
const originalCall = '            await this.github.commentOnIssue(comment, pullRequest.number);'
const replacement =
  "            this.logger.info('Release pull request comment suppressed by repository policy.');"
const source = await readFile(manifestPath, 'utf8')
const occurrences = source.split(originalCall).length - 1

if (source.includes(replacement)) {
  assert.equal(occurrences, 0)
} else {
  assert.equal(occurrences, 1, 'Pinned Release Please comment hook changed; review the integration patch.')
  await writeFile(manifestPath, source.replace(originalCall, replacement))
}

const patchedSource = await readFile(manifestPath, 'utf8')
assert.doesNotMatch(patchedSource, /await this\.github\.commentOnIssue\(comment, pullRequest\.number\)/)
console.log('Release Please repository policy patch applied.')
