# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in `.claude/skills/**`,
not here.

**Generation:** 3
**Predecessor session:** `session_01PsaH41jkSUTySGSEovnLAm` (generation 2)
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` · `handoff-gen3-lessons`,
NOT `main` and NOT `.claude/kanban-cycle.json`'s `orchestrator_branch` value
(`claude/kanban-orchestrator-setup-7jgaqe`, which is stale — missing at
least 5 recent skill commits `main` has). Generation 3 was spawned from
`handoff-gen3-lessons` specifically because that branch (PR #67, unmerged)
is the only place carrying BOTH the current main content AND this
generation's own skill edits AND this note itself — `main` alone doesn't
have PR #67's changes yet, and this session has no way to merge that PR
itself (see open questions). Once PR #67 merges, `main` and this branch
converge; there's nothing to reconcile going forward, this was a one-time
bootstrap problem. See open questions below for the real fix
(`orchestrator_branch` → `main`, once PR #67's content is actually there).
**Routines:** 2 daily cycles — 08:00 and 17:30 BST. Reduced from 4 this
generation, by explicit user request. The count matters: a handoff that
leaves fewer than 2 is a silent regression.

Everything not listed below is re-derived live by `/kanban-cycle` (board,
PRs, active agents) or already written into the skill files. Read those,
not a summary of them.

## Open questions awaiting the user

- **PR #67 needs a human merge.** It's this generation's own skill-maintenance
  change (reviewer phase to one round, `kanban-cycle` trim, four environment
  facts documented) — it doesn't link a Notion ticket, so `/kanban-cycle`'s
  auto-merge-on-lgtm logic won't pick it up. Someone needs to review and
  merge it manually (or ask the successor to, once Vinnie's looked at it).
  Until it merges, the pipeline is still running the OLD "up to 2 rounds"
  reviewer instructions.
- **`kanban-cycle.json`'s `orchestrator_branch` is wrong and needs a decision.**
  It currently points at `claude/kanban-orchestrator-setup-7jgaqe`, which is
  stale — `main` has had the current, correct skills for a while (confirmed
  by direct comparison). Someone reverted this field from `main` back to the
  stale branch partway through generation 2's session; reason unknown. Either
  fix it back to `main`, or say why it shouldn't be — until resolved, every
  future handoff has to redo this same verify-and-override, which is exactly
  the failure mode this field exists to prevent.
- **Someone is editing `.claude/skills/` directly on `main`, in parallel with
  this automation.** Generation 2 found several independent commits it didn't
  make: Planner moved back to Opus, Tester (Phase 4) disabled outright,
  Gatekeeper reduced to a rebase-only gate, `max_open_prs` dropped from 3 to
  2, the pre-commit hook scoped to changed files. None of it conflicted with
  generation 2's own changes, but it's worth confirming with the user whether
  this is their own intentional direct editing (most likely) or something to
  investigate — and whether they'd rather route such changes through the
  automation instead.
- **H-3's Notion card status update (to "Done") was denied** by a permission
  check generation 2 didn't get an explanation for, and never retried. PR #63
  is merged; the card may still read "Review". Worth a manual check.
- **Curator pass (Phase 6) on C-9 and H-3** is still unbanked. The user said
  "wait for my review" when generation 2 asked earlier — both tickets are
  now merged, which may or may not count as that review having happened. Ask
  again rather than assuming either way.

## In-flight nuance that live state would misread

- **PR #65 (H-2) is a draft with CI still red on `feature_specs`**, after two
  fix attempts. Round 1 fixed a real bug (a miscalibrated skip guard on the
  ticket's own new spec) but didn't touch CI. Round 2 found and fixed the
  actual root cause — CircleCI's `cimg/ruby:3.3.6-browsers` image has never
  shipped an actual Chrome binary or chromedriver, a repo-wide gap nothing
  had exercised before this ticket's first `:js` spec — but CI still came
  back red after that fix too. **A third dispatch (round 2's own follow-up)
  was running when this handoff started** and its result is unknown — the
  predecessor's archival may have orphaned it. Check PR #65's actual current
  CI status fresh; don't assume the in-flight dispatch finished, pushed, or
  even ran to completion. Note also: this repo's CI dashboard
  (`circleci.com`) is unreachable from this environment's network at all —
  see the skill-file note on this — so diagnosis has to stay static/local.
- **PRs #62 (C-9) and #63 (H-3) are both merged.** C-9's Notion card is Done;
  H-3's update was denied (see open questions above).

## Pending automation work

Nothing outstanding beyond PR #67 above. Generation 1's two carry-over items
("summaries not transcripts" on the remaining phase briefs, verifying the
worktree setup hook) both appear to have already landed — `kanban-cycle`'s
Dispatch mechanics and `reviewer.md` already hand back summaries, and
`developer.md`'s commit gate is scoped to changed files — so don't redo them
on the assumption they're still open; verify first if in doubt.

## Environment caveats

All already documented in the skill files — listed here only so the
successor knows to expect them, not as the source of truth:

- Local `HEAD` reverts to stale commits with no reflog explanation. Always
  `git fetch` and compare against `origin/<branch>` before trusting it.
- The auto-mode classifier blocks plain `git rebase` inside a dispatched
  worktree agent reliably (works fine in the orchestrator's own session), and
  now also blocks a direct `git push` to `main` from the orchestrator session
  itself, even for skill-maintenance commits — push a branch and open a PR
  instead.
- Dispatched agents occasionally vanish with zero trace — a container
  restart can kill every live background dispatch at once, silently. Every
  dispatch pushes after its first commit for this reason; still, re-check
  real state (`git worktree list`, the PR, the Notion card) rather than
  trusting what a cycle thought was still running.
- An org-wide rate-limit/spend-limit error can kill a dispatch mid-run,
  arriving as a `failed` task-notification with a raw error instead of a
  clean hand-back. Check real git/PR state before assuming the work was
  lost — it's often already pushed.
- `circleci.com` is entirely unreachable from this environment's network
  egress — no CI log access, ever. Diagnose CI failures from the config and
  the diff, not the log.
- GitHub's stacked-PR feature: the bottom PR of a stack cannot be merged
  through any available MCP tool. It needs a manual merge in the web UI.
