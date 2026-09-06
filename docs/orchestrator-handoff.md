# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in the
`kanban-automation` plugin (`Vinnehboom/claude-automation`), not here and
no longer in `.claude/skills/`.

**Generation:** 9
**Predecessor session:** `session_01NYRRtyEHKss5Uf16DTdEbv` (generation 8)
**Handoff trigger:** none. Generation 8 had nothing in flight. Vinnie
asked for a fresh orchestrator after the plugin cutover, so this
generation starts clean rather than carrying a conversation.
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` · `main`.
`orchestrator_branch` in `.claude/kanban-cycle.json` reads `main` and is
current.

Everything not listed below is re-derived live by `/kanban-cycle` (board,
pull requests, active agents) or already written into the plugin's skill
files. Read those, not a summary of them.

## Open questions awaiting the user

None.

## In-flight nuance that live state would misread

None. No pull request is open in `tcg_fantasy_league` or in
`claude-automation`. No dispatched agent is active. Generation 8 never
resumed cycles after 2026-09-06, so the board is where the last completed
cycle left it.

## What changed on 2026-09-06

The orchestration skills now come from the `kanban-automation` plugin.
Four things follow from that:

- A skill edit goes to `Vinnehboom/claude-automation` as a pull request.
  Do not edit `.claude/skills/` in this repository. Those copies are
  superseded and a pull request to delete them is still to come.
- The UI capture driver moved too. The plugin ships `capture.mjs` and
  `run.sh` under `scripts/ui_capture/`. This repository keeps
  `.claude/ui-capture.json`, `script/ui_capture/boot.sh`, and
  `script/ui_capture/core_targets.sh`.
- `script/ui_capture/run.sh` is a shim that forwards to the plugin. Delete
  it in the same pull request that deletes `.claude/skills/`.
- The plugin arrives by an install, not by a file. A project
  `.claude/settings.json` that declares `extraKnownMarketplaces` and
  `enabledPlugins` installs nothing. Those keys are what an install
  writes. tcg#95 tried to add them and was closed for that reason. Do not
  re-open it.

## Pending automation work

- **The environment needs `Vinnehboom/claude-automation` as a source.**
  The marketplace clone goes through the git proxy of the session, and
  that proxy allows only the repositories attached to the session. A
  session with only this repository attached cannot install the plugin,
  whatever its setup script says. Generation 8 failed this way for days.
  The failure reads as
  `Plugin "kanban-automation" not found in marketplace "vinnie-automation"`,
  which sounds like a stale marketplace. It is an empty one.
- **The setup script hides its own failure.** Its two marketplace lines
  carry `|| true`, and those two lines do the network work. When one
  fails, the only error that reaches anyone is the install's, which names
  the wrong cause. Vinnie has been asked to remove `|| true`.
- **Delete the four superseded skill copies** from `.claude/skills/`,
  KEEPING `simple-english`, which stays in this repository for licensing.
  The same pull request deletes `script/ui_capture/run.sh`. Do this only
  after a session proves that the plugin loads.
- **Rename the Routine prompts** to `/kanban-automation:kanban-cycle`
  once those copies are gone.
- **Notion H-14** covers moving the generic part of
  `script/ui_capture/boot.sh` into the plugin. In progress, not started
  in code.
