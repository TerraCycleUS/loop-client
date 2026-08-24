# Contributing

## Pull request titles

Use Conventional Commit syntax for pull request titles:

```text
type(scope): [ITG-123][ITG-999] lowercase summary
```

The scope is optional. Jira keys go at the start of the subject, immediately after the Conventional Commit prefix, never in the scope. Wrap each key in its own brackets with no separator between them. CI rejects a title without a key; the only exception is the release pull request Release Please opens for itself.

Examples:

```text
feat(api): [ITG-123] add request retries
fix(cache): [ITG-123][ITG-999] preserve token expiry
maintenance(deps): [ITG-123] update dependencies
revert: [ITG-123] "feat(api): add request retries"
```

Allowed types are `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `maintenance`, `perf`, `refactor`, `revert`, `style`, and `test`. CI reads that list from the `changelog-sections` of `release-please-config.json`, so a type added there is accepted without touching the checks.

Release impact:

- `feat` creates a minor release.
- every other type creates a patch release.
- `!` or a `BREAKING CHANGE` footer creates a major release.

No type is hidden: each has its own changelog section, so whatever you merge shows up in the release notes.

Release Please pull requests use the trusted title `chore(master): prepare X.Y.Z` and do not require a Jira key.

Editing a title does not reliably start a new CircleCI pipeline, so the check keeps the verdict it reached on the old one. Push something, or rerun the workflow, after renaming a pull request.

## Branch names

Name a branch after its Jira issue:

```text
ITG-123-short-description
```

That name is what links the branch and its pull request to the issue, and CI rejects anything else. Branches nobody types by hand are exempt: `master`, the `vX.Y.Z` branches cut for each release, the `release-please--*` branches, `dependabot/*`, and the `revert-<number>-*` branches GitHub creates.

A merged branch is deleted automatically. Every published release also gets a branch named after its tag, so a release can be picked from Heroku's branch list.

## Jira links

Every Jira key in the release notes and in `CHANGELOG.md` resolves to `https://terracycle.atlassian.net/browse/<key>`. CI adds the Markdown link definitions after each release: to the published GitHub Release body, and to `CHANGELOG.md` on the open release pull request branch, so they land with the release commit.

A key written any other way — `(ITG-123)`, or bare in the summary — is rewritten to `[ITG-123]` first, so older entries resolve too.

The definitions sit at the bottom of `CHANGELOG.md` and cover the whole file. Leave them there — Release Please prepends each new section and never rewrites the tail.

## Merge strategy

Prefer squash merge and keep the pull request title as the squash commit subject. Review and edit the draft release pull request before merging it; merging it publishes the tag and the GitHub Release.

GitHub Release notes are read from the merged release pull request body, not from `CHANGELOG.md`. Correcting the changelog alone leaves the published notes wrong, so edit both and keep the structural markers in the body intact. For a durable note, add a `BEGIN_COMMIT_OVERRIDE` block to the source pull request body before that pull request is merged.

Never move or delete a published `vX.Y.Z` tag. Correct a mistake with another release.
