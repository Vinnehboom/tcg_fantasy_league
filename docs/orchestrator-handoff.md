# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in the
`kanban-automation` plugin (`Vinnehboom/claude-automation`), not here and
no longer in `.claude/skills/`.

**Generation:** 15
**Predecessor session:** `session_01QNtm6fNP3HWjKwdi4tAe2L` (generation 14)
**Handoff trigger:** cost ceiling. `get_session` read `cost_usd` $54.40
against `orchestrator_cost_ceiling_usd` $50, caught mid-cycle (the 08:00
BST scheduled firing), not at a cycle boundary. This generation ran three
tickets (P-1, P-13, P-2c) plus a fourth in flight (P-14) in one long
interactive stretch with Vinnie live in the session, live-fixed two
Checkpoint-1-driven reviewer findings, and made three plugin/config
changes — that volume, not a single runaway dispatch, drove the cost.
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` · `main`.
`orchestrator_branch` in `.claude/kanban-cycle.json` reads `main` and is
current.

Everything not listed below is re-derived live by `/kanban-cycle` (board,
pull requests, active agents) or already written into the plugin's skill
files. Read those, not a summary of them.

## Open questions awaiting the user

None outstanding. P-2c's eight Checkpoint-1 questions and P-14's two
scope questions were both answered directly by Vinnie this generation and
are recorded on their respective cards.

## In-flight nuance that live state would misread

- **P-14 dispatch may still be running or may have just finished** —
  agent `a3f5f1704c4d314fa`, dispatched this generation with both its
  scope questions already pre-answered (erasure/objection only; the
  super-admin suppressed-player lookup is a separate feature, not this
  ticket). Check `ListAgents` first. If it's gone with no PR and no
  updated card, that's the vanished-worktree failure mode documented in
  "Dispatch mechanics" — don't assume lost work without checking the
  card and `git ls-remote` for its branch first.
- **`tcg_fantasy_league#124` (P-2c) — rebased and pushed at handoff time,
  CI in progress, not yet marked ready.** Branch
  `P-2c-terms-of-service`, head `a2369a2`. One reviewer round already ran
  (1 BLOCKING fixed: a self-contradiction about whether sponsored prize
  drafts exist today; 3 of 8 NON-BLOCKING also fixed). Check CI on
  `a2369a2` — if green and main hasn't moved again, just un-draft and
  flip the card to Review; no second review round needed. This is an AI
  legal draft, explicitly not lawyer-reviewed — that's stated on the PR
  and card on purpose, not a gap to fill.
- **`tcg_fantasy_league#123` merged this generation** — sets
  `min_open_prs: 2`. Its branch briefly showed 2 phantom extra commits
  from a stale local `main` ref (this session had not re-fetched after
  an earlier rebase-merge minted new commit SHAs for already-merged
  content) — resolved with a clean rebase onto `origin/main` and a
  force-push. Nothing wrong shipped; noted in case the same stale-ref
  symptom recurs on another branch.
- **P-1 and P-13 cards stay `In progress` on purpose** — both are
  compliance tickets blocked on Vinnie's own real-world action (ICO
  registration + fee; contacting Limitless/eloshowdown for permission),
  not on more pipeline work. Their PRs (`#122` merged, P-13 has none by
  design) and Knowledge Base/Decisions entries are already done. Don't
  re-dispatch either from board state alone.
- **Two new standing instructions from Vinnie this generation, both
  already written into the plugin (see "Pending automation work") —
  don't re-derive them from this note, read the skill files:**
  keep `min_open_prs` ticket-linked PRs in flight at all times, topping
  up immediately when a merge or a resolved Checkpoint 1 opens room; and
  skip Checkpoint 1 entirely for a compliance-ticket gap that's purely an
  unknown fact the bracketed-placeholder Decision already resolves —
  draft it and let him review the result, but still ask on a genuine
  design fork or real judgment call.

## Pending automation work

- **Filed this generation, likely already merged (whitelisted,
  skill-files-only, green `validate`):** `claude-automation#18` (the
  `min_open_prs` top-up logic in `kanban-cycle` step 4) and
  `claude-automation#19` (the Checkpoint-1 placeholder-skip instruction
  in `ticket-pipeline`). Check they merged; if either is still open and
  red, that's this generation's to fix.
- **Not yet merged, needs Vinnie's own review (not whitelisted, edits
  code not just skills/config):** none outstanding from this generation
  beyond the tickets already listed above.

## Recently merged (context, not a substitute for reading live state)

- `tcg_fantasy_league#122` (P-1), `#123` (min_open_prs config) — merged
  this generation.
- `Vinnehboom/claude-automation#13` (mid-cycle cost-ceiling check),
  `#14` (H-12), `#15`, `#16`, `#17` — all merged before or during this
  generation.
