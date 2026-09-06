# UI capture

This directory boots the app, drives headless Chromium over it, and
produces screenshots for a pull request. The Gatekeeper phase of the
ticket pipeline runs it before a PR goes to review, then sends the
resulting files into the session as chat attachments — see "Delivery"
below. Always run it from the ticket branch's own checkout — it captures
whatever code is checked out where you run it, not the branch named in
`--ticket`.

Video capture (a short recording of a multi-step flow) is deferred to
the evidence-page ticket that replaces chat delivery — see "Delivery"
below for why.

## Run it

```sh
script/ui_capture/run.sh --ticket H-8 --targets tmp/ui-capture/H-8.json --out tmp/ui-capture/H-8 [--budget 600]
```

`--targets` points at the ticket's Capture plan: the JSON file the
orchestrator writes from the plan's `## Capture plan` section (see
`example.json` for the shape). `run.sh` adds the app's core surface to
this list itself, from `UiCapture::CoreTargets`, then runs the capture.
`--budget` is a wall-clock limit in seconds; it defaults to 600 (10
minutes) and falls back to that default if it isn't a positive whole
number.

On exit, `<out>/result.json` lists every captured target: its name, kind,
viewport, file path, byte count, whether the Gatekeeper should attach it
on its own (see "Contact sheets" below), and the HTTP status of the page.
Read `exit_code` and `message` for the overall outcome (see "Exit codes"
below).

## What gets captured

- **The core surface**: every GET route that renders a page, resolved
  straight from `Rails.application.routes.routes` by
  `UiCapture::CoreTargets` (see `lib/ui_capture/core_targets.rb`). A
  route whose controller doesn't implement that action (`config/routes.rb`
  declares full `resources` blocks against controllers that only handle
  part of them) is left out — visiting it would just 404, which is a fact
  about the app, not something for this run to report as a capture
  finding. Each dynamic segment (`:game`, `:id`) is filled from seeded
  demo data, and a segment scoped to a `:game` already resolved for that
  same route only matches a record belonging to that game. A segment with
  no seeded record makes that one target drop out; that is expected for a
  page whose data the demo seed does not create yet (for example, no
  `ScoreModifier` is seeded, so its show/edit pages drop). Every drop is
  logged by name.
- **The ticket's own targets**: the Capture plan the planner proposed
  and the developer amended, in `## Capture plan` on the ticket — a page
  worth a close-up, nothing more. A target here whose `path` matches a
  core target replaces it, so a ticket can single out a page the core
  surface would otherwise fold into its contact sheet.

Every target is captured at two viewports: desktop (1440x900) and
mobile (390x844, `deviceScaleFactor: 3`, so the mobile PNG comes out at
1170x2532) — one screenshot each.

Every `signed_out` target (the landing page, sign in, sign up) is
captured before the run signs in as the demo admin account. Everything
else is captured signed in. A page that quietly bounces to the sign-in
page instead of rendering — the session didn't actually establish —
records as a tooling failure (`status: null`, with an `error`), never as
a false 200.

## Capture plan target shape

```json
{ "ticket": "H-8",
  "targets": [
    { "name": "score-modifiers-index", "kind": "still", "path": "/admin/score_modifiers" } ] }
```

A target is a page, nothing more: a `name`, `kind` (currently always
`"still"`), a `path`, and optionally `signed_out: true`. See
`example.json`.

## Contact sheets

The core surface alone is around 25 pages at two viewports. Rather than
attach each one at full size, `capture.mjs` lays every core still that
answered `200` into one grid per viewport (`contact-sheet.png`) with a
caption naming the page and its status, and marks those stills
`"attach": false` in the manifest. That keeps the evidence reviewable in
one image instead of fifty.

Everything else is marked `"attach": true` and gets its own full-size
file:

- Every ticket target, since that is the change under review.
- Any core page whose status is not `200`, or that failed outright
  (`status: null` with an `error`), since a broken or unreadable page is
  worth seeing on its own, not lost in a grid.
- Each contact sheet itself.

An entry with no `file` (capture never produced anything to send) is
always `"attach": false`. The Gatekeeper's own delivery step reads this
field directly — send every entry whose `attach` is true and whose
`file` is not null — rather than sending everything the manifest lists.

