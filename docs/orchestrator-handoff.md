# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in the
`kanban-automation` plugin (`Vinnehboom/claude-automation`), not here and
no longer in `.claude/skills/`.

**Generation:** 16
**Predecessor session:** `session_01G7W7C8wgKpNhzRUVoyqCsw` (generation 15)
**Handoff trigger:** cost ceiling. `get_session` read `cost_usd` $48.37
against `orchestrator_cost_ceiling_usd` $50 at the top of the 08:00 BST
scheduled cycle — caught before it grew further, unlike generation 13→14's
handoff which wasn't caught until $93.38 (nearly double) because nothing
checked mid-cycle. This generation ran the gen-14→15 handoff itself, two
full kanban cycles, and one ticket (H-16) end to end with live checkpoint
back-and-forth in the same session — that volume drove the cost.
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` · `main`.
`orchestrator_branch` in `.claude/kanban-cycle.json` reads `main` and is
current.

Everything not listed below is re-derived live by `/kanban-cycle` (board,
pull requests, active agents) or already written into the plugin's skill
files. Read those, not a summary of them.

## Open questions awaiting the user

1. **A proposed CLAUDE.md addition, never confirmed.** This generation
   found that attaching `Vinnehboom/claude-automation` with push access
   (needed to check/drive that repo's own PRs, and to file lessons into
   its skill files) got blocked once by the auto-mode classifier early in
   the generation, then succeeded later during this handoff with no
   config change in between — so the block may be intermittent rather
   than a hard wall. Either way, CLAUDE.md's Routine Actions list still
   doesn't mention this action, which is the classifier's only source of
   authority for it (per CLAUDE.md's own text). Proposed wording was put
   to Vinnie in chat; he has not answered. Don't add it yourself without
   his word — this is exactly the kind of automation-permission widening
   CLAUDE.md itself says needs his explicit say-so.
2. **P-2c's Curator proposals (Checkpoint 3), posted in chat, not yet
   answered:** a new card for sponsored-drafts prize/promotions terms, a
   Decisions-database row ("No refunds, now or for any future paid
   feature"), a text update to card P-2b (add the
   `[Contact address for legal notices]` placeholder it's missing, and
   refresh its now-stale "no card covers reviewing /terms copy" note),
   and two Tech Debt entries (age numbers as literal prose instead of
   `AgeGate` constants; repeated `visit <path>` in two spec files instead
   of a shared `before` block). Nothing is written to Notion until Vinnie
   says go — don't infer approval from silence.

## In-flight nuance that live state would misread

- **Two PRs open, both genuinely ready, no hidden blockers:**
  - `tcg_fantasy_league#126` (P-14) — CI green, Gatekeeper capture clean,
    reviewed and fixed. Waiting on Vinnie's ordinary review/merge since
    2026-09-15.
  - `tcg_fantasy_league#127` (H-16) — CI green, reviewer approved (0
    blocking, fixed 5 of 8 non-blocking in the same pass). Waiting on
    Vinnie's ordinary review/merge since 2026-09-16. High-risk ticket
    (rewrites the `ExternalScore` write path); already got its own
    Checkpoint 2 back-and-forth with Vinnie, already resolved — nothing
    further needed from him beyond the normal merge decision.
- **`tcg_fantasy_league#124` (P-2c) merged this generation.** Notion card
  is `Done`. The Curator already ran against it — see open question 2
  above, not a stuck PR.
- **This generation's plugin install predates a 2026-09-13 change (H-12)
  in `claude-automation`'s `ticket-pipeline` skill**, which replaced the
  interim chat-attachment UI-capture delivery with a published Artifact
  evidence page. Discovered only while writing this note (reading the
  repo directly, not the installed cache). P-2c's and H-16's Gatekeeper
  evidence both used the old method (a `## Visual evidence` text section
  on the Notion card, screenshots sent as chat attachments — the mobile
  contact sheet failed to upload both times, a ~2MB PNG hitting a 400
  from the file service). **No need to migrate those two cards
  retroactively.** Your own fresh plugin install should already have the
  evidence-page version; just don't be surprised the two most recent
  cards look different from what your own Gatekeeper runs will produce.
- **H-16's Notion card carries a `### Checkpoint 2 outcome` and
  `### Build notes` section** in addition to the usual `## Plan` — the
  isolated Reviewer was deliberately given a hand-trimmed ticket text
  (original problem/done-criteria only) rather than the live card, to
  keep those sections out of its blind review. Not a card-hygiene issue,
  just how this round's isolation was kept intact.

## Pending automation work

- **Filed this generation:** `Vinnehboom/claude-automation#20` —
  documents that the shared-Postgres cross-worktree contamination
  (already a known risk in `kanban-cycle/SKILL.md`) is confirmed to also
  hit the orchestrator's own main checkout, not just between two
  dispatch worktrees, with a concrete default response (verify it names
  an open PR's migration, then `git restore` without further
  investigation). Skill-files-only diff; should auto-merge on green
  `validate` — check its state if it's still open next cycle.
- **Not filed, deliberately:** the CLAUDE.md addition in open question 1
  above stays a chat proposal, not a PR, until Vinnie answers.
