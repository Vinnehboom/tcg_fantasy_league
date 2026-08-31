---
name: handoff
description: >-
  Retire the current standing Kanban orchestrator session and hand its role to
  a brand-new session, so the automation keeps running without dragging a huge
  conversation context (and its per-turn cost) along with it. Writes a compact
  handoff note, spawns the successor session, and has the successor re-point
  every recurring Routine at itself before the predecessor stands down. Use
  when the user says "hand off the orchestrator", "cycle the orchestrator",
  "start a fresh orchestrator", "/handoff", or when `/kanban-cycle`'s own
  cost-ceiling check (step 0) says this session has got too expensive to keep
  using. Do NOT use it to start a second parallel orchestrator — this is a
  replacement, not a fan-out — and do not use it for handing a single ticket
  to a subagent, which is `/ticket-pipeline`'s job.
---

# Orchestrator handoff

A standing orchestrator session burns more tokens every turn it lives.
Tokens per turn are proportional to context length, and context only grows,
so a session's total consumption grows roughly with the *square* of its turn
count. Measured on the first orchestrator generation: 1,944 requests, mean
prompt 371,729 tokens, 700M cache-read tokens. The same work at a capped
context would have used a fraction of that.

**What that actually costs depends on the plan.** On a subscription there is
no per-token bill — the constraint is the rate-limit window, and
`get_session`'s `external_metadata.rate_limit_info` is where it shows up
(`rateLimitType`, `status`, `resetsAt`). Generation 1 drove the account to
`allowed_warning` on a seven-day window. So the thing being conserved here is
**capacity**: how much orchestration fits in a window before the automation
gets throttled and scheduled cycles start failing. On usage-based API billing
the same tokens are money instead. Either way the lever is the same, but do
not tell the user they are "spending" money without knowing which plan they
are on.

This skill is the fix: retire the session, keep the role. Nothing about the
automation's behaviour changes — only which session runs it.

## Why this is cheap to do

The handoff note can be tiny, because almost nothing actually needs handing
over:

- **Board and ticket state** — `/kanban-cycle` already re-derives all of it
  from live sources (Notion board, open PRs, `ListAgents`) on every run, and
  its step 1 explicitly says conversation memory is NOT a reliable record.
- **Accumulated lessons and standing instructions** — already written into
  the skill files in `.claude/skills/`, which the successor reads fresh.
- **Environment caveats** (stale local `HEAD`, the classifier blocking
  `git rebase` inside dispatched agents, agents vanishing without trace) —
  also already in those skill files.

So the note carries only what genuinely cannot be re-derived: open questions
waiting on the user, work in flight that live state would misrepresent, and
anything learned since the last commit to the skill files. If you find
yourself writing more than a page, the lesson probably belongs in a skill
file instead — put it there and reference it.

## Steps

### 1. Fold new lessons into the skill files first

Anything this generation learned that should outlive it goes into the
relevant `.claude/skills/**/SKILL.md` (or its `references/`) now, as a
normal commit. This is the durable channel; the handoff note is not. A
lesson left only in the note will be lost at the *next* handoff.

### 2. Write the handoff note

Update `docs/orchestrator-handoff.md` (create it from scratch if absent).
Keep it short and current — it is overwritten each generation, not appended
to. It must contain:

- **Generation number** — increment it.
- **Predecessor session ID** — from `get_session` with `session_id` omitted.
- **Open questions awaiting the user** — anything the predecessor asked and
  never got an answer to. Without this the successor cannot know a question
  is outstanding, since it never asked it.
- **In-flight nuance that live state would misread** — e.g. a PR that looks
  stalled but is deliberately waiting, a ticket whose card status lags
  reality, a dispatch known to have vanished. Only real exceptions; do not
  restate what the board already says.
- **Pending automation work** — changes to the skill files that were agreed
  but not yet made. This is what "update the automations" means for the
  successor.

Commit and push it on the designated branch. The successor gets a fresh
clone, so an uncommitted note does not reach it.

### 3. Spawn the successor

Use the claude-code-remote MCP `create_session` tool (the server prefix is
session-specific — find it with `ToolSearch` rather than hardcoding it):

- `environment_id` — omit, so it inherits this session's environment. That
  is what carries the GitHub and Notion MCP connectors across; do not try
  to name an environment by hand.
- `source_url` and `source_revision` — **required, and the easiest thing to
  get wrong.** A new session clones the repo's *default* branch unless told
  otherwise. If the skill files live on a working branch rather than the
  default branch, a successor spawned without these comes up with no
  `/handoff` skill and a stale `/kanban-cycle` — an orchestrator missing the
  definition of its own job, which cannot even hand off again. Set
  `source_url` to the config's `repo` as a clone URL and `source_revision`
  to its `orchestrator_branch`. Before spawning, verify that branch actually
  carries the current skills (`git ls-tree -r --name-only <rev> -- .claude`)
  rather than assuming it.
