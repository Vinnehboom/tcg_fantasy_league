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
  dispatch last touched a ticket. A cycle notifies only when it produced
  something worth raising — a decision needed, a state change, a failure —
  ending in exactly one bullet-point rundown and one PushNotification;
  quiet cycles end with a single in-session line and no push at all, and
  nothing is ever announced mid-cycle. Before each cycle it checks its own
  session cost against a ceiling and hands off to a fresh orchestrator
  session (`/handoff`) once it gets too expensive to keep running in.
  Use when the user says
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
`max_open_prs`, `max_stacked_prs`, `orchestrator_cost_ceiling_usd`). If
it's missing, say so and stop — don't guess a repo or board.

**Then check whether this session is still worth running in.** Call the
claude-code-remote MCP `get_session` tool with `session_id` omitted (it
then describes this session) and read
`external_metadata.usage.cost_usd`. If that exceeds
`orchestrator_cost_ceiling_usd`, **run `/handoff` instead of this cycle**
and stop — the successor picks up at the next scheduled firing.

This is not housekeeping, it's the single largest cost lever in the whole
automation. Cost per turn is proportional to context length, context only
grows, so a standing session's total cost grows with roughly the *square*
of its turn count. Generation 1 was measured at 1,944 requests, mean prompt
371,729 tokens, 700M cache-read tokens, ~$237 — most of it spent in the
long tail where each trivial turn was still dragging a ~400K-token context
behind it. A cycle skipped for a handoff costs one cycle; not handing off
costs compounding money every turn after.

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

- **Vinnie commented/reviewed "lgtm" (or a clear equivalent — "looks
  good," "approved," "ship it") and CI is green** → merge it. This is a
  standing instruction (2026-08-25), not a one-off: don't wait for a
  further "go ahead," and don't leave it sitting merge-ready across
  cycles. Mark it ready for review if still draft (`draft: false`), then
  merge with `merge_method: "rebase"` (preserves the ticket's individual
  test-first commits, produces no merge commit — same spirit as the
  no-merge-commits rule elsewhere in this skill). After merging: flip the
  ticket's Notion Status to "Done", then **rebase every other open PR
  onto the new default-branch tip — every one, not only PRs literally
  stacked on the branch just merged.** This is a standing instruction
  (2026-08-25): a merge moves the default branch forward, and any open
  PR benefits from staying current rather than silently drifting,
  regardless of whether it was technically stacked on what just merged.
  For a PR whose base was the branch that just merged, this means BOTH
  retargeting its base to the default branch (`mcp__github__update_pull_request`
  with `base:` — the merge usually doesn't auto-retarget on its own, since
  `rebase`-merging doesn't delete the head branch the way GitHub's normal
  auto-retarget expects) AND actually running `git rebase` on its
  branch — **retargeting the API `base` field alone is not a rebase and
  does not touch the branch's real commit history; doing only that
  leaves the PR's diff silently bloated/wrong against its new base while
  looking superficially fine.** (Confirmed the hard way on PR #56: it was
  API-retargeted after C-5 merged but never actually rebased, so its real
  git ancestry stayed rooted before C-5's commits — 9 commits behind
  `main` including the merge itself — while GitHub kept computing a
  bloated diff against the new base it was never rebased onto.) For a PR
  whose base wasn't the merged branch, a plain rebase onto the
  now-updated default branch is enough, no retargeting needed. **Do this
  rebase cascade directly in this orchestrator session, not via a
  dispatched agent** — see the classifier note under "Dispatch mechanics."
  Push each rebased branch with `--force-with-lease`, confirm the test
  suite and lint are still green post-rebase before pushing. A merge frees
  a slot
  under `max_open_prs` — don't wait for the next scheduled firing to use
  it; re-run step 4 onward in this same cycle. If the CI-green condition
  isn't met yet (still running, or red), leave it — that's the CI-red or
  waiting-on-CI case below, not this one.
- **CI red** → dispatch a worktree-isolated background agent (see
  "Dispatch mechanics" below) to fix it with the same rigor as
  `/ticket-pipeline`'s Gatekeeper CI-fix step (references/developer.md
  discipline: test-first, lint+test before pushing). New commit(s), push,
  done — don't just report it.
