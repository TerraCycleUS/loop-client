import assert from 'node:assert/strict'

const JIRA_PROJECT = process.env.JIRA_PROJECT ?? 'ITG'
const JIRA_BROWSE_URL = process.env.JIRA_BROWSE_URL ?? 'https://terracycle.atlassian.net/browse'
const REFERENCE = new RegExp(`\\[(${JIRA_PROJECT}-\\d+)\\]`, 'g')
const TRAILING_DEFINITION = new RegExp(`\\n\\[${JIRA_PROJECT}-\\d+\\]: \\S+$`)

export function withDefinitions(body) {
  const keys = [...new Set([...body.matchAll(REFERENCE)].map(match => match[1]))]
  const missing = keys.filter(key => !body.includes(`\n[${key}]: `))
  if (!missing.length) return body

  const trimmed = body.replace(/\s+$/, '')
  const definitions = missing.map(key => `[${key}]: ${JIRA_BROWSE_URL}/${key}`).join('\n')
  return `${trimmed}${TRAILING_DEFINITION.test(trimmed) ? '\n' : '\n\n'}${definitions}\n`
}

export function verifyDefinitions() {
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

  const changelog = '# Changelog\n\n## [1.0.1](https://example.test/compare) (2026-08-22)\n\n' +
    '### Bug Fixes\n\n* **api:** [ITG-1] preserve token expiry\n\n[ITG-2]: https://terracycle.atlassian.net/browse/ITG-2\n'
  const appended = withDefinitions(changelog)
  assert.ok(appended.startsWith('# Changelog\n'))
  assert.equal(appended.match(/^\[ITG-1\]: /gm).length, 1)
  assert.equal(appended.match(/^\[ITG-2\]: /gm).length, 1)
  assert.equal(withDefinitions(appended), appended)

  const partly = '* [ITG-1] one\n* [ITG-2] two\n\n[ITG-1]: https://terracycle.atlassian.net/browse/ITG-1\n'
  const grown = withDefinitions(partly)
  assert.ok(grown.endsWith('[ITG-1]: https://terracycle.atlassian.net/browse/ITG-1\n' +
    '[ITG-2]: https://terracycle.atlassian.net/browse/ITG-2\n'))
  assert.doesNotMatch(grown, /\n\n\[ITG-2\]: /)
}
