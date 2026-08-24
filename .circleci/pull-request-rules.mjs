import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const JIRA_PROJECT = process.env.JIRA_PROJECT ?? 'ITG'

const KEY = `${JIRA_PROJECT}-\\d+`
const SCOPE = '(?:\\([a-z0-9][a-z0-9._/-]*\\))?!?'
const KEYS = `(?:\\[${KEY}\\])+`
const ANY_KEY = new RegExp(KEY, 'i')

const BRANCH = new RegExp(`^${JIRA_PROJECT}-\\d+-[a-z0-9]+(?:[-_][a-z0-9]+)*$`)
const BRANCH_EXEMPT = [/^master$/, /^v\d+\.\d+\.\d+$/, /^release-please--/, /^dependabot\//, /^revert-\d+-/]

const CONFIG_PATH = resolve(dirname(fileURLToPath(import.meta.url)), '../release-please-config.json')
const PLACEHOLDERS = { scope: '(?:\\([^)]+\\))?', component: '(?: \\S+)?', version: '\\d+\\.\\d+\\.\\d+' }

function allowedTypes(config) {
  if (process.env.ALLOWED_TYPES) return process.env.ALLOWED_TYPES.split(',')

  const types = (config['changelog-sections'] ?? []).map(section => section.type)
  assert.ok(types.length, `No changelog-sections in ${CONFIG_PATH}; the allowed commit types are read from there.`)
  return types
}

function exemptPattern(config) {
  if (process.env.TITLE_EXEMPT_PATTERN) return new RegExp(process.env.TITLE_EXEMPT_PATTERN)

  const pattern = config['pull-request-title-pattern']
  if (!pattern) return /$^/

  const source = pattern
    .split(/\$\{(\w+)\}/)
    .map((part, index) => (index % 2 ? PLACEHOLDERS[part] : part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')))
    .join('')
  return new RegExp(`^${source}$`)
}

export function rulesFrom(config) {
  const types = allowedTypes(config).join('|')

  return {
    title: new RegExp(`^(?:${types})${SCOPE}: ${KEYS} [a-z].+$`),
    revert: new RegExp(`^revert${SCOPE}: ${KEYS} "[^"]+"$`),
    prefix: new RegExp(`^(?:${types})${SCOPE}: (?:${KEYS} )?`),
    exempt: exemptPattern(config),
  }
}

export function loadRules() {
  return readFile(CONFIG_PATH, 'utf8').then(JSON.parse, () => ({})).then(rulesFrom)
}

export function branchErrors(branch) {
  if (BRANCH_EXEMPT.some(rule => rule.test(branch)) || BRANCH.test(branch)) return []

  return [`Name the branch after its Jira issue: ${JIRA_PROJECT}-123-short-description. ` +
    'That name is what links the branch and its pull request to the issue.']
}

export function titleErrors(title, rules) {
  if (rules.exempt.test(title)) return []

  const errors = []
  if (!rules.title.test(title) && !rules.revert.test(title)) {
    errors.push('Use type(scope): [ITG-123] lowercase summary with an allowed Conventional Commit type.')
  }
  if (ANY_KEY.test(title.replace(rules.prefix, ''))) {
    errors.push(`Put every Jira key in the prefix group: [${JIRA_PROJECT}-123][${JIRA_PROJECT}-999] summary. ` +
      'A key may not sit in the scope or inside the summary.')
  }
  return errors
}
