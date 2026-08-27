# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in `.claude/skills/**`,
not here.

**Generation:** 1 (first; no predecessor)
**Predecessor session:** `session_01Jow5PUwwqA9vNBuBzEgQuE`
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` · `main` carries the
skills since PR #64 merged on 2026-08-27, so a successor cloning the
default branch comes up fully equipped.
**Routines:** 4 daily cycles — 08:00, 12:30, 17:30, 21:30 BST. The count
matters: a handoff that leaves fewer is a silent regression.

Everything not listed below is re-derived live by `/kanban-cycle` (board,
PRs, active agents) or already written into the skill files. Read those,
not a summary of them.

## Open questions awaiting the user

- **Curator pass (Phase 6) on C-9 and H-3.** Both tickets finished their
  review cycles and their PRs are open and ready. The predecessor asked
  whether to run the curator now or wait until the user has reviewed the
  PRs, and never got an answer. Nothing is blocked on it; the knowledge
  harvest is simply unbanked. Ask again at a natural moment rather than
  assuming either way.

## In-flight nuance that live state would misread

- **PRs #62 and #63 are genuinely waiting on the user**, not stalled. Both
  are ready for review with CI green on every check, and there is nothing
  for the automation to do on either. PR #64 merged on 27 August.
- **The handoff is deferred pending a decision.** The 12:30 cycle on
  27 August reached the cost ceiling and would have run `/handoff`. It was
  held instead: the mechanism had never run once, and its first run would
  have archived the session the user was working in, while the PR that
  adds that mechanism was still open. Merging #64 approved the code. It is
  not an answer to "archive this session now", so the question is still
  with the user. Until they answer, treat reaching the ceiling as a reason
  to ask, not to act.
- **A stash is parked in the predecessor's checkout** (`stash@{0}`, labelled
  "stale-checkout schema.rb artifact"). It is a *bad* `db/schema.rb` — an
  artifact of migrating against a stale checkout, which drops the `settings`
  table and rolls the migration version backwards. Never apply it. It was
  stashed rather than discarded only to avoid destroying something
  unexamined. The successor gets a fresh clone and will not see it; drop it
  from the note once the predecessor is archived.

## Pending automation work

The successor should do these, then report. They come from a token audit of
generation 1 (1,944 requests, mean prompt 371,729 tokens, 700M cache-read
tokens, ending the week at `allowed_warning` on a seven-day rate-limit
window). The account is on a subscription, so the payoff is reclaimed
capacity before throttling, not money. Ranked by measured saving:

1. **Finish "summaries, not transcripts" across the remaining phase
   briefs.** Generation 1 already did this for
   `.claude/skills/kanban-cycle/SKILL.md` ("Dispatch mechanics") and
   `ticket-pipeline/references/reviewer.md`. Still to do: the same
   treatment for `planner.md`, `developer.md`, `tester.md` and
   `curator.md` — each writes its full output to
   `docs/pipeline-cache/<TASK_ID>/` and hands back a few lines plus a
   path. Note `docs/pipeline-cache/` is gitignored and scratch-only, so a
   report there does not survive the run; where the detail needs to
   outlive the pipeline (review outcomes, curator proposals) put it on the
   PR or the Notion card instead and hand back the link.
2. **Fix the worktree setup cost.** `.claude/hooks/session-start.sh` is
   already run first thing by every dispatch, which covers `test.key`, the
   Postgres role, and assets. Verify that is actually sufficient in a fresh
   worktree — generation 1 saw agents still rediscovering setup failures
   (`NoMethodError: undefined method 'name' for nil` from `database.yml`,
   `AssetNotFound: application.css`). Est. ~1% directly, but it prevents
   multi-thousand-token error dumps entering context permanently, which is
   the larger cost.

Already done in generation 1, do not redo: Planner and Curator moved from
Opus to Sonnet (Reviewer deliberately stays Opus); `model` pinned on every
ad-hoc dispatch; the cost-ceiling check and this handoff mechanism.

## Environment caveats

All already documented in the skill files — listed here only so the
successor knows to expect them, not as the source of truth:

- Local `HEAD` reverts to stale commits with no reflog explanation. Always
  `git fetch` and compare against `origin/<branch>` before trusting it.
- The auto-mode classifier intermittently blocks `git rebase`,
  `git reset --hard`, and `git push --force-with-lease`. Inside dispatched
  worktree agents it blocks rebase reliably; in the orchestrator's own
  session it blocks sporadically and usually succeeds on a plain retry.
- Dispatched agents occasionally vanish with zero trace. Every dispatch is
  told to push after its first commit for this reason.
- GitHub's stacked-PR feature: the bottom PR of a stack cannot be merged
  through any available MCP tool. It needs a manual merge in the web UI.
