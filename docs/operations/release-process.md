# Release process

## Overview

Release Please prepares a draft pull request containing the next version, `CHANGELOG.md`, `lib/loop_client/version.rb`, and `Gemfile.lock`. The release pull request is the approval point. Review the changelog after the release scope is frozen. A later Release Please update can regenerate the branch, so make final manual edits immediately before merge.

For durable custom notes, add a `BEGIN_COMMIT_OVERRIDE` block to the source pull request body before that source pull request is merged. If a final correction is made directly in the release pull request, update both `CHANGELOG.md` and the matching notes section in the pull request body while preserving its structural markers. GitHub Release notes are read from the merged release pull request body, not from `CHANGELOG.md`.

After the release pull request is merged and the `master` checks pass again, the next CircleCI run creates the immutable `vX.Y.Z` tag and GitHub Release. It then prepares the next release pull request when new release-visible changes exist.

RubyGems publishing is intentionally out of scope. The repository does not currently have a published `loop_client` package or confirmed publishing credentials.

## Release rules

- `feat` increments the minor version.
- `fix`, `perf`, `maintenance`, `build`, and `revert` increment the patch version.
- `!` or a `BREAKING CHANGE` footer increments the major version.
- `chore`, `ci`, `docs`, `refactor`, `style`, and `test` do not create a release by themselves and are hidden from the changelog.

## CircleCI credential

The release job requires `RELEASE_PLEASE_TOKEN` from the `loop-client-release-please` CircleCI context and fails closed when it is unavailable.

For the initial implementation, use an expiring fine-grained service-account token restricted to this repository. Required permissions are:

- Metadata: read
- Contents: read and write
- Pull requests: read and write
- Issues: read and write

Store the credential in the restricted `loop-client-release-please` CircleCI context, which is attached only to the `release_please` job. Do not expose it to pull request jobs or use a broader fallback token.

A future GitHub App integration should store the App ID, installation ID, and private key, then mint a short-lived installation token inside each job. Do not store a short-lived installation token as a static CircleCI value.

The release job must run only on `master`, after `build`, `release_rules`, and `title_rules`, and remain serialized. It always runs `github-release` before `release-pr` so a merged release pull request is published before the next proposal is prepared.

Release Please is pinned to `17.11.1`. Its installation applies a deterministic repository-policy patch that suppresses the default release pull request comment while preserving tag, GitHub Release, and label handling. Installation fails if the pinned integration point changes, requiring an explicit review before upgrading.

## CircleCI trigger limitation

Use the CircleCI GitHub App trigger preset **PR opened or pushed to, default branch and tag pushes**. The title validator reads the current pull request title through the GitHub API when CircleCI supplies pull request context.

A title-only edit does not reliably start a new CircleCI pipeline. Rerun the title check after editing a title, and preserve the validated title as the squash commit subject. Strict organization-wide enforcement requires a merge queue or an additional webhook-backed status check.

## Baseline

The automation starts from `v1.0.0` at `f3fcfdf4279260a44cdd93606c6805370c010677`. `master` carries a
release-visible `fix` after that tag, so the first candidate is `v1.0.1` and its notes open with that fix.
`bootstrap-sha` only applies while no release has been found; the published `v1.0.0` release means it never
takes effect, and it stays as a bound on history scanning if that release ever goes missing.

Never move or delete an existing `vX.Y.Z` tag. Correct release mistakes with a new patch release.
