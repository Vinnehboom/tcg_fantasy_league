# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in `.claude/skills/**`,
not here.

**Generation:** 6
**Predecessor session:** `session_018NCFPhnP6C225GhgGK8TzM` (generation 5)
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` · `main`. `orchestrator_branch`
in `.claude/kanban-cycle.json` reads `main` and is current — confirmed via
`git show origin/main:.claude/kanban-cycle.json` at handoff time, not just
trusted.

Everything not listed below is re-derived live by `/kanban-cycle` (board,
PRs, active agents) or already written into the skill files. Read those,
not a summary of them.

## Open questions awaiting the user

None outstanding from this generation.

## In-flight nuance that live state would misread

- **C-26 is stacked on C-25's branch, not on `main`.** C-25
  (`c-25-external-score-player-season`, PR #81) is still in review, not
  merged. C-26's branch (`c-26-score-modifier-sti`) is deliberately based
  on C-25's tip per Vinnie's explicit decision (both tickets touch
  `player_season.rb`) — it has no PR open yet. When C-26 is ready to open
  a PR, its `base:` must be `c-25-external-score-player-season` (or that
  PR's number, once it's known), never `main` — see the ticket-pipeline
  skill's "Stacked PRs for dependent tickets" section. If C-25 gains new
  commits before C-26 opens its PR, C-26 needs a rebase onto C-25's new
  tip first (done directly by the orchestrator session per the
  classifier-blocks-dispatched-rebase rule, not by a dispatched agent).

- **C-26's Phase 3 (Reviewer) dispatch was still running at handoff time
  and will NOT survive into this session.** Dispatched subagents are
  children of the predecessor session and are lost at handoff, per the
  `/handoff` skill's own guardrail. Before redispatching a fresh reviewer,
  check `.claude/worktrees/agent-abe706e1aab8476e1/docs/pipeline-cache/C-26/review-round-1.md`
  (the reviewer's worktree, if it still exists) — if a completed review is
  sitting there, resume from it (relay findings to the developer's
  worktree, `agent-aa6e030661dcff910`, running branch `c-26-score-modifier-sti`)
  rather than redoing the review from scratch. If the worktree or file is
  gone, redispatch a fresh reviewer per the usual mechanics, diffing
  `c-26-score-modifier-sti` against `c-25-external-score-player-season`
  (not `main`, since C-26 is stacked).

- **PR #81 (C-25) is ready for review, CI green, no rebase needed as of
  handoff** — a normal state, noted only so the next cycle doesn't waste a
  check confirming what's already settled.

## Pending automation work

- **Merge PR #82** (`handoff-gen6-lessons`) — this generation's own
  lesson-fold: one new `kanban-cycle` environment fact (a `cd` into a
  vanished dispatch worktree can fail silently and leave a later command
  in the same Bash call running in the orchestrator's own checkout,
  confirmed three times this generation). No linked Notion ticket, so
  auto-merge-on-lgtm won't pick it up — needs a human merge like the
  others before it (#69/#71/#72/#74/#75/#77/#78/#79/#80).
- **The claude-code-remote MCP connector (session/trigger management —
  `get_session`, `create_session`, `list_triggers`, `create_trigger`,
  `delete_trigger`, `archive_session`) was disconnected at the moment
  generation 5 tried to run `/handoff`'s step 3.** This is the same kind
  of connector-name/availability flapping this generation saw repeatedly
  with the Notion and GitHub MCP connectors — it has reconnected on its
  own every other time. If you are reading this because a human manually
  completed the spawn once the connector recovered, this line is now
  stale and can be ignored. If instead generation 5 is still alive and
  retrying when you're reading this some other way, that's the situation
  to check first.