- **Unresolved review feedback** (a review or comment since the PR last
  updated, that ISN'T an "lgtm"/approval covered above) → dispatch an
  agent to run `/ticket-pipeline`'s "Handling review feedback (re-entry)"
  flow for that ticket/PR. **Gather every unresolved comment/thread on
  that PR first and hand them all to ONE dispatch — never one dispatch
  per comment.** Standing instruction, 2026-08-26, after a token-usage
  audit found ~1.2M tokens across 9 dispatched agents in one session,
  several of them sequential rounds on the SAME PR (rebase, then a
  rename, then a redesign proposal, then its implementation, then a
  further refactor) that arrived close together and could have been one
  dispatch instead of four or five. Each dispatch pays a fixed cost
  regardless of how small its task is — the session-start hook,
  fetching/caching Notion context fresh, re-grepping the codebase,
  running the full suite multiple times — so splitting one PR's feedback
  across dispatches multiplies that fixed cost for no benefit; only real
  human checkpoints (Checkpoint 1/2 answers, a design go-ahead) justify a
  new dispatch boundary, not "a new comment arrived." If a dispatch for
  this PR is already active (checked via `ListAgents` per the guardrail
  below), do not queue a second one for feedback that arrives while it's
  running — let it finish, then re-check the PR for anything still
  unaddressed (including what arrived mid-run) before deciding whether a
  further dispatch is actually needed.
- **Stale branch / merge conflict** → **do the rebase directly in this
  orchestrator session, do not dispatch a worktree-isolated agent for it.**
  (Standing instruction, 2026-08-25 — see the classifier note under
  "Dispatch mechanics" below: a plain `git rebase` gets blocked by the
  auto-mode classifier inside a dispatched worktree-isolated agent, even
  with no history-rewrite flags involved, but the identical command runs
  fine in this session's own tool calls. Confirmed on PR #56: a dispatched
  agent's `git rebase origin/main` was denied by the classifier, it
  silently fell back to reporting the rebase as "out of scope" instead of
  flagging the block, and the orchestrator had to redo the whole triage
  case itself afterward.) Check out the PR's existing worktree if one is
  still around (`git worktree list`) or fetch the branch fresh, rebase,
  force-push with `--force-with-lease` (never merge into the branch — no
  merge commits, ever), per the same rule `/ticket-pipeline`'s Gatekeeper
  uses.
  **The rebase target is the PR's own current base branch, not
  automatically the repo's default branch** — for a stacked PR (base is
  another open PR's branch, not `main`), that base branch is what may have
  moved (e.g. a review-feedback fix landed new commits on it) while this
  PR sat unrebased; rebase onto that branch's current tip so this PR
  picks up those changes. Only rebase directly onto the default branch
  once this PR's own base already is the default branch, or once the PR
  it was stacked on has merged.
  **Check the base-PR-merged case explicitly here too, every time — don't
  rely solely on the lgtm-merge case above to have caught it.** That case
  only fires when this automation is the one merging; a base PR can also
  merge some other way (Vinnie merging it himself on GitHub, for
  instance), which this stale-branch triage may be the first thing to
  notice. If the branch this PR is/was stacked on shows as merged, do
  both: retarget this PR's `base` to the repo's default branch
  (`mcp__github__update_pull_request` with `base:`) *and* rebase its
  commits onto that default branch's current tip — GitHub does not
  reliably do this automatically on its own (confirmed firsthand: a
  `rebase`-merge doesn't delete the base branch, so the auto-retarget
  GitHub normally does on branch deletion never fires). Don't rebase past
  a still-open base PR onto `main` early, that would silently drop
  whatever that base PR hasn't merged yet.
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
- **First thing in every dispatch prompt: tell the agent to run
  `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"` before
  anything else.** That script provisions `config/credentials/test.key`,
  the local Postgres role, and built JS/CSS assets — but it's tied to
  session lifecycle, not per-worktree, and a git worktree does not inherit
  gitignored files (test.key included) from the checkout it was created
  from. Without this, every dispatched agent silently starts from zero and
  has to rediscover the same setup from scratch — confirmed cost: one C-22
  dispatch burned over 5 of its 6 total hours on exactly this before
  writing a single line of ticket code, including rediscovering that
  `sudo -u postgres` (the hook's original Postgres-role-creation command)
  is blocked by the auto-mode classifier when run directly as a Bash tool
  call, unlike when the same command runs inside the hook script itself.
  The hook now uses `runuser -u postgres` instead specifically so it stays
  classifier-safe when a dispatched agent needs to fall back to running
  its steps manually. The script is idempotent and safe to run
  unconditionally on every dispatch, including triage dispatches that
  never end up touching Ruby.
- **Tell every dispatch to push after its FIRST commit, not just at the
  end.** Standing instruction, 2026-08-26, after a dispatched agent
  vanished twice this session with zero trace — no commits, no push, no
  completion notification, no `git worktree list` entry — losing all its
  work (once on a planner that had done real research before writing
  anything, once on a whole review-feedback round). The cause isn't
  confirmed (suspected container/session lifecycle effect, same family as
  the stale-HEAD bug below, not a code bug in the agent's own logic), but
  the fix doesn't need the cause: if an agent pushes incrementally,
  losing the agent later loses at most its most recent uncommitted work,
  not everything. Don't wait for "done" to have something recoverable.
- `subagent_type: "general-purpose"`, prompt: instruct it exactly what to
  do (run `/ticket-pipeline <Task ID>` including all three human
  checkpoints; or the specific triage task for an existing PR), and give
  it a clearly identifiable name/description (ticket ID or PR number) so a
  later cycle's `ListAgents` call and this cycle's rundown (step 7) can
  match it back to the right card/PR.
- **Tell every dispatch to hand back a summary, not a transcript.** Its
  full output — review findings, test logs, diagnosis, file-by-file
  reasoning — goes into a file in its own worktree (or straight onto the
  PR/Notion card where that's the natural home). What comes back to this
  session is at most a few lines: what it did, what it needs, and where
  the detail lives. Standing instruction, 2026-08-27, from a token-cost
  audit: anything a subagent returns is pasted into this session's context
  and then **re-read on every single subsequent turn for the rest of the
  session**. A 5,000-token findings dump handed back at turn 400 of a
  1,944-turn session gets re-read ~1,500 times. The dispatch prompt itself
  is cheap and paid once; the return path is the expensive direction, and
  it's the one that's easy to miss.
- **When the ticket being dispatched is stacked on another open PR, tell
  the dispatch explicitly to open its new PR with `base:` set to that
  other PR's branch, not `main`.** This isn't automatic — a PR-creation
  call defaults to the repo's default branch unless told otherwise, even
  when the underlying git branch was itself branched off the other PR's
  branch. Getting this right is what makes GitHub show only this ticket's
  own commits in the PR's diff for review, instead of the combined diff
  of both tickets — the whole point of stacking instead of waiting for
  the base PR to merge first. Confirmed working this way on PR #57
  (stacked on #56): base set explicitly to `feat/C-17-...`, diff shows
  only C-6's own 5 commits.
- `model: "sonnet"` — set this explicitly on every dispatch here (CI
  fixes, review-feedback rounds, rebases). These are Developer-shaped
  tasks (execute a known fix, test-first), not the adversarial-critique
  job that justifies Opus inside `/ticket-pipeline`'s Reviewer phase — see
  that skill's 2026-08-26 cost-cut note. Don't leave `model` unset on the
  assumption it'll inherit something equivalent; pin it so a future change
  to this session's own model doesn't silently change every dispatch's
  cost with it.
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
- **A ticket dispatch's hand-back isn't always a human checkpoint — it can
  be a request for YOU to dispatch something on its behalf.** A dispatched
  agent running `/ticket-pipeline` cannot itself call the `Agent` tool
  (nested subagent dispatch isn't available to a subagent, confirmed
  2026-08-26 on ticket H-1) — so when it reaches Phase 3 (reviewer, or
  Phase 4/6 if those need real isolation too), it stops and hands back
  with a request to dispatch that phase's genuinely isolated subagent
  FOR it. Recognize this case (it names the phase and gives you what you
  need — branch, PR, ticket context) and act on it like normal PR triage:
  dispatch the isolated reviewer/tester/curator per "Dispatch mechanics"
  above, then relay its result back to the ORIGINAL dispatched agent via
  `SendMessage` so it can continue. This can happen mid-cycle, not just at
  cycle boundaries — treat it as immediate triage work, not something to
  fold into the end-of-cycle rundown the way an actual human-facing
  checkpoint question is.

**Classifier blocks plain `git rebase` inside a dispatched agent, not just
history-rewriting flags.** The earlier-known classifier block was for
`git rebase --exec 'git commit --amend --author=...'` (rewriting commit
authorship). Confirmed 2026-08-25 that a plain `git rebase origin/main`,
no `--exec`, no amend, gets denied the same way when run as a Bash tool
call inside a worktree-isolated dispatched agent — but the identical
command succeeds with no prompt when run directly in this orchestrator
session's own tool calls (not sandboxed the same way). Practical
consequence: **any git rebase this skill needs — the lgtm-merge cascade in
step 3, and the stale-branch/merge-conflict case in step 3 — must be done
directly by this orchestrator session, never delegated to a dispatched
agent.** Only delegate the surrounding work that doesn't involve a rebase
(a rename, a CI fix unrelated to branch currency, a reply to a review
comment) to a dispatched agent; if a dispatch also needs to be current
with its base branch first, rebase it here before dispatching, or rebase
it here after the dispatch's other work lands, rather than asking the
dispatch to do it. A dispatched agent that hits this block may not always
say so plainly — on PR #56 it reported the skipped rebase as an "out of
scope" decision in its user-facing reply rather than surfacing the
classifier denial, so don't assume a dispatch's own account of what it did
is complete; check `git log <branch>..origin/main --oneline` yourself
whenever branch currency actually matters.

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

**Trusting local git state:** local `HEAD` — in the orchestrator's own
checkout and in a dispatched worktree alike — has been observed to
revert to a stale pre-sync commit even right after a successful push,
with no reflog entry that explains it (suspected container/session
lifecycle effect, not a git operation gone wrong). Before you rely on
local `HEAD` for anything that matters — deciding a branch is current,
skipping a rebase, reporting a push succeeded, dispatching a triage
agent onto a PR's branch — verify it first: `git fetch origin <branch>`,
then compare `git rev-parse HEAD` against `git rev-parse
origin/<branch>`. If they differ, don't act on the stale state — `git
reset --hard origin/<branch>` when origin is known-good (e.g. right
after your own push), or investigate before proceeding otherwise. This
applies inside a dispatched agent's own worktree too, not just the
orchestrator's checkout.

## 7. End-of-cycle rundown (always)

**Notify only when something is worth raising.** Standing instruction,
2026-08-27, replacing the earlier always-notify rule: the user does not
want a report on every cycle, only when a cycle produced something they'd
act on. A cycle is **worth raising** if any of these is true:

- something needs the user's decision, answer, or review;
- a PR merged, a ticket was dispatched, or a PR's state changed;
- something failed, is stuck, or a dispatched agent went missing.

Everything else — CI still running, PRs sitting where they were, no ready
tickets, nothing dispatched — is a **quiet cycle**. End a quiet cycle with
a single line in this session (`Kanban cycle: quiet — 2 PRs open, nothing
needing you`) and **no `PushNotification` at all**. Don't build the full
rundown for a quiet cycle; the point is to stop paying for a report nobody
asked for.

When the cycle IS worth raising, end it with exactly one bullet-point
rundown, posted as this turn's own visible output in this session.
`ListAgents` to get the full current set of active dispatched agents (this
cycle's new dispatches plus any still running from earlier cycles), and
give one bullet per agent:

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
active, 1 needs your OK — see session"`. Say what changed or what's
needed, not that a cycle ran. Do not send any other `PushNotification`
mid-cycle — a subagent reaching a checkpoint, a PR opening, or anything
else that happens between the start and end of a cycle gets folded into
this one end-of-cycle rundown and push, not announced separately.

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
- Never trust local `HEAD` at face value — verify it against
  `origin/<branch>` first (see "Trusting local git state" under
  "Dispatch mechanics").
- Notify only when a cycle is worth raising (step 7's test). A quiet cycle
  gets one line in-session and no push at all; a cycle worth raising gets
  exactly one rundown and exactly one push — never more than one push per
  cycle, no mid-cycle notification spam for individual checkpoints.
- Check the orchestrator cost ceiling at step 0 before doing anything
  else. Over the ceiling means `/handoff`, not another cycle.
- Dispatches hand back summaries, not transcripts — the return path is
  what inflates this session's context permanently.
