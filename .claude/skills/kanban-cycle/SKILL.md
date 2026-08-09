---
name: kanban-cycle
description: >-
  Run one scheduled review cycle of a project's Kanban board and its GitHub
  pull requests: triage any open PRs first (CI fixes, review-feedback
  re-entry, rebases), then — if there's room under the PR caps — pick up the
  next ready ticket and hand it to the /ticket-pipeline skill. Reads its
  target repo, board, and caps from `.claude/kanban-cycle.json`, so it's
  portable to any project with a Notion kanban board: copy this skill folder
  and write a new config file pointing at that project's repo/board. Designed
  to be fired by a recurring Routine bound to a persistent session (not a
  fresh session per firing) — this session is the standing orchestrator,
  doing triage and picking what's next; it does NOT run ticket-pipeline
  inline in its own working directory. Both PR triage and picked-up ticket
  work are dispatched as background Agent-tool subagents, each on its own
  isolated git worktree (own checkout, own branch — not a separate
  container or session), so up to `max_open_prs` of them can run in
  parallel without a scheduled cycle ever colliding with in-progress work
  on the orchestrator's own checkout or on each other. In-flight detection
  reads real state (open PRs, Notion card status, `ListAgents`), not
  conversation memory, so it's correct regardless of which cycle or
  dispatch last touched a ticket. Every cycle ends with exactly one
  PushNotification pointing at a bullet-point rundown of every active
  agent's status, posted directly in this session — no notifications
  mid-cycle for individual checkpoints or events. Use when the user says
  "run the board
  cycle," "/kanban-cycle," or asks to check the kanban board and PR status on
  a schedule. Do not use for a one-off "work this ticket" request — that's
  /ticket-pipeline directly.
---

# Kanban cycle

One pass of: triage what's already open, then start what's next — never both
blindly. Runs unattended on a schedule, so it must never leave the user
guessing: end every cycle with a status push, even when nothing happened.

## 0. Load config

Read `.claude/kanban-cycle.json` (repo `owner/name`, `notion_board_url`,
`max_open_prs`, `max_stacked_prs`). If it's missing, say so and stop —
don't guess a repo or board.

## 1. Check for in-flight work — from real state, not memory

Ticket work now runs in its own dispatched worktree-isolated agent (see
"Dispatch mechanics"), not inline in this session, so this session's own
conversation history is NOT a reliable record of what's already
running — always confirm via `ListAgents` and real board/PR state, not
memory of what a previous cycle did. Check real state instead:

- Query the Notion board for any card with Status "In progress" or
  "Review". For each, check (step 2's PR inventory) whether an open PR
  already links it.
  - Status "In progress" with **no** linked open PR yet → still at or before
    Checkpoint 2 (planning, or a plan awaiting the user's go-ahead) in
    whatever session it's running in. Treat as in-flight.
  - Status "In progress" or "Review" **with** a linked open PR → it has its
    own lifecycle now; step 3's PR triage covers it, not this step.
- If any card is in-flight per the first bullet, **don't dispatch a new
  ticket this cycle** — only one ticket may be sitting in the
  pre-Checkpoint-2 state at a time. Note it in this cycle's rundown (step
  7) as "still waiting on your OK for `<ticket>`" and move on to PR
  triage.

If nothing is in flight, proceed normally.

## 2. Inventory open PRs

`mcp__github__list_pull_requests` (state=open) on the configured repo.
For each PR, note: number, author, base branch, head branch, whether its
body links a Notion ticket card (that's the fingerprint of a PR this
automation — via `/ticket-pipeline` — opened), CI status, review state,
and mergeability.

**Stacked PRs** are any whose base branch is not the repo's default branch
(i.e. based on another PR's branch rather than `main`). Count them —
that's `stacked_count`, capped at `max_stacked_prs`.

**First review given** on a PR means the user (the repo owner) has
submitted at least one review (any state — comment, approve, or changes
requested) on it — check via the PR's reviews, not just comments.

## 3. Triage existing PRs before starting anything new

Open PRs always come before new work. First, `ListAgents` to see which
dispatched subagents from a previous cycle are still active — match them
to PR numbers (by name/description) so you never dispatch a second agent
onto a PR that already has one running (that's a correctness requirement,
not just efficiency: two agents rebasing or pushing to the same branch
will fight each other). For a PR with an agent already active, just read
its current state for this cycle's rundown (step 7) — don't touch it.

For each open PR whose body links a Notion ticket (i.e. one this
automation is responsible for driving) that does NOT already have an
active agent:

- **CI red** → dispatch a worktree-isolated background agent (see
  "Dispatch mechanics" below) to fix it with the same rigor as
  `/ticket-pipeline`'s Gatekeeper CI-fix step (references/developer.md
  discipline: test-first, lint+test before pushing). New commit(s), push,
  done — don't just report it.
- **Unresolved review feedback** (a review or comment since the PR last
  updated) → dispatch an agent to run `/ticket-pipeline`'s "Handling
  review feedback (re-entry)" flow for that ticket/PR.
- **Stale branch / merge conflict** → dispatch an agent to rebase onto the
  repo's default branch only (never merge into the branch — no merge
  commits, ever), force-push with `--force-with-lease`, per the same rule
  `/ticket-pipeline`'s Gatekeeper uses.
