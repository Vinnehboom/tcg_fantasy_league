# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in the
`kanban-automation` plugin (`Vinnehboom/claude-automation`), not here and
no longer in `.claude/skills/`.

**Generation:** 14
**Predecessor session:** `session_0129DEZ2Kz8y8qqMjGFd73nt` (generation 13)
**Handoff trigger:** cost ceiling. `get_session` read `cost_usd` $93.38
against `orchestrator_cost_ceiling_usd` $50 — nearly double, caught at the
top of the 17:30 BST scheduled cycle (not mid-task this time; the
mid-cycle re-check from generation 12/13's own lesson wasn't exercised
because nothing hit it before the scheduled boundary did). This generation
ran three tickets end-to-end back to back (P-7 review re-entry + a
follow-up fix, H-12, H-14, H-15) in one long interactive stretch with
Vinnie live in the session — that volume, not a single runaway dispatch,
is what drove the cost.
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` · `main`.
`orchestrator_branch` in `.claude/kanban-cycle.json` reads `main` and is
current.

Everything not listed below is re-derived live by `/kanban-cycle` (board,
pull requests, active agents) or already written into the plugin's skill
files. Read those, not a summary of them.

## Open questions awaiting the user

1. **P-14's scope** (https://app.notion.com/p/3d84af79fc01818a93dfc838895b2fd2)
   — two things, both still open:
   - Request types beyond erasure/objection (access/rectification/
     restriction?) — open since generation 12.
   - A narrower ask from generation 13: Vinnie asked on P-7's PR review
     for a super-admin-only lookup of suppressed players via policy
     scopes. This sits next to, but isn't obviously the same feature as,
     P-14's queue — the card's own 2026-09-11 answer says the existing
     admin role is fine for working the queue. Both are recorded on the
     card under "Note, 2026-09-13"; whoever plans P-14 needs to ask
     Vinnie directly if it's still unclear which access model covers
     which part.
   P-14's dependency (P-7) merged this generation, so P-14 is now a real
   candidate the next cycle may pick up — this question is more relevant
   now than when generation 12 first raised it, not less.

## In-flight nuance that live state would misread

- **Three PRs open, all waiting on Vinnie's ordinary review/merge — no
  hidden blockers, but one has a non-obvious eligibility note:**
  - `tcg_fantasy_league#118` (H-15) — CI green, isolated review found 0
    BLOCKING findings. Nothing unusual.
  - `tcg_fantasy_league#119` (H-14) — CI green. The isolated reviewer
    caught a real bug outside the ticket's own scope during this same
    round: a route-segment constraint the developer added as a side
    effect could have raised `UrlGenerationError` on the public landing
    page for any lowercase-id `Game`. Reverted in the same PR, with a
    request spec pinning the actual (harmless) fall-through behavior it
    was trying to prevent. Already fixed — nothing to do, just don't be
    surprised the diff includes a routes.rb constraint change that reads
    unrelated to "trim over-declared routes" at first glance.
  - `Vinnehboom/claude-automation#14` (H-12) — CI green, review round
    clean (4 BLOCKING found and fixed, 12/13 NON-BLOCKING addressed).
    **Does not qualify for this repo's skill-files auto-merge** — it
    touches `plugins/kanban-automation/scripts/ui_capture/**`, outside
    `plugins/*/skills/**` — so it genuinely needs Vinnie's manual review,
    this isn't a stuck-auto-merge situation to investigate.
- **`Vinnehboom/claude-automation#15`** — this generation's own lesson PR
  (see "Pending automation work"), just opened, likely still unmerged.
  Entire diff is under `plugins/*/skills/**`, so it should auto-merge on
  its own once `validate` goes green — no action needed unless it's
  still open and red next cycle.
- **P-7 (`tcg_fantasy_league#116`) merged this generation.** Notion card
  is `Done`. Nothing further.
- **H-12/H-14/H-15's Notion cards are all `Review`** — normal Gatekeeper
  state for an open, ready PR waiting on Vinnie's merge, not a lag to
  correct.
- **H-16** (https://app.notion.com/p/3da4af79fc01817f96a3e607616c0da3) is
  a new ticket filed this generation — a follow-up on the N+1 preload
  fix landed on P-7 (layer 2: batching `Player#record_score!` and
  `ExternalData::Result`'s per-record queries, deliberately deferred
  since it needs its own design, not a copy of the layer-1 preload).
  `Not started`, no dependency, ready whenever a slot opens.

## Pending automation work

- **Filed this generation:** `Vinnehboom/claude-automation#15` —
  clarifies the Reviewer brief's worktree write path (a dispatched
  reviewer can only write into its own worktree, never the developer's)
  and documents a confirmed hazard: a reviewer's own worktree can be
  cleaned up before the orchestrator's next turn copies the review file
  out, even on a clean completed run, because `docs/pipeline-cache/` is
  gitignored and worktree cleanup doesn't distinguish "nothing changed"
  from "changed something untracked." Hit twice this generation (H-12,
  H-15) — both times the reviewer's inline hand-back message was what
  actually survived, not the file. `add_repo`/`get_session` worked fine
  this generation (no repeat of generation 12's `Permission Grant`
  block), so this one filed cleanly.
- **Anecdotal, not confirmed as a standing block:** `register_repo_root`
  (used to load the automation repo's own CLAUDE.md/skills) was denied
  under `Permission Grant` once this generation, mid-session, even
  though `add_repo` on the same repo had succeeded earlier. Didn't block
  anything (registering the repo root isn't required to edit and push a
  file in it) — just try it normally next time rather than assuming
  either outcome.

## Recently merged (context, not a substitute for reading live state)

- `tcg_fantasy_league#116` (P-7) — merged this generation.
- `Vinnehboom/claude-automation#13` (mid-cycle cost-ceiling re-check,
  filed at this generation's own handoff-in) and `#14`'s predecessor
  work — already merged before this generation's main work began.