- `model` — pin `"claude-sonnet-5"` explicitly. Triage and dispatch are not
  adversarial-critique work, and the expensive judgement in this system is
  already isolated in `/ticket-pipeline`'s Reviewer phase. Do not leave it
  unset and assume it inherits.
- `title` — `"Kanban orchestrator gen <N>"`.
- `permission_mode` — omit, so it inherits.
- `prompt` — the seed below.

Seed prompt, filled in:

```
You are the standing Kanban orchestrator for <repo>, generation <N>,
taking over from session <predecessor id>.

Do these in order, then stop and stay idle until a Routine fires:

1. Read docs/orchestrator-handoff.md in this repo.
2. Find your own session ID: the claude-code-remote MCP get_session tool
   with session_id omitted describes this session.
3. Re-point every recurring Routine at yourself. list_triggers shows them;
   each is currently bound to the predecessor via persistent_session_id.
   That field cannot be changed by update_trigger, so for EACH trigger:
   create a new one with the same name, the same cron_expression, the same
   prompt, and persistent_session_id set to your own session ID, then
   delete the old one. Create before deleting, so a failure leaves the
   automation running rather than stranded. Verify with list_triggers that
   the count is unchanged and every trigger now names you.
4. Re-subscribe to every open PR. PR subscriptions belong to the session
   that made them, and they die with it. List the repo's open PRs and
   call subscribe_pr_activity for each one this automation drives (any
   PR whose body links a Notion ticket card, plus any PR opened for the
   automation itself). Without this the successor never learns about a
   CI failure or a review comment on work already in flight.
5. Do the "pending automation work" listed in the handoff note.
6. Archive the predecessor: archive_session with its session ID. Only
   after steps 3 and 4 verified — an archived session that still owns
   triggers would silently drop every scheduled cycle, and archiving
   before re-subscribing loses PR events in the gap.
7. Report back in one short message: generation number, triggers
   re-pointed, PRs re-subscribed, automation work done. Raise anything
   that failed. Do not restate the board's state — the next scheduled
   cycle covers that.

Standing role from here: you run /kanban-cycle when a Routine fires, and
answer the user directly when they message you. Read
.claude/skills/kanban-cycle/SKILL.md when the first cycle fires — do not
read it now, it costs context you do not need yet.
```

The successor does the re-pointing, not the predecessor, for two reasons:
it knows its own session ID first-hand, and if it never runs, the triggers
still point at a live predecessor instead of nothing.

### 4. Report and stand down

Tell the user the successor's session ID and that the predecessor will be
archived by the successor once triggers are verified. Then stop. Do not
run another `/kanban-cycle` in the predecessor, and do not archive it
yourself — the successor owns that, and doing it early strands the Routines.

## Guardrails

- **Create every replacement trigger before deleting its original.** A
  delete-then-create ordering that fails halfway loses a scheduled cycle
  permanently.
- **Never archive the predecessor before `list_triggers` confirms the
  re-point.** Triggers bound to an archived session do not fire.
- **Carry the PR subscriptions across.** They are session-scoped, not
  repo-scoped, so every one dies with the predecessor. A successor that
  re-points its Routines but forgets this runs its cycles correctly and
  still goes deaf to CI failures and review comments between them.
- **The trigger count must not change** across a handoff. This project
  currently runs two daily cycles (08:00 and 17:30 BST) — confirmed via
  `list_triggers` at generation 4's handoff, correcting an earlier "four
  daily cycles" claim here that didn't match reality. Whatever the count
  actually is when you check, a handoff that leaves fewer is a silent
  regression. Count before and after — read it from `list_triggers`, don't
  assume a number written here.
- **One orchestrator at a time.** This replaces the session, it does not add
  one. Two live orchestrators would both triage the same PRs and dispatch
  duplicate agents onto the same branches.
- **Don't hand off mid-checkpoint.** If a dispatched agent is blocked
  waiting on an answer that only the predecessor's context can interpret,
  resolve it or write it into the note's open-questions section first — a
  subagent of the predecessor does not survive into the successor.
- **The note is overwritten, not appended.** It describes the present, not
  the history. Durable lessons belong in the skill files (step 1).
- **Never spawn a successor from a revision that lacks the current skill
  files.** Check before spawning, not after. A successor without
  `/handoff` and the current `/kanban-cycle` looks healthy — it starts, it
  answers, it has its connectors — but it silently runs the old automation
  and can never cycle itself again, so the failure only surfaces
  generations later. Getting the skills onto the repo's default branch
  removes this whole class of bug; pinning `source_revision` only works
  around it.
