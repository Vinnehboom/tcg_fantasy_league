# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in `.claude/skills/**`,
not here.

**Generation:** 4
**Predecessor session:** `session_01Vkct2ETmBwkvargZNeTeRH` (generation 3)
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` · `handoff-gen4-lessons`,
NOT `main` and NOT `.claude/kanban-cycle.json`'s `orchestrator_branch` value
(`claude/kanban-orchestrator-setup-7jgaqe`, still stale — same open question
generation 3 inherited from generation 2, still unresolved). Generation 4
spawned from `handoff-gen4-lessons` because it's the only branch carrying
current `main` content AND two pending skill PRs (#69, #71) AND this note —
`main` alone doesn't have those PRs' content yet. Once both merge, `main`
converges with this branch; nothing to reconcile going forward. See open
questions for the real fix (`orchestrator_branch` → `main`, once merged).

Everything not listed below is re-derived live by `/kanban-cycle` (board,
PRs, active agents) or already written into the skill files. Read those,
not a summary of them.

## Open questions awaiting the user

- **PR #69 needs a human merge** — records that curator Notion writes are
  pre-approved (a direct user instruction this generation). No linked
  Notion ticket, so auto-merge-on-lgtm won't pick it up.
- **PR #71 needs a human merge** — records a new environment fact (see
  "In-flight nuance" below for what it's about). Same auto-merge gap as #69.
- **PR #65 (H-2) still hasn't merged**, despite being marked ready for
  review and fully CI-green for a while now. Not blocking anything, just
  flagging in case it's waiting on something this generation doesn't know
  about.
- **`kanban-cycle.json`'s `orchestrator_branch` is still wrong.** Same
  question as generation 2 → 3: it points at a stale branch when `main`
  has the current skills (once #69/#71 land). Fix it to `main` once both
  merge, or say why not — this is the third generation to redo this
  same verify-and-override.

## In-flight nuance that live state would misread

- **Ticket H-6 ("Feature specs: user profile") is a real mess — investigate
  before trusting anything about it.** This generation dispatched it,
  approved its Checkpoint 2 plan, and then `ListAgents` reported it
  "running" for 4+ hours straight — but `git ls-remote --heads origin` shows
  **no branch for H-6 exists anywhere**, and `git worktree list` shows no
  worktree under its own agent ID either. What actually happened: a
  *different* ticket dispatch (H-5)'s original worktree vanished mid-run
  (the known container-restart failure mode), and when the harness gave it
  a fresh worktree, that worktree's directory was named after H-6's dispatch
  agent ID instead of H-5's own — see the new `kanban-cycle` environment
  fact (PR #71) for the mechanism. H-5 itself completed fine (PR #70,
  merged into this note's context already) using that borrowed-looking
  worktree. But H-6's own dispatch — the one that should have owned that
  worktree — has no visible trace of ever reaching Phase 2. The Notion card
  (https://app.notion.com/3c84af79fc01817798ddea15d8e77d99) showed Status
  "Not started" on last fetch, which may itself be stale. **Don't try to
  resume H-6's dispatch (it has no live agent to resume, and no worktree)
  — verify the card's real current status, confirm no stray branch exists,
  and if truly nothing happened beyond the plan being approved in
  conversation, redispatch it fresh** (`/ticket-pipeline H-6` from scratch —
  the approved plan itself doesn't carry over, so this needs genuine
  replanning, not a replay).
- **H-7's scope was widened this generation**, not just filed fresh — it
  now covers findings from both H-4's and H-5's curator passes (a shared
  sign-in helper, plus small fixes to `rosters_edit_spec.rb`/
  `rosters_show_spec.rb` that depend on that helper landing first to free
  up line budget). Card already reflects this; no action needed, just
  don't be surprised its scope looks bigger than "H-7" alone would suggest.
- **PR #70 (H-5) is fresh** — opened, marked ready, CI green, curator
  already ran and filed its findings directly (style guide + tech debt +
  the H-7 widening above). Nothing outstanding on it.

## Pending automation work

Nothing beyond the two PR merges above (#69, #71) and the
`orchestrator_branch` config fix that depends on them landing.