- **Waiting on CI / waiting on the user** → nothing to dispatch; just
  reflect its state in the cycle rundown.

Each dispatched PR gets its own agent, so up to `max_open_prs` of these
can be running in parallel — that cap is exactly what keeps this bounded.

For open PRs that do NOT link a Notion ticket (opened by hand, not by this
automation): leave them alone — don't push to someone else's branch — but
list them in the rundown since they still count against the PR cap.

## 4. Compute room for new work

```
open_count    = all open PRs on the repo
stacked_count = open PRs whose base isn't the default branch
```

- If `open_count >= max_open_prs`: no new ticket this cycle — PR triage
  (step 3) is the whole cycle. Say so in the summary.
- Otherwise there's room for one new ticket, but a ticket whose plan would
  need to branch off another open PR (its dependency hasn't merged yet) is
  only allowed to start if BOTH: `stacked_count < max_stacked_prs`, AND the
  PR it would stack on already has the user's first review (step 2
  definition). If either fails, skip that ticket and try the next
  candidate instead of blocking the whole cycle on it.

## 5. Pick the next ready ticket

Fetch the Notion board (`notion_board_url`). Candidates are cards with
status "Not started" whose dependencies (`Depends On`) are satisfied —
either the dependency card is Done, or its PR is open and eligible to
stack onto per step 4. Rank by priority (as `/ticket-pipeline` does when
told "do the next one"). Walk the ranked list and take the first candidate
that clears step 4's room check.

If no candidate clears it (board empty of ready work, or every ready
ticket is blocked by the PR/stacking caps), that's a valid outcome — say so
in the summary, don't force one through.

## 6. Dispatch the picked ticket

Dispatch it exactly per "Dispatch mechanics" below. Do not dispatch a
second ticket in the same cycle even if step 4 would technically allow
it — one new ticket picked up per cycle, so the user doesn't get a wall of
approvals at once. (Existing-PR triage from step 3 is not subject to this
one-per-cycle limit — every open PR needing action gets its own dispatch,
up to `max_open_prs`.)

## Dispatch mechanics (used by both step 3 and step 6)

