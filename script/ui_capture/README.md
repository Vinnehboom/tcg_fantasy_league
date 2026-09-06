# UI capture — this project's half

The screenshot driver lives in the `kanban-automation` plugin, in
`scripts/ui_capture/`. Its README documents the run command, the target
shape, the contact sheets, the `attach` rule, and the exit codes. Read that
one first.

This directory holds only what the driver cannot know: how to boot this app,
and how to list this app's own pages. `.claude/ui-capture.json` points at
both, and carries the sign-in surface as well.

## Run it

```sh
${CLAUDE_PLUGIN_ROOT}/scripts/ui_capture/run.sh \
  --ticket H-8 --targets tmp/ui-capture/H-8.json --out tmp/ui-capture/H-8 [--budget 600]
```

Run it from the ticket branch's own checkout. It captures whatever code is
checked out where you run it, not the branch named in `--ticket`.

## Files

- `run.sh` — a transitional shim. It forwards every argument to the plugin's
  driver. It exists because the local `.claude/skills/` copies of
  `ticket-pipeline` still name this path, and the Routines still call those
  copies. Delete it in the same pull request that deletes those copies. Set
  `UI_CAPTURE_DRIVER` to point it at a driver by hand.
- `boot.sh --ticket <id> [--dir <path>] [--stop]` — builds the app once per
  run and seeds a fresh run database directly (measured at ~12s for a cold
  `rake demo:seed` — not worth a template database's staleness risk).
  `--stop` kills the server and drops the run's database. Any failure during
  a start tears down whatever it already created, even before `--stop` is
  ever called. `--dir` sets where it keeps its state and logs; `run.sh`
  passes its own `--out` there, so both agree on one directory to erase
  afterward. Prints two lines on success: `BASE_URL=...` and
  `TEST_ENV_NUMBER=...`. `run.sh` exports the second one onward.
- `core_targets.sh` — prints this app's core surface as a JSON array: every
  GET route that renders a page, resolved straight from
  `Rails.application.routes.routes` by `UiCapture::CoreTargets` (see
  `lib/ui_capture/core_targets.rb`). A route whose controller does not
  implement that action is left out — visiting it would just 404, which is a
  fact about the app, not a capture finding. Each dynamic segment (`:game`,
  `:id`) is filled from seeded demo data, and a segment scoped to a `:game`
  already resolved for that same route only matches a record belonging to
  that game. A segment with no seeded record makes that one target drop out.
  That is expected for a page whose data the demo seed does not create yet
  (no `ScoreModifier` is seeded, so its show and edit pages drop). Every drop
  is logged by name to stderr.

## Environment notes

- Only `config/credentials/test.key` exists in this environment, so
  `RAILS_ENV=test` is the only environment that boots. `boot.sh` copies it
  from the main checkout when a dispatch worktree does not have its own copy.
- `boot.sh` symlinks `node_modules` from the main checkout when the worktree
  has none of its own. It finds that checkout through git
  (`git rev-parse --path-format=absolute --git-common-dir`'s parent),
  overridable with `UI_CAPTURE_MAIN_CHECKOUT`.
- Database credentials are never written to disk. `boot.sh` re-reads them
  from Rails credentials whenever it needs them, including in `--stop` mode.
- `TEST_ENV_NUMBER` suffixes the database name. `core_targets.sh` stops with
  a clear message when it is not set, because without it the resolution runs
  against the shared, unseeded test database and every `:game`-scoped route
  silently drops.

## Delivery

The files this run produces do not go to Notion. This session's own network
proxy denies the direct HTTPS upload `notion-create-attachment` needs, so
the Gatekeeper instead sends every entry marked `attach: true` into the
session as a chat attachment, and writes a `## Visual evidence` section on
the Notion card that names each file, its viewport, and its status.

This is **interim**. A chat attachment reaches Vinnie once, at review time,
but it does not persist anywhere a later reader can open. H-12 adds a
per-pull-request evidence page that can hold the files themselves. Video
capture is deferred to that same ticket, since its whole purpose — a durable
record — depends on a persistence chat delivery does not have.
