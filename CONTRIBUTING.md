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

Allowed types are `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `maintenance`, `perf`, `refactor`, `revert`, `style`, and `test`.

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

## Merge strategy

Prefer squash merge and keep the pull request title as the squash commit subject. Review and edit the draft release pull request before merging it; merging it publishes the tag and the GitHub Release.

GitHub Release notes are read from the merged release pull request body, not from `CHANGELOG.md`. Correcting the changelog alone leaves the published notes wrong, so edit both and keep the structural markers in the body intact. For a durable note, add a `BEGIN_COMMIT_OVERRIDE` block to the source pull request body before that pull request is merged.

Never move or delete a published `vX.Y.Z` tag. Correct a mistake with another release.
