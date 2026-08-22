import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'

import { DefaultChangelogNotes } from '../.release/node_modules/release-please/build/src/changelog-notes/default.js'
import { parseConventionalCommits } from '../.release/node_modules/release-please/build/src/commit.js'
import { buildStrategy } from '../.release/node_modules/release-please/build/src/factory.js'
import { Manifest } from '../.release/node_modules/release-please/build/src/manifest.js'
import { GemfileLock } from '../.release/node_modules/release-please/build/src/updaters/ruby/gemfile-lock.js'
import { VersionRB } from '../.release/node_modules/release-please/build/src/updaters/ruby/version-rb.js'
import { PullRequestTitle } from '../.release/node_modules/release-please/build/src/util/pull-request-title.js'
import { Version } from '../.release/node_modules/release-please/build/src/version.js'
import { DefaultVersioningStrategy } from '../.release/node_modules/release-please/build/src/versioning-strategies/default.js'

const config = JSON.parse(await readFile('release-please-config.json', 'utf8'))
const manifestVersions = JSON.parse(await readFile('.release-please-manifest.json', 'utf8'))
const versionSource = await readFile('lib/loop_client/version.rb', 'utf8')
const gemfileLock = await readFile('Gemfile.lock', 'utf8')
const currentVersion = Version.parse(manifestVersions['.'])
const expectedPatchVersion = new Version(
  currentVersion.major,
  currentVersion.minor,
  currentVersion.patch + 1,
)
const expectedMinorVersion = new Version(currentVersion.major, currentVersion.minor + 1, 0)
const expectedMajorVersion = new Version(currentVersion.major + 1, 0, 0)
const versioning = new DefaultVersioningStrategy()
const changelog = new DefaultChangelogNotes()

const manifest = await Manifest.fromManifest(
  {
    getFileJson: async path => {
      if (path === 'release-please-config.json') return config
      if (path === '.release-please-manifest.json') return manifestVersions
      throw new Error(`Unexpected manifest path: ${path}`)
    },
    repository: { owner: 'TerraCycleUS', repo: 'loop-client' },
  },
  'master',
)

assert.equal(manifest.repositoryConfig['.'].releaseType, 'ruby')

const packageConfig = manifest.repositoryConfig['.']
const strategy = await buildStrategy({
  github: { repository: { owner: 'TerraCycleUS', repo: 'loop-client' } },
  releaseType: packageConfig.releaseType,
  targetBranch: 'master',
  packageName: packageConfig.packageName,
  includeComponentInTag: packageConfig.includeComponentInTag,
})
const updates = await strategy.buildUpdates({
  changelogEntry: '',
  newVersion: expectedPatchVersion,
  versionsMap: new Map(),
  latestVersion: currentVersion,
  commits: [],
})

assert.equal(await strategy.getComponent(), '')
assert.deepEqual(updates.map(update => update.path), [
  'CHANGELOG.md',
  'lib/loop_client/version.rb',
  'Gemfile.lock',
])
assert.equal(manifest.releasedVersions['.'].toString(), currentVersion.toString())
assert.match(versionSource, new RegExp(`VERSION = ['\"]${currentVersion.toString()}['\"]`))
assert.match(gemfileLock, new RegExp(`loop_client \\(${currentVersion.toString()}\\)`))

const releaseTitle = PullRequestTitle.ofComponentTargetBranchVersion(
  await strategy.getComponent(),
  'master',
  expectedPatchVersion,
  config['pull-request-title-pattern'],
).toString()
assert.equal(releaseTitle, `chore(master): prepare ${expectedPatchVersion.toString()}`)
assert.ok(PullRequestTitle.parse(releaseTitle, config['pull-request-title-pattern']))

let fixtureIndex = 0

function commit(message) {
  fixtureIndex += 1
  const commits = parseConventionalCommits([
    {
      message,
      sha: fixtureIndex.toString().padStart(40, '0'),
    },
  ])

  assert.equal(commits.length, 1, `Expected one parsed commit for: ${message}`)
  return commits[0]
}

async function notesFor(commits, version) {
  return changelog.buildNotes(commits, {
    changelogSections: config['changelog-sections'],
    currentTag: `v${version}`,
    host: 'https://github.com',
    owner: 'TerraCycleUS',
    repository: 'loop-client',
    targetBranch: 'master',
    version,
  })
}

const maintenance = commit('maintenance(deps): (ITG-123, ITG-999) update dependencies')
const maintenanceVersion = versioning.bump(currentVersion, [maintenance])
const maintenanceNotes = await notesFor([maintenance], maintenanceVersion.toString())

assert.equal(maintenance.type, 'maintenance')
assert.equal(maintenance.scope, 'deps')
assert.equal(maintenanceVersion.toString(), expectedPatchVersion.toString())
assert.match(maintenanceNotes, /Maintenance/)
assert.match(maintenanceNotes, /ITG-123, ITG-999/)

const feature = commit('feat(api): (ITG-123) add request retries')
assert.equal(versioning.bump(currentVersion, [feature]).toString(), expectedMinorVersion.toString())

const fix = commit('fix(api): (ITG-123) preserve response metadata')
assert.equal(versioning.bump(currentVersion, [fix]).toString(), expectedPatchVersion.toString())

const breaking = commit('fix(api)!: (ITG-123) replace the response contract')
assert.equal(breaking.breaking, true)
assert.equal(versioning.bump(currentVersion, [breaking]).toString(), expectedMajorVersion.toString())

const choreNotes = await notesFor(
  [commit('chore(tooling): (ITG-123) refresh development dependencies')],
  expectedPatchVersion.toString(),
)
assert.equal(choreNotes.split('\n').length, 1)
assert.doesNotMatch(choreNotes, /Chores/)

const build = commit('build(deps): [ITG-376] update gems')
const buildNotes = await notesFor([build], expectedPatchVersion.toString())

assert.equal(versioning.bump(currentVersion, [build]).toString(), expectedPatchVersion.toString())
assert.match(buildNotes, /Build System/)

const updatedVersionSource = new VersionRB({ version: expectedPatchVersion }).updateContent(versionSource)
const updatedGemfileLock = new GemfileLock({
  gemName: 'loop_client',
  version: expectedPatchVersion,
}).updateContent(gemfileLock)

assert.match(updatedVersionSource, new RegExp(`VERSION = ['\"]${expectedPatchVersion.toString()}['\"]`))
assert.match(updatedGemfileLock, new RegExp(`loop_client \\(${expectedPatchVersion.toString()}\\)`))

console.log(
  'Release rules verified: maintenance and build=patch, feat=minor, breaking=major, hidden types=no release pull request.',
)
console.log('Ruby updates verified: version.rb and Gemfile.lock use the same release version.')
console.log('\nMaintenance fixture preview:\n')
console.log(maintenanceNotes)
