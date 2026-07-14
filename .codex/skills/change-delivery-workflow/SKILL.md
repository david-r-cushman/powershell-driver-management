---
name: change-delivery-workflow
description: Use when asked to perform ordinary repository changes through a consistent workflow that handles sandbox escalation, non-main branches, changelog updates, release decisions, conventional commits, ready pull requests, and post-merge cleanup without inventing repo-specific process.
---

# Change Delivery Workflow

## Overview

Use this skill for day-to-day repository maintenance and feature work that does not already belong to a more specialized workflow such as downstream cleanup, downstream guidance sync, runtime policy updates, or template release finalization.

This skill standardizes how agents should deliver ordinary changes: inspect guidance first, work from a non-main branch, capture the change in `CHANGELOG.md`, decide whether the work is release-worthy, validate with the repository's existing checks, and finish with a normal ready PR to `main`.

This workflow is intentionally guidance-oriented rather than script-driven. The controls are repository guidance, Git state, repo-specific validators, diff review, and human review.

## Why This Exists

Routine ordinary repository work was already following a repeated pattern, but that pattern was not captured in one reusable place. The result was avoidable drift in how branches, changelog entries, release decisions, PRs, and post-merge cleanup were handled.

The recurring Windows sandbox failure also needs to be treated explicitly. Errors such as `helper_sid_resolve_failed` and `LookupAccountNameW ... CodexSandboxOffline` are environment/runtime failures, not repository defects. They should trigger a scoped escalation retry for the blocked command, not a process shortcut or a speculative repository change.

## Required Context

Before acting, identify:

- the repository guidance entrypoint, normally `AGENTS.md` and `.github/copilot-instructions.md`
- the current branch and working tree state
- whether the repository already has a release/version contract such as `VERSION`, a changelog version validator, release docs, or tag conventions
- whether the requested change is ordinary maintenance, a release-worthy capability change, or post-merge cleanup

If the repo does not provide a clear versioning contract, default to a `CHANGELOG.md` update under `## Unreleased` unless the user explicitly asks to introduce release metadata.

## Preflight Workflow

Use this sequence before editing:

1. Read the repository guidance and inspect the working tree.
2. If the current branch is `main` or `master`, create and switch to a working branch before making changes.
3. Review the relevant implementation, tests, docs, and existing validators before choosing the smallest safe change.
4. Decide whether the repo already defines a release workflow that should be respected for this change.

If the task clearly matches a more specialized repo-local skill, use that skill instead of this one.

## Sandbox Recovery

When a needed command fails because of the Windows sandbox runtime, retry the blocked command with:

- `sandbox_permissions: require_escalated`
- a narrow, user-facing `justification`
- the smallest reasonable `prefix_rule`

Use this recovery path only for commands that are important to the requested work. Keep the retry scoped to the blocked command rather than broadening the task. After escalation succeeds, continue normal diff review and validation.

Do not describe sandbox failures as repository bugs unless repository code or configuration is actually responsible.

## Change Workflow

When the user wants the repository changed, use this sequence:

1. Confirm the working branch is not `main` or `master`.
2. Make the smallest change that satisfies the request.
3. Update `CHANGELOG.md` for every meaningful change.
4. Run the repository's normal validation entrypoints when they exist.
5. Inspect the diff and stage only intended files.
6. Create a Conventional Commit message that matches the actual change.
7. Push the branch and open a ready PR to `main` unless the user explicitly asks for a draft PR.

Use `## Unreleased` for ordinary maintenance notes by default.

## Release Decision

Use the repository's existing release posture instead of inventing one:

- if the repo already has `VERSION`, release validators, tag conventions, or release docs, follow them
- if the change adds a meaningful new repo capability, prepare the next release entry using the repo's established SemVer policy
- if the change is not release-worthy, keep the note under `## Unreleased`

When preparing a release-worthy change:

1. Move relevant `Unreleased` notes into the new version section.
2. Update the repo's existing version metadata together.
3. Validate the release metadata with the repo's existing checks before opening the PR.
4. After the PR is merged, follow the repo's existing post-merge tag and release process.

If the repo does not already define release metadata, stop short of inventing a new versioning system unless the user explicitly asks for that broader change.

## Post-Merge Cleanup

After a PR is merged:

1. Switch to `main`.
2. Fast-forward from `origin/main`.
3. Prune deleted remote refs.
4. Confirm the working tree is clean.
5. Delete the merged local branch only after the remote branch deletion or merge is confirmed.

If the repository has an established post-merge release step such as tag creation or GitHub Release publishing, perform it only when the repo's workflow calls for it.

## Success Criteria

The workflow is complete when:

- repository guidance was reviewed before changes were made
- edits were performed from a non-main branch
- `CHANGELOG.md` was updated appropriately
- release metadata was updated only when the repo already supported that workflow and the change justified it
- validation was run, or a clear reason was reported when it was unavailable or intentionally skipped
- the branch was pushed and a ready PR to `main` was opened when requested
- post-merge cleanup or release follow-up was handled according to the repo's existing workflow

## Stop Conditions

Stop and report instead of improvising when:

- repository guidance is missing
- the working tree is dirty in a way that conflicts with the requested change
- the repo's release/version contract is inconsistent across files or validators
- validation fails and the failure is not clearly unrelated to the requested change
- the user asks for a versioning or release process the repository does not currently define

Do not bypass branch discipline, changelog updates, or diff review just because a task appears small.

## Agent Role

Treat repository guidance, Git state, changelog history, and repo-specific validators as the source of truth. The agent role is to coordinate a repeatable delivery workflow: inspect context, recover safely from sandbox failures when needed, keep changes off `main`, capture the work in the changelog, respect repo-specific release posture, validate, prepare commits, open ready PRs, and clean up local state after merge.
