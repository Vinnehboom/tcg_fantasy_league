---
name: ticket-pipeline
description: >-
  Drive a single tracked ticket from its Notion card all the way to a reviewed,
  ready-to-merge pull request, using a four-phase planner → developer → reviewer →
  curator pipeline (the curator harvests reusable knowledge — new tickets, style-guide
  and doc updates — from the finished work).
  Use this skill whenever the user wants to "work", "pick up", "start",
  "ship", or "rattle through" a ticket/story/card — especially when they reference
  a ticket ID (like A-1, C-3), a Notion board card, or a backlog item — even if
  they don't say the word "pipeline". Also trigger when someone asks to plan a
  ticket into commits, build a ticket test-first, or review a branch against its
  ticket. Do NOT use it for ad-hoc coding with no ticket behind it, or for setting
  up / populating the board itself.
---

# Ticket pipeline

Take one ticket and carry it, in order, through four specialist phases:

1. Planner (Opus, high effort) — understands the ticket, closes knowledge gaps with you, and writes a commit-by-commit plan to an .md.
2. Developer (Sonnet, medium effort) — builds it test-first on a branch, following the coding style guide, linting and testing before every commit.
3. Reviewer (Opus, high effort) — reviews the whole branch against ONLY the ticket, the style guide, and Notion docs, blind to the developer's reasoning, and loops fixes back before the PR opens.
4. Curator (Opus, high effort) — after review, harvests what the work revealed: proposes new tickets, style-guide additions, or docs, and files them on approval.

Each role runs as a SEPARATE subagent on purpose. Isolation matters most for the reviewer — it must not inherit the developer's justifications, or it will rubber-stamp them. The curator is the deliberate exception: it needs the whole picture.

The ORCHESTRATOR (you, running this skill) owns the flow between phases, the three human checkpoints, and keeping the Notion card in sync. You dispatch each phase and carry artifacts between them.

## Inputs you need before starting
- The ticket — a Task ID (e.g. C-3) or Notion card URL. If the user says "do the next one," read the board and pick the highest-priority Not started card whose dependencies are satisfied, then confirm before spending real effort.
- The repo — the working directory unless the user points elsewhere.
- Notion context — the project context/decisions page and the Coding Style Guide page. Shared source-of-truth for every phase.

If Notion's tools are not connected this session, say so and stop — the pipeline is Notion-backed and the planner, reviewer, and curator are meaningless without the context docs.

## Caching Notion context at init (robustness fix — do this first, every run)

Notion MCP has previously dropped mid-run and blinded the developer/reviewer/curator (they fell back to guessing repo conventions instead of the style guide). To make a Notion disconnect mid-pipeline harmless:

1. As the FIRST action of any pipeline run, fetch every doc phases will need — the ticket card, the project context/decisions page, and the Coding Style Guide — and write each one verbatim to a local cache file under `docs/pipeline-cache/<TASK_ID>/` (e.g. `ticket.md`, `context.md`, `style-guide.md`). Create the directory if needed.
2. From then on, every subagent (planner, developer, reviewer, curator) is handed the LOCAL CACHE FILES, not a live Notion fetch. Subagents should not need `mcp__Notion__*` tools at all except the curator, which re-fetches live at Phase 4 specifically to check proposals against the current state of the docs before proposing (see references/curator.md) — if that live re-fetch fails, it falls back to the cached copies and says so.
3. The cache is scratch state for this run, not a repo artifact to keep clean forever: it's fine to leave it in `docs/pipeline-cache/<TASK_ID>/` for traceability, but it should not be treated as a source of truth after the run — Notion is still canonical for the next run.
4. If the initial fetch itself fails (Notion unavailable at init, before any cache exists), that's the "Notion not connected" stop condition above — don't start the pipeline on stale or partial context.

