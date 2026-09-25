---
name: steward
description: >-
  Repository rules for a Claude session that drives a pull request in
  tcg_fantasy_league through CI and review: rebase only, no merge
  commits, merge on Vinnie's lgtm with the rebase method, keep the
  Notion card Status current, and run the Curator after the merge. Read
  before you act on a CI or review event on a PR in this repository.
---

# Steward rules for tcg_fantasy_league

These rules apply to every PR in this repository that a Claude session
drives. For a ticket PR, `/kanban-automation:ticket-pipeline` has the
full detail. This file is the short form, for each CI or review event.

## Branches

- Rebase onto `main`. Never merge `main` into a branch. This repository
  has no merge commits.
- Push a rebased branch with `--force-with-lease`. Never force-push
  `main`.
- Before a rebase or a push, `git fetch origin <branch>` and compare
  `HEAD` with the fetched ref. Local `HEAD` has gone stale after a push
  in this environment.
- Squash every `fixup!` commit before you push (`bin/no-fixups`).

## Commits and PR text

- Author commits as `Vinnehboom` with the email in
  `ticket-pipeline`'s "Commit identity" section.
- Put no Claude trailer on a commit and no "Generated with" footer on a
  PR body.
- Obey the hot list in `CLAUDE.md` in every fix.

## CI

- Run `bundle exec rubocop` and the specs that cover the change before
  every push.
- `circleci.com` is not reachable from this environment. Read the
  commit status and `.circleci/config.yml`, and reproduce the failure
  locally.

## Review

- A review comment on a ticket PR starts a scoped re-entry round, per
  `ticket-pipeline` "Handling review feedback". Collect every unresolved
  thread first and handle them in one round.

## Merge

- Merge only when Vinnie wrote "lgtm" (or "looks good", "approved",
  "ship it") and CI is green on the head commit. Use
  `merge_method: "rebase"`.
- A stacked PR merges only after its base PR merged.
- After a merge: set the Notion card Status to Done, tell every other
  ticket thread with an open PR that `main` moved, then run the Curator
  (Checkpoint 3).
