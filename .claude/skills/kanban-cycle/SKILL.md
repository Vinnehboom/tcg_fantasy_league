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
  inline in its own working directory. Picked-up ticket work is dispatched
  as a background Agent-tool subagent on an isolated git worktree (own
  checkout, own branch — not a separate container or session) so a
  scheduled cycle can never collide with in-progress ticket work on the
  orchestrator's own checkout. In-flight detection reads real state (open
  PRs, Notion card status), not conversation memory, so it's correct
  regardless of which session or dispatch last touched a ticket. Every
  cycle ends with a PushNotification summarizing status,
  approvals needed, or questions. Use when the user says "run the board
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

Ticket work now runs in its own dispatched session (see step 6), not this
one, so this session's conversation is NOT a reliable record of what's
already running — a ticket could be mid-pipeline in a session this
orchestrator has never seen a message from. Check real state instead:

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
  pre-Checkpoint-2 state at a time. Note it in this cycle's summary as
  "still waiting on your OK for `<ticket>`" (you won't know which session
  to point the user at — that's fine, the ticket's own session already
  notified them when it reached that checkpoint) and move on to PR triage.

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

Open PRs always come before new work. For each open PR whose body links a
Notion ticket (i.e. one this automation is responsible for driving):

- **CI red** → fix it with the same rigor as `/ticket-pipeline`'s Gatekeeper
  CI-fix step (references/developer.md discipline: test-first, lint+test
  before pushing). New commit(s), push, done — don't just report it.
- **Unresolved review feedback** (a review or comment since the PR last
  updated) → run `/ticket-pipeline`'s "Handling review feedback (re-entry)"
  flow for that ticket/PR.
- **Stale branch / merge conflict** → rebase onto the repo's default branch
  only (never merge into the branch — no merge commits, ever), force-push
  with `--force-with-lease`, per the same rule `/ticket-pipeline`'s
  Gatekeeper uses.
- **Waiting on CI / waiting on the user** → nothing to do; just reflect its
  state in the cycle summary.

For open PRs that do NOT link a Notion ticket (opened by hand, not by this
automation): leave them alone — don't push to someone else's branch — but
list them in the summary since they still count against the PR cap.

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

## 6. Dispatch the ticket to a worktree-isolated background agent

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

Instead, dispatch `/ticket-pipeline <Task ID>` as a background `Agent`
subagent of THIS session, with `isolation: "worktree"`:

- `run_in_background: true` — a background Agent-tool call, not a new CCR
  session. Subagents inherit this session's tool access (GitHub, Notion —
  confirmed working: a Curator subagent dispatched this way successfully
  used live `mcp__Notion__*` calls with no special wiring) instead of
  starting cold with nothing, which is what actually made the checkpoint
  loop and every phase's Notion/GitHub work possible on A-1.
- `isolation: "worktree"` — gives the ticket its own git checkout and
  branch, isolated from whatever this orchestrator's own working directory
  is doing, without needing a wholly separate session/container to get
  that isolation. This is the actual property the old design was reaching
  for; it just reached for the wrong tool to get it.
- `subagent_type: "general-purpose"`, prompt: instruct it to run
  `/ticket-pipeline <Task ID>` exactly as documented, including all three
  human checkpoints. Since it's a subagent of this session (not a
  disconnected CCR session), route checkpoints through the normal
  subagent flow: it stops and its `<task-notification>` arrives back into
  THIS session when it needs an answer or reaches a checkpoint; relay to
  the user directly in this conversation, then `SendMessage` the answer
  back to resume it. This is materially faster than the old design's
  loop (dispatched session pushes a `PushNotification`, user has to find
  and reply in that session's own separate chat) — checkpoints land and
  get answered in the same place this cycle is already running. Still
  tell the dispatched agent explicitly not to assume anyone is watching
  live between its own tool calls — this session may itself be dormant
  between cron firings, so it should still be able to sit blocked on its
  own `<task-notification>` without doing anything destructive in the
  meantime.

**Residual risk this trade accepts:** worktree isolation is git-level
only — every worktree of this repo still shares one Postgres test
database. The old fully-separate-session design also gave a separate test
DB, which is what the "cross-branch test-DB pollution" bug this design
was originally built to prevent actually needed. The practical exposure
now is narrow (this skill dispatches at most one ticket per cycle, and
the orchestrator itself rarely runs `bundle exec rspec` directly outside
of skill-file verification work) but not zero: avoid running the test
suite in the orchestrator's own checkout while a dispatched ticket agent
is still active, and if collision symptoms ever show up (a stray
table/migration bleeding across branches, as seen before), that's the
first thing to suspect.

Do not dispatch a second ticket in the same cycle even if step 4 would
technically allow it — one new ticket picked up per cycle, so the user
doesn't get a wall of approvals at once.

## 7. End-of-cycle notification (always)

Every cycle ends with exactly one `PushNotification`, regardless of
whether anything happened — the user is relying on these 4 firings a day
as their check-in, not on remembering to look. Under 200 characters, lead
with what needs a reply if anything does:

- Plan awaiting approval → `"<ticket>: plan ready for your OK"`
- PR opened / now ready for review → `"<ticket> PR #<n> ready for review"`
- Question blocking a ticket → the actual question, compressed
- Nothing needed, just informational → brief state, e.g.
  `"PRs green, no ready tickets, 1 waiting on your review"`

## Guardrails

- PR triage always comes before starting new work — never skip straight to
  step 5 because step 3 found nothing urgent-looking; check first.
- Never exceed `max_open_prs` or `max_stacked_prs`, and never stack a new
  PR on one the user hasn't reviewed at least once yet — these are hard
  caps, not targets to approach.
- Only one ticket in the pre-Checkpoint-2 state at a time (step 1).
- Never run `/ticket-pipeline` inline in this session's own working
  directory — always dispatch it as a worktree-isolated background `Agent`
  subagent (step 6), so ticket work gets its own checkout and branch
  instead of touching whatever this orchestrator's own git state is doing.
  Worktree isolation is git-level only, not a separate test DB — see step
  6's residual-risk note before ever running specs directly in this
  session while a dispatch is active.
- No merge commits, ever — rebase only, same as `/ticket-pipeline`.
- Don't touch a PR that doesn't link a Notion ticket card — it isn't this
  automation's to drive.
- Every cycle ends with a push notification. No silent cycles.