## Delivery

The files this run produces do not go to Notion. This session's own
network proxy denies the direct HTTPS upload `notion-create-attachment`
needs, so the Gatekeeper instead sends every entry marked `attach: true`
into the session as a chat attachment, and writes a `## Visual evidence`
section on the Notion card that names each file, its viewport, and its
status — the record, not the files.

This is **interim**. A chat attachment reaches Vinnie once, at review
time, but it does not persist anywhere a later reader can open. A
follow-up ticket is expected to add a per-pull-request evidence page
that can hold the files themselves; video capture (a recording of a
multi-step flow, not just a page) is deferred to that same ticket, since
its whole purpose — a durable record to compare against once I-1 lands —
depends on a persistence chat delivery does not have.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success. |
| 1 | Usage error (bad arguments, a targets file that is not valid JSON). |
| 2 | The app did not boot. |
| 3 | The capture itself failed (Chromium would not launch, a script error). |
| 4 | The run did not finish inside its budget. |

A non-zero exit code here is a **capture failure**, and a capture
failure never blocks a pull request by itself; the Gatekeeper still
un-drafts the PR. The one thing that does block a PR is different, and
it is a test on field values, not a description in prose: a capture that
**succeeds** and produces a manifest entry whose `status` is a number in
the 5xx range. A `null` status (paired with a non-empty `error`) is
always a tooling failure, whatever else is true about the entry — never a
block condition, and never a "clean 200" either.

## Files

- `boot.sh --ticket <id> [--dir <path>] [--stop]` -- builds the app once
  per run and seeds a fresh run database directly (measured at ~12s for a
  cold `rake demo:seed` — not worth a template database's staleness
  risk). `--stop` kills the server and drops the run's database. Any
  failure during a start tears down whatever it already created, even
  before `--stop` is ever called. `--dir` sets where it keeps its state
  and logs; pass the same path as `run.sh`'s `--out` so both scripts
  agree on one directory to erase afterward. Prints two lines on success:
  `BASE_URL=...` and `TEST_ENV_NUMBER=...` — the latter must be set on
  any later command that queries the database directly, or it reads the
  shared, unseeded test database instead of this run's own.
- `capture.mjs --targets <path> --out <dir> --base-url <url>` -- the
  Playwright driver. Reads the merged target list, signs in as needed,
  captures every target, builds the two contact sheets, and writes
  `<out>/manifest.json` after every entry, so a budget timeout or a crash
  mid-run still leaves everything captured so far on disk.
- `run.sh --ticket <id> --targets <path> --out <dir> [--budget <seconds>]`
  -- the one command described above. Wires `boot.sh` and `capture.mjs`
  together (exporting `TEST_ENV_NUMBER` from `boot.sh`'s output before
  resolving the core surface), merges the core surface with the ticket's
  targets, enforces the budget, and always tears the server and run
  database down again — a `trap` on `EXIT`, `INT`, and `TERM` covers every
  exit path, including a budget timeout or the run being killed outright.
- `example.json` -- a worked example of the Capture plan shape, for the
  planner and the developer to copy from.

## Environment notes

- Only `config/credentials/test.key` exists in this environment, so
  `RAILS_ENV=test` is the only environment that boots. `boot.sh` copies
  it from the main checkout when a dispatch worktree does not have its
  own copy.
- `boot.sh` symlinks `node_modules` from the main checkout when the
  worktree has none of its own. It finds that checkout through git
  (`git rev-parse --path-format=absolute --git-common-dir`'s parent),
  overridable with `UI_CAPTURE_MAIN_CHECKOUT`.
- Chromium is the symlink at `/opt/pw-browsers/chromium`, launched with
  `--no-sandbox`. Do not run `playwright install`; nothing needs it.
- The global `playwright` npm package supplies the driver. `run.sh`
  passes its location (`npm root -g`) to `capture.mjs` as `NODE_PATH`,
  since Node's ES module loader does not consult `NODE_PATH` on its
  own; `capture.mjs` reaches it through `createRequire`, which does.
- Database credentials are never written to disk. `boot.sh` re-reads
  them from Rails credentials whenever it needs them, including in
  `--stop` mode, instead of persisting them in its own state file.