**Do not use `mcp__Claude_Code_Remote__create_trigger` with
`create_new_session_on_fire: true` for this.** That was the original
design and it is broken for this org: a freshly-spawned CCR session gets
none of this session's MCP connectors — confirmed via `list_triggers`
(such triggers show no `mcp_connections` at all, unlike self-bound ones,
which inherit the calling session's) and via `create_trigger` itself
rejecting an explicit `connectors` param ("not available for this
organization"). Two real dispatch attempts on ticket A-1 both confirmed
`run_once_fired` server-side and then did precisely nothing — no session,
no branch, no PR, not even a startup `PushNotification` — because the
spawned session had no GitHub or Notion tools to do anything with, and
apparently not enough life left to report that before giving up.

Instead, dispatch the work (`/ticket-pipeline <Task ID>` for a new ticket,
or the specific CI-fix/review-feedback/rebase task for an existing PR) as
a background `Agent` subagent of THIS session, with `isolation:
"worktree"`:

- `run_in_background: true` — a background Agent-tool call, not a new CCR
  session. Subagents inherit this session's tool access (GitHub, Notion —
  confirmed working: a Curator subagent dispatched this way successfully
  used live `mcp__Notion__*` calls with no special wiring) instead of
  starting cold with nothing, which is what actually made the checkpoint
  loop and every phase's Notion/GitHub work possible on A-1.
- `isolation: "worktree"` — gives the dispatch its own git checkout and
  branch, isolated from whatever this orchestrator's own working directory
  (and every other concurrently dispatched agent) is doing, without
  needing a wholly separate session/container to get that isolation. This
  is the actual property the old design was reaching for; it just reached
  for the wrong tool to get it. Multiple dispatches (existing-PR triage
  plus at most one new ticket) can run this way at once, each on its own
  worktree — that's what makes running several PRs in parallel safe.
- `subagent_type: "general-purpose"`, prompt: instruct it exactly what to
  do (run `/ticket-pipeline <Task ID>` including all three human
  checkpoints; or the specific triage task for an existing PR), and give
  it a clearly identifiable name/description (ticket ID or PR number) so a
  later cycle's `ListAgents` call and this cycle's rundown (step 7) can
  match it back to the right card/PR.
- Since it's a subagent of this session (not a disconnected CCR session),
  checkpoints route through the normal subagent flow: it stops and its
  `<task-notification>` arrives back into THIS session when it needs an
  answer or reaches a checkpoint. Do NOT treat that notification as a cue
  to interrupt the user right away — record the question/state and fold
  it into the next end-of-cycle rundown (step 7); a live back-and-forth
  can't be assumed since nobody may be watching. When the user does answer
  (whenever they next reply in this session, on their own time), resume
  the subagent with `SendMessage`. Tell every dispatched agent explicitly
  not to assume anyone is watching live between its own tool calls — this
  session may itself be dormant for hours between cron firings or user
  check-ins, so each subagent should sit blocked on its own
  `<task-notification>` without doing anything destructive in the
  meantime.

**Residual risk this trade accepts:** worktree isolation is git-level
only — every worktree of this repo still shares one Postgres test
database. The old fully-separate-session design also gave a separate test
DB, which is what the "cross-branch test-DB pollution" bug this design
was originally built to prevent actually needed. Running several
dispatches in parallel (up to `max_open_prs`) widens this slightly versus
the original one-at-a-time version: avoid running the test suite in the
orchestrator's own checkout while any dispatched agent is active, and if
collision symptoms ever show up (a stray table/migration bleeding across
branches), that's the first thing to suspect.

## 7. End-of-cycle rundown (always)

Every cycle ends with exactly one bullet-point rundown, posted as this
turn's own visible output in this session, regardless of whether anything
happened — the user checks in on this session when they have time, not on
remembering every individual alert. `ListAgents` to get the full current
set of active dispatched agents (this cycle's new dispatches plus any
still running from earlier cycles), and give one bullet per agent:

```
- [<Task ID>](<Notion card URL>) · [PR #<n>](<PR URL>): <one-line status>
```

Link whatever exists: a ticket with no PR yet is just `[<Task ID>](<Notion
card URL>): <status>`; a hand-opened PR with no linked ticket is just `[PR
#<n>](<PR URL>): <status>`. Use the card's own Notion page URL (from step
1/5's board query), not the shared `notion_board_url` — the point is a
one-click link straight to that ticket, not the whole board. Use the PR's
`html_url` from step 2's inventory. `<status>` is a short, concrete state,
e.g. `blocked on CI, pushed a fix` / `planner waiting on your decisions` /
`review round 2 in progress` / `ready for review`. Include a line for
every open PR too, even ones with nothing new to say (`nothing to do,
waiting on your review`), so the rundown is a complete picture, not just
the deltas. If nothing is active at all, say so in one line (`no open PRs,
no ready tickets`).

Then send exactly one `PushNotification` for the whole cycle — never more,
regardless of how many checkpoints were hit or agents dispatched during
it. Keep it to the tool's own one-line/200-character limit; it exists to
point at the rundown, not to contain it, e.g. `"Kanban cycle: 3 agents
active, 1 needs your OK — see session"` or, when nothing needs attention,
something as minimal as `"Kanban cycle: all quiet, 2 PRs open"`. Do not
send any other `PushNotification` mid-cycle — a subagent reaching a
checkpoint, a PR opening, or anything else that happens between the start
and end of a cycle gets folded into this one end-of-cycle rundown and
push, not announced separately.

## Guardrails

- PR triage always comes before starting new work — never skip straight to
  step 5 because step 3 found nothing urgent-looking; check first.
- Never exceed `max_open_prs` or `max_stacked_prs` (currently 3 and 2 —
  i.e. at most 2 PRs may ever be stacked on each other at once), and never
  stack a new PR on one the user hasn't reviewed at least once yet — these
  are hard caps, not targets to approach.
- Only one ticket in the pre-Checkpoint-2 state at a time (step 1).
- Never dispatch a second agent onto a PR/ticket that already has one
  active — `ListAgents` first (step 3), every time, before dispatching.
- Never run `/ticket-pipeline` or PR-triage work inline in this session's
  own working directory — always dispatch via "Dispatch mechanics" as a
  worktree-isolated background `Agent` subagent, so work gets its own
  checkout and branch instead of touching whatever this orchestrator's own
  git state (or another dispatch's worktree) is doing. Worktree isolation
  is git-level only, not a separate test DB — see the residual-risk note
  under "Dispatch mechanics" before ever running specs directly in this
  session while a dispatch is active.
- No merge commits, ever — rebase only, same as `/ticket-pipeline`.
- Don't touch a PR that doesn't link a Notion ticket card — it isn't this
  automation's to drive.
- Every cycle ends with exactly one bullet-point rundown and exactly one
  push notification — never zero (no silent cycles), never more than one
  push per cycle (no mid-cycle notification spam for individual
  checkpoints or events).
