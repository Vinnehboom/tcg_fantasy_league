# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in `.claude/skills/**`,
not here.

**Generation:** 2
**Predecessor session:** `session_01Jow5PUwwqA9vNBuBzEgQuE` (generation 1,
ran 23–27 August 2026)
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` ·
`claude/kanban-orchestrator-setup-7jgaqe`. Generation 2 was spawned from
that branch, not `main`, because `main` still carries the pre-fix
`orchestrator_branch` value — see pending work item 1.
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
- **This handoff is the first one ever run.** The user approved it
  explicitly on 27 August, after holding it earlier that day so its first
  run would not be unattended. If any step of it misbehaved, that is new
  information about the mechanism, not routine noise — say so plainly
  rather than working around it quietly.

## Pending automation work

The successor should do these, then report. They come from a token audit of
generation 1 (1,944 requests, mean prompt 371,729 tokens, 700M cache-read
tokens, ending the week at `allowed_warning` on a seven-day rate-limit
window). The account is on a subscription, so the payoff is reclaimed
capacity before throttling, not money. Ranked by measured saving:

1. **Get the `orchestrator_branch` fix onto `main`.** The branch
   `claude/kanban-orchestrator-setup-7jgaqe` holds one commit that `main`
   lacks: it points `orchestrator_branch` at `main` instead of at a
   working branch. PR #64 merged just before that fix, so `main` still
   names the working branch. Nothing is broken today — that branch exists
   and carries the skills — but the value is wrong in principle and will
   rot. Ask the user whether to open a PR for it; do not open one
   unprompted. Once it merges, `main` is self-consistent and every later
   handoff can spawn from the default branch.
2. **Finish "summaries, not transcripts" across the remaining phase
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
3. **Fix the worktree setup cost.** `.claude/hooks/session-start.sh` is
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
