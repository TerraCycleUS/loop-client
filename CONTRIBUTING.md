# Contributing

## Pull request titles

Use Conventional Commit syntax for pull request titles:

```text
type(scope): [ITG-123][ITG-999] lowercase summary
```

The scope is optional. When a pull request is related to Jira, put its keys at the start of the subject, immediately after the Conventional Commit prefix, not in the scope. Wrap each Jira key in its own brackets with no separator between them. A pull request without a Jira issue may omit the Jira group.

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
- `fix`, `perf`, `maintenance`, `build`, and `revert` create a patch release.
- `!` or a `BREAKING CHANGE` footer creates a major release, even on a hidden type.
- `chore`, `ci`, `docs`, `refactor`, `style`, and `test` do not create a release by themselves and are hidden from the changelog.

Release Please pull requests use the trusted title `chore(master): prepare loop_client X.Y.Z` and do not require a Jira key.

## Merge strategy

Prefer squash merge and keep the pull request title as the squash commit subject. Review and edit the draft release pull request before merging it.