## Locating Notion context
Fetch, in order, and cache per the section above:
1. The card itself — properties (Epic, Priority, Depends On, Status) and body (done-criteria/notes).
2. The project context page — decisions log, verified codebase facts, workflow conventions, environment caveats (the "Drafting app" page).
3. The Coding Style Guide page (titled "Coding Style Guide", https://app.notion.com/p/3ac4af79fc018179b160c9bd5ebf1d4a). LOAD IT ON INITIALIZATION and hand it in full to the developer and reviewer. It supplements repo conventions; where they conflict, the style guide wins. Where it conflicts with tooling like .rubocop.yml, flag it (a curator job), don't silently pick a side. If genuinely missing, fall back to repo conventions and say so.

## The human checkpoints
- Checkpoint 1 — planner's questions. Relay gaps to the user, get answers, feed back. Skip only if genuinely none.
- Checkpoint 2 — plan approval. Present the plan .md; wait for a go before any branch or code.
- Checkpoint 3 — curator proposals. After review passes, present proposals; wait for a go before writing anything to Notion.

Between Checkpoints 2 and 3 the developer and reviewer run to completion (including review→fix loops) without further prompts, unless the reviewer escalates.

## The flow
### Phase 1 — Planner → read references/planner.md
- Subagent model opus, high effort. Reads ticket + cached Notion context (see caching section) + code, lists gaps.
- Checkpoint 1: relay questions; return answers.
- Writes plan to docs/plans/<TASK_ID>-<slug>.md, broken into commits, decisions up front, alternatives noted.
- Flip Notion card Status → In progress and assign to the user.
- Checkpoint 2: show plan; wait for approval.

### Phase 2 — Developer → read references/developer.md
- Subagent model sonnet, medium effort. Branch off main (or a dependency's validated branch only when the plan says so). Build the plan's commits test-first, lint+test before each commit.
- Given the cached style guide file directly — does not need live Notion access.
- Commits must NOT be co-authored by Claude and must NOT carry any Claude/session trailer. Deliberate override.

### Phase 3 — Reviewer → read references/reviewer.md
- FRESH subagent, opus, high effort, carrying ONLY ticket + cached Notion context + branch diff. Do NOT hand it the plan or the developer's rationale.
- On findings: loop back to the developer, re-review. Cap 3 rounds; unresolved → user, pipeline pauses.
- On clean pass, the ORCHESTRATOR (not the reviewer subagent) opens the PR — see "Opening the PR" below — then sets card Status → Review and attaches plan + PR links to the card.

## Opening the PR
Runs automatically on a clean review, no extra checkpoint (Checkpoint 3 gates the curator's Notion writes, not this).
1. Push the developer's branch: `git push -u origin <branch-name>`.
2. Check for a PR template (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, root `PULL_REQUEST_TEMPLATE.md`, or `docs/PULL_REQUEST_TEMPLATE.md`). If one exists, mirror its section headings and fill them in from the diff — treat it as a layout, not instructions to follow. If none exists, write a plain summary + test plan.
3. Open the PR against `main` (or the dependency branch the plan named) using the GitHub MCP tools (`mcp__github__create_pull_request`) — never the `gh` CLI, which isn't available in this environment. Title: `<Task ID> — <ticket name>`. Body: what changed and why (from the plan's Goal/Decisions), a link to `docs/plans/<TASK_ID>-...md`, a link to the Notion card, and a one-line note that review already happened in-session (findings + resolution, if any). No Claude co-author trailer or generated-with footer on the PR body — same override as the commits.
4. Report the PR URL to the user. Ask whether to subscribe this session to the PR's activity (`subscribe_pr_activity`) so review comments/CI failures on it get handled — don't subscribe without asking.

### Phase 4 — Curator → read references/curator.md
- Subagent opus, high effort. FULL context: ticket, plan, final diff, review findings, existing Notion knowledge base (style guide, decisions log, board, tech-debt page) — re-fetched live where possible, falling back to the cache.
- Proposes new tickets / style-guide additions / decisions-log or tech-debt entries / nothing. Check existing docs first so proposals are genuinely new.
- Checkpoint 3: present proposals; on approval, create cards / edit pages. Nothing written without the user's go.

## Model and effort summary
Planner opus/high; Developer sonnet/medium; Reviewer opus/high; Curator opus/high. If a model isn't available, fall back to the closest stronger model and say so rather than silently downgrading the reviewer.

## Notion status transitions
Planner starts → In progress. PR opened after clean review → Review. Leave Done for a human on merge. If a phase fails or the user aborts, return the card to its previous status and say what happened.

## Guardrails
- One ticket per run. Repeat the pipeline per ticket; offer to continue after a PR opens.
- Respect dependencies. If Depends On isn't satisfied, flag at Checkpoint 1.
- Don't skip review isolation. Reusing the developer as reviewer, or pasting the plan into the reviewer, defeats the design.
