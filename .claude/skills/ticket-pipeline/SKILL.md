---
name: ticket-pipeline
description: >-
  Drive a single tracked ticket from its Notion card to a reviewed,
  ready-to-merge pull request via a planner → developer → reviewer →
  gatekeeper → curator pipeline (live-verification/Tester is currently
  disabled — no Render PR-preview login set up yet). The gatekeeper keeps
  the PR a draft until it's rebased onto main, then marks it ready; the
  curator harvests follow-up tickets and doc updates afterward. Use this
  skill whenever the user wants to "work", "pick up",
  "start", "ship", or "rattle through" a ticket/story/card — especially
  with a ticket ID (like A-1, C-3), a Notion card, or a backlog item — even
  without the word "pipeline". Also trigger for planning a ticket into
  commits, building test-first, or reviewing a branch against its ticket.
  Do NOT use for ad-hoc coding with no ticket behind it, or for setting up
  / populating the board itself.
---

# Ticket pipeline

Take one ticket and carry it, in order, through six specialist phases:

1. Planner (Opus, high effort) — understands the ticket, closes knowledge gaps with you, and writes a commit-by-commit plan directly onto the Notion ticket card.
2. Developer (Sonnet, medium effort) — builds it test-first on a branch, following the coding style guide, linting and testing before every commit.
3. Reviewer (Opus, high effort) — reviews the whole branch against ONLY the ticket, the style guide, and Notion docs, blind to the developer's reasoning, and hands one round of fixes back before the PR opens. Kept at Opus deliberately: this is the one phase whose whole job is catching what a Sonnet-tier pass already missed, and downgrading it is where a cost cut would show up as real bugs reaching a PR.
4. Tester (Sonnet, medium effort) — once Render's PR-preview environment deploys, exercises the ticket's done-criteria against the live app with a real test account, capturing screenshots as evidence. **Disabled as of 2026-08-29 — no Render PR-preview login is set up yet. See Phase 4.**
5. Gatekeeper (orchestrator-run, no separate subagent) — keeps the PR a draft until the branch is rebased onto the latest main (never merged), then marks it ready for review. **Reduced scope as of 2026-08-29** alongside Phase 4 being disabled — see Phase 5.
6. Curator (Sonnet, high effort) — after review, harvests what the work revealed: proposes new tickets, style-guide additions, or docs, and files them on approval.

**2026-08-26 cost pass, partially reversed 2026-08-29:** Planner and Curator were both moved from Opus to Sonnet (effort kept at high) on 2026-08-26 — both are organizing/synthesizing existing context (the ticket, the diff, the docs) rather than the adversarial "find what's wrong" job the Reviewer does, so the effort level buys most of the quality that mattered here, at a fraction of the cost. **Planner moved back to Opus on 2026-08-29** — every downstream phase rides on its plan, and that's worth paying for directly rather than through rework later. Curator stays Sonnet. Reviewer stays Opus (unaffected either way — it was never part of this cut). If a Sonnet-tier Curator starts producing visibly worse proposals, that's the signal to move it back too — don't silently reduce effort level as a cut without checking the model level first.

Each role runs as a SEPARATE subagent on purpose (except the Gatekeeper, which is mechanical orchestrator work, not judgment work — see Phase 5). Isolation matters most for the reviewer — it must not inherit the developer's justifications, or it will rubber-stamp them. The curator is the deliberate exception: it needs the whole picture.

**This isolation is not optional and not a "best effort" — dispatch each phase as a genuinely separate subagent using the `Agent` tool with `isolation: "worktree"` (the same mechanism `.claude/skills/kanban-cycle/SKILL.md`'s "Dispatch mechanics" section documents and confirmed working end-to-end: a background `Agent` call with `isolation: "worktree"`, `run_in_background: true`, inherits this session's GitHub/Notion tool access instead of starting cold).** Standing correction, 2026-08-25: multiple past runs of this pipeline (B-2, C-4, C-5, C-17, C-6) shipped a PR whose body admitted "this environment's separate subagent-dispatch tooling was not used for a genuinely isolated reviewer pass... applied the reviewer checklist as rigorously as possible in-session instead." That is not a lesser version of this phase — it is the same session reviewing its own work, which defeats the entire point of Phase 3 and produces exactly the outcome isolation exists to prevent: on PR #56 (C-17), a bespoke admin API endpoint + wrapper service + JS-fetch flow shipped and passed this "in-session review" cleanly, then drew five separate design-level review comments from Vinnie asking for a plain RESTful redesign — findings a genuinely blind reviewer, checking the diff against the style guide and Decisions log with no attachment to the developer's reasoning, should have caught before the PR ever opened. If the `Agent` tool is ever genuinely unavailable in a given environment, STOP and tell the user plainly that the reviewer phase cannot run with real isolation rather than silently substituting an in-session pass and calling it equivalent — an honestly-skipped review is a smaller failure than a falsely-trusted one.

The ORCHESTRATOR (you, running this skill) owns the flow between phases, the three human checkpoints, and keeping the Notion card in sync. You dispatch each phase and carry artifacts between them.

**If you are yourself a dispatched worktree-isolated `Agent` subagent (e.g. kanban-cycle handed you this whole ticket to run), you cannot dispatch further `Agent` subagents — nested `Agent`-tool dispatch is not available to a subagent, only to the top-level session.** Confirmed 2026-08-26 (ticket H-1): a dispatched agent's `ToolSearch` for `Agent`/`Task` came back empty, and it correctly refused to substitute a Claude Code Remote session (already known-broken for MCP connector inheritance) or an in-session fake review. Do Phases 1 and 2 (planner, developer) yourself — they're just you doing research/writing code, no isolation requirement. When you reach Phase 3 (reviewer) — or Phase 4/6 if those also need a genuinely separate subagent — **stop, push whatever's pushable, and hand back to whichever session dispatched you** with enough context (branch name, PR if open, what phase you're handing off) for it to dispatch the isolated subagent on your behalf and relay the result back to you via `SendMessage`. This is a phase handoff routed through one extra hop, not a shortcut around the isolation requirement — the actual review must still happen in a fresh, blind context.

## Inputs you need before starting
- The ticket — a Task ID (e.g. C-3) or Notion card URL. If the user says "do the next one," read the board and pick the highest-priority Not started card whose dependencies are satisfied, then confirm before spending real effort.
- The repo — the working directory unless the user points elsewhere.
- Notion context — the Knowledge Base page, the Decisions database, and the Coding Style Guide page (pointers in `.claude/knowledge-base.json` and `.claude/coding-style.json` respectively — never hardcode these URLs, read the pointer files). Shared source-of-truth for every phase.

If Notion's tools are not connected this session, say so and stop — the pipeline is Notion-backed and the planner, reviewer, and curator are meaningless without the context docs.

## Commit identity
Every commit the developer makes must be authored as the repo owner's identity, not Claude's default:
```
git config user.name "Vinnehboom"
git config user.email "vinnie.schelfhaut.95@hotmail.com"
```
Set this repo-locally (not `--global`) at the start of Phase 2, before the first commit. Note: this is a real personal email, not a GitHub noreply address — it's visible in plain git history (`git log`, the GitHub API), not just masked in the UI. That's a deliberate choice made explicitly by the user, overriding the noreply-address default this skill used earlier. See references/developer.md.

**Commit signing:** the `.claude/hooks/session-start.sh` SessionStart hook configures repo-local SSH commit signing (`gpg.format ssh`, `user.signingkey`, `commit.gpgsign true`) automatically when the `TCG_FANTASY_LEAGUE_GIT_SIGNING_KEY` secret is set — that's what actually gets commits a "Verified" badge on GitHub, not the identity email above. This skill doesn't need to do anything extra for it; it's inherited from repo-local git config the hook already set up before Phase 2 runs. If that secret isn't set, commits are just unsigned — not an error, don't try to work around it mid-pipeline.

## Live-verification credentials
The tester (Phase 4) logs into the Render PR-preview app as a real user. Credentials come from environment secrets, never hardcoded in the skill or the repo:
- `TCG_FANTASY_LEAGUE_STAGING_TEST_EMAIL`
- `TCG_FANTASY_LEAGUE_STAGING_TEST_PASSWORD`

If either is unset, skip Phase 4 entirely and say so — don't attempt unauthenticated testing as a substitute, and don't ask the user to paste credentials into the conversation. Never print, log, or screenshot the password; the email appearing in a screenshot (e.g. an account page) is fine, it's a test account.

**Phase 4 is currently disabled outright (2026-08-29), independent of credentials — see Phase 4.** This section stays as reference for when Render access is configured and the phase is re-enabled.

## Caching Notion context at init (robustness fix — do this first, every run)

Notion MCP has previously dropped mid-run and blinded the developer/reviewer/curator (they fell back to guessing repo conventions instead of the style guide). To make a Notion disconnect mid-pipeline harmless:

1. As the FIRST action of any pipeline run, fetch every doc phases will need — the ticket card, the Knowledge Base page, the Decisions database, and the Coding Style Guide — and write each one verbatim to a local cache file under `docs/pipeline-cache/<TASK_ID>/` (`ticket.md`, `context.md`, `decisions.md`, `style-guide.md`). Create the directory if needed. Read the page/database pointers from `.claude/knowledge-base.json` and `.claude/coding-style.json` — never hardcode them.
2. From then on, every subagent (planner, developer, reviewer, curator) is handed the LOCAL CACHE FILES, not a live Notion fetch. Subagents should not need `mcp__Notion__*` tools at all except the curator, which re-fetches live at Phase 6 specifically to check proposals against the current state of the docs before proposing (see references/curator.md) — if that live re-fetch fails, it falls back to the cached copies and says so.
3. The cache is scratch state for this run, not a repo artifact — `docs/pipeline-cache/` is gitignored. Never `git add`/commit it, even with a broad `git add -A`; it should not be treated as a source of truth after the run either — Notion is still canonical for the next run.
4. If the initial fetch itself fails (Notion unavailable at init, before any cache exists), that's the "Notion not connected" stop condition above — don't start the pipeline on stale or partial context.

## Locating Notion context
Fetch, in order, and cache per the section above:
1. The card itself — properties (Epic, Priority, Depends On, Status) and body (done-criteria/notes).
2. The Knowledge Base page (pointer: `knowledge_base_page.notion_page_url` in `.claude/knowledge-base.json`) — verified codebase facts, workflow conventions, environment caveats. Currently titled "Drafting app" in Notion — go by the pointer, not the title, in case it's renamed.
3. The Decisions database (pointer: `decisions_database` in `.claude/knowledge-base.json`) — structured log of non-obvious architectural/domain decisions, each row's Status marking whether it's Active, Superseded, or Rejected. Obey Active decisions (and note their rejected alternatives — don't re-propose something already ruled out); a Superseded row's replacement decision governs instead.
4. The Coding Style Guide page (pointer: `notion_page_url` in `.claude/coding-style.json`). LOAD IT ON INITIALIZATION and hand it in full to the developer and reviewer. It supplements repo conventions; where they conflict, the style guide wins. Where it conflicts with tooling like .rubocop.yml, flag it (a curator job), don't silently pick a side. If genuinely missing, fall back to repo conventions and say so.

The Tech Debt page (pointer: `tech_debt_page.notion_page_url` in `.claude/knowledge-base.json`) is companion reading, not part of the cached init context — only the curator (Phase 6) reads it, live, when checking whether a finding is already logged.

## The human checkpoints
- Checkpoint 1 — planner's questions. Relay gaps to the user, get answers, feed back. Skip only if genuinely none.
- Checkpoint 2 — plan approval. **Surface the plan's actual content in the chat, in full or faithfully summarized section-by-section — not a one-line "plan's ready, approve?"** A plan the human never really reads is not a checkpoint, it's a formality; skimpy surfacing here is how design mistakes (see the reviewer-isolation note above) reach code before anyone who'd object has actually seen them. Call out the **Convention check** section (see references/planner.md Step 2.5) explicitly and by name — any flagged deviation from a default pattern needs its own visible line, not a mention buried in a Decisions bullet — and ask directly whether it's acceptable, don't assume silence on it means yes. Wait for a go before any branch or code.

  **Standing convention, 2026-08-31 — self-approval carve-out:** the orchestrator may approve a plan itself, skipping the wait, but only when ALL of the following hold:
  - The plan's stated **Risk classification** (references/planner.md) is Low or Medium. High always waits for the user — no exceptions, regardless of how confident the orchestrator is.
  - The **Convention check** section is empty (genuinely "no deviations," not just unaddressed). Any flagged deviation always needs an explicit go; self-approval never covers it.
  - No collision with other in-flight work: no other in-flight ticket touches the same files/models, and every design decision in the plan either has no live alternative worth debating or is already settled by an existing Coding Style Guide rule or Decisions-database entry (cite the rule/entry — that's enough, it's not a fresh judgment call).

  A decision the plan makes purely by following already-documented Style Guide doctrine doesn't need to be flagged as a judgment call requiring sign-off — citing the rule is sufficient. When self-approving, still surface the plan in the next rundown so the record is visible, but proceed straight to Phase 2 without waiting on it. Any genuine ambiguity about which bucket a plan falls into defaults to waiting for the user — this carve-out removes uncontested busywork, it does not expand how much the orchestrator decides alone.
- Checkpoint 3 — curator proposals. After review (and live verification) passes, present proposals and wait for a go before writing anything to Notion. **Standing convention, 2026-08-31:** once approved, the orchestrator (not the curator subagent) performs the actual Notion writes — see references/curator.md's "After approval" for why.

Between Checkpoints 2 and 3 the developer and reviewer run to completion (including the one review→fix pass) without further prompts, unless the reviewer escalates. (Tester/Phase 4 is currently disabled — see Phase 4 — so it isn't part of this stretch right now.)

## The flow
### Phase 1 — Planner → read references/planner.md
- Subagent model opus, high effort. Reads ticket + cached Notion context (see caching section) + code, lists gaps.
- Checkpoint 1: relay questions; return answers.
- Hands back the plan as text — broken into commits, decisions up front, alternatives noted. Do NOT write it to a repo file (no `docs/plans/`).
- The orchestrator appends the plan to the Notion ticket card itself, under a `## Plan` heading (`notion-update-page`, `insert_content`, position `end`), then refreshes that ticket's cache file (see caching section) so the cache reflects the card with its plan attached — downstream phases that read the cache see it too.
- Flip Notion card Status → In progress and assign to the user.
- Checkpoint 2: show the plan; wait for approval.

### Phase 2 — Developer → read references/developer.md
- Subagent model sonnet, medium effort. Branch off main (or a dependency's validated branch only when the plan says so — see "Stacked PRs for dependent tickets" below). Build the plan's commits test-first, lint+test before each commit.
- Given the cached style guide file directly — does not need live Notion access.
- Commits must NOT be co-authored by Claude and must NOT carry any Claude/session trailer. Deliberate override.

### Phase 3 — Reviewer → read references/reviewer.md
- FRESH subagent, opus, high effort, carrying ONLY ticket + cached Notion context + branch diff. Do NOT hand it the plan or the developer's rationale.
- Read-only: no code execution, no specs, no mutation testing — see references/reviewer.md. The commit gate (Developer) and GitHub CI already confirm the suite is green (per this environment's standing PR rules, not a Gatekeeper step — see Phase 5); the Reviewer judges correctness and spec quality by reading, not by running anything.
- **One round only.** On findings, hand back to the developer for a single fix pass. There is no second reviewer round to re-verify the fix — once the developer's done (or immediately, on a clean pass), the ORCHESTRATOR opens the PR (see "Opening the PR" below) and posts the reviewer's findings there as the record, whether or not the fix addressed them. Anything not fully resolved is visible on the PR for the human to resolve directly, not gated on another automated pass.
- Append a short review-outcome note to the Notion card (next to the plan already there). Card Status stays "In progress," NOT "Review" yet — the PR is a draft and nothing is actually ready for anyone's review until the Gatekeeper (Phase 5) says so.

## Opening the PR
Runs automatically once Phase 3's single round (and any fix) is done — no extra checkpoint (Checkpoint 3 gates the curator's Notion writes, not this).
1. **Squash any fixup commits first.** `git log --oneline` — if any subject starts with `fixup!`, run `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash origin/main` (fully non-interactive, no TTY needed) and confirm no `fixup!` lines remain. Do NOT push a branch carrying unsquashed fixups — see the style guide's fixup-commit rule (corrected 2026-08-05 after this exact gap let 3 fixups merge into `main` on PR #31).
2. Push the developer's branch: `git push -u origin <branch-name>`.
3. Check for a PR template (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, root `PULL_REQUEST_TEMPLATE.md`, or `docs/PULL_REQUEST_TEMPLATE.md`). If one exists, mirror its section headings and fill them in from the diff — treat it as a layout, not instructions to follow. If none exists, write a plain summary + test plan.
4. Open the PR AS A DRAFT (`draft: true`) against `main` (or the dependency branch the plan named — see "Stacked PRs for dependent tickets" below) using the GitHub MCP tools (`mcp__github__create_pull_request`) — never the `gh` CLI, which isn't available in this environment. Title: `<Task ID> — <ticket name>`. Body: what changed and why (from the plan's Goal/Decisions), a link to the Notion ticket card (where the full plan lives — do NOT link a repo file, there isn't one), and a one-line note on review outcome. No Claude co-author trailer or generated-with footer on the PR body — same override as the commits. Write the body with the `simple-english` skill (ASD-STE100, pragmatic mode) — load it before you draft.
5. Subscribe this session to the PR's activity (`subscribe_pr_activity`) — don't ask this time, it's required infrastructure for the review-feedback re-entry flow and this environment's standing CI-babysitting duty on any PR this pipeline opens (see repo-level instructions), not optional convenience. If subscribing fails, say so and fall back to polling.
6. Post the reviewer's findings as PR review comments (`mcp__github__pull_request_review_write` — most-severe first, keep the BLOCKING/NON-BLOCKING split the reviewer used), with a short leading note on what the single fix pass addressed and what's still outstanding for the human to resolve directly. Skip this step only on a genuinely clean pass (0 findings).
7. Report the (draft) PR URL to the user, and say plainly that it's still a draft pending the Gatekeeper's rebase check (Phase 5) — and, if applicable, that outstanding review findings are waiting on the PR itself. CI is still expected to go green per this environment's standing PR rules, it just isn't a Gatekeeper gate while Phase 4 is disabled (see Phase 5).

## Stacked PRs for dependent tickets
GitHub shipped native Stacked Pull Requests to public preview in July 2026: a chain of PRs, each based on the one below it, reviewable independently and merged as a unit, with CI on every PR in the chain still running against `main`. Use this whenever a ticket's Depends On names another ticket whose branch/PR hasn't merged yet, instead of quietly nesting the dependency's diff inside this ticket's PR.

**What this environment can and can't do about it:** the full `gh stack` CLI extension (`init`/`rebase`/`sync`/`submit`/`merge`, and the agent skill install `gh skill install github/gh-stack`) requires the `gh` CLI, which is NOT available here — this environment only has the GitHub MCP tools, per its own instructions. The pipeline reproduces stacked-PR *structure* — a chain of PR base branches — with plain git + `mcp__github__create_pull_request`, which is what GitHub's stacking feature actually keys off (a PR whose base is another open PR's branch). That's enough for GitHub to recognize and render the chain as a stack; it just doesn't get the CLI's automated rebase/sync conveniences, or `gh stack view`'s visual navigator. If Vinnie wants that locally, installing `gh stack` himself is independent of what the agent does here.

**Mechanics:**
1. Phase 1 (Planner) already decides whether to branch off main or a dependency's branch (planner.md Step 1) — that decision is now also the PR-base decision, not just the git-branch decision.
2. Phase 2 (Developer): if branching off a dependency, `git fetch origin <dependency-branch> && git checkout -B <branch> origin/<dependency-branch>`, not main.
3. "Opening the PR" step 3: set `base` to the dependency's branch (not `main`) when that dependency's PR is still open. If the dependency has since merged, rebase this branch onto `main` first and open normally — never stack on a branch that no longer exists.
4. Say so explicitly in the PR body ("Stacked on #<dependency PR number> — merge that first") since there's no `gh stack view` here to show it visually.
5. **Merge order is always bottom-up.** Never merge a PR whose base is another still-open PR before that base PR merges. GitHub retargets a stacked PR's base to `main` automatically once its parent merges — that's the point of the feature — but merging out of order produces a broken diff regardless. If asked to merge a stack, confirm the dependency order first.

### Phase 4 — Tester (live verification) — DISABLED, read references/tester.md before ever re-enabling
**As of 2026-08-29 this phase does not run.** No Render PR-preview login is set up yet, so there's nothing for a live-verification pass to check. **Always skip Phase 4 unconditionally and go straight to Phase 5** — don't check credentials, don't check the diff for frontend surface, don't attempt it. `references/tester.md` and the subagent design below are left intact on purpose for a later iteration once Render access exists; re-enabling this phase is a deliberate skill edit (restore the dispatch logic below and Phase 5's evidence gate), not something to infer from credentials merely appearing.

<details>
<summary>Dispatch logic to restore when re-enabling (kept for reference, not currently run)</summary>

- Only runs if the ticket's diff has frontend-observable surface (views, controllers rendering something a browser would show, JS, CSS) AND both live-verification credentials (see above) are set. A backend-only diff (a service object, a model, a job, a rake task, an API-only endpoint with no view) has nothing for a browser-driven pass to exercise — skip this phase and say so plainly, same as a missing-credentials skip, no need to check credentials at all in that case. If credentials are missing but the diff does have frontend surface, skip this phase and say so — don't attempt unauthenticated testing as a substitute. Either way, go straight to Phase 5.
- Wait for Render's PR-preview deploy. Preferred: if subscribed to PR activity, wait for the webhook event carrying Render's deploy comment/status (don't poll). If not subscribed, check PR comments/statuses (`pull_request_read`, `get_comments` / `get_status`) for a URL matching a Render preview host, on a real wait mechanism (`ScheduleWakeup` or `send_later`) rather than an inline sleep loop. Give up after ~20 minutes, tell the user the preview never showed up, and skip to Phase 5.
- FRESH subagent, sonnet, medium effort, with Playwright (Chromium is pre-installed in this environment — do not run `playwright install`). Given: the ticket's done-criteria, the preview URL, and the two credential env vars (read at runtime, never pasted into the prompt or written to a file).
- Logs in as the test account, walks the ticket's done-criteria one by one against the live preview, screenshots each meaningful step, and notes pass/fail/observation per criterion. Read-only where possible; where the criterion requires creating data, prefer data that's obviously a test fixture (e.g. an obviously-named record) over mutating anything that looks like real seed data.
- Hands back: a short markdown report (done-criteria → pass/fail/observation) plus the screenshot files. Never includes the password in the report.
- The ORCHESTRATOR posts the report + screenshots to BOTH the PR (as a comment) and the Notion ticket card (as an attachment/section) — see "Posting live-verification evidence" below.
- A live-environment failure here is NOT part of the reviewer's one round — it's a separate signal. Report it to the user; don't silently fix-and-retry the same way the reviewer loop does, since this is evidence about the deployed app, not a code review finding the developer can just address blindly.

</details>

## Posting live-verification evidence
**Unused while Phase 4 is disabled — kept for when Tester is re-enabled.**
1. PR comment: post the tester's markdown report via the GitHub MCP comment tools, with screenshots attached (upload via the same mechanism used elsewhere for PR comment images in this environment; if none exists, describe the screenshot and attach the file so the user can view it, rather than silently dropping it).
2. Notion card: append a `## Live verification` section to the ticket card (`notion-update-page`, `insert_content`) with the same report; attach screenshots via `notion-create-attachment` if available, otherwise reference where the files can be found.
3. Both postings carry the same attribution footer convention as other GitHub posts in this environment (see repo-level instructions) — the Notion posting does not need one.

### Phase 5 — Gatekeeper (rebase gate + mark ready)
Not a subagent — mechanical orchestrator work, like "Opening the PR." Runs after Phase 3 (Reviewer) — Phase 4 (Tester) is currently disabled and no longer sits in front of this phase.

**Reduced scope, 2026-08-29:** the CI gate and testing-evidence gate that used to be steps 1–2 here are dropped, alongside disabling Phase 4 (Tester) — there's no live-verification evidence to gate on, and CI-red is still this session's job to fix, just via this environment's standing "drive a PR you opened to green" duty (see repo-level instructions) rather than as an explicit step in this skill. That duty is not optional just because it's no longer written here — a red or conflicted PR this pipeline opened is still this session's to fix, same as any other PR it owns. What remains below is git hygiene only: keep the branch current, then say go.

1. **Branch-currency gate — rebase only, never merge.** First, don't trust local `HEAD` at face value: local `HEAD` has been observed to revert to a stale pre-sync commit even right after a successful push, with no reflog entry that explains it (suspected container/session lifecycle effect, not a git operation gone wrong). Run `git fetch origin <branch>` and compare `git rev-parse HEAD` against `git rev-parse origin/<branch>`; if they differ, `git reset --hard origin/<branch>` before doing anything else in this gate — origin is the known-good state right after your own push. Then check main's currency the normal way: `git fetch origin main` and compare against the branch's merge-base. If main has moved: `git rebase origin/main` — NEVER `git merge origin/main` into the branch, this repo does not want merge commits anywhere in its history, in either direction. Re-run the commit gate (lint + the specs covering the rebased-in changes, per developer.md's scoped commit gate) after rebasing, since a rebase can surface real conflicts or behavior changes that a plain diff wouldn't — then let GitHub CI re-confirm full-suite green against the new commit on push; don't duplicate a full local run here. Force-push (`--force-with-lease`). This same rebase-only rule applies everywhere else this skill reconciles a branch with main — general merge-conflict handling in this environment, and the review-feedback re-entry flow below, both mean rebase, never merge.
2. **Mark ready for review.** Only once step 1 passes: un-draft the PR (`mcp__github__update_pull_request`, `draft: false`), set the Notion card Status → Review, and tell Vinnie it's actually ready now — this is the real "sending it off for your review" moment, not PR creation. Note plainly that this no longer implies CI was confirmed green by this skill itself — say what CI's actual state is if you know it.

See "Merge policy" below for how the PR itself eventually gets merged.

## Merge policy
No merge commits, anywhere. When a PR in this pipeline is merged, always use `merge_method: "rebase"` on `mcp__github__merge_pull_request` — never `"merge"`, which creates a merge commit. `"squash"` is a separate call Vinnie can make per-PR if he wants it; rebase is this skill's default unless told otherwise. Stacked-PR merges still respect bottom-up order (see "Stacked PRs for dependent tickets") on top of this.

### Phase 6 — Curator → read references/curator.md
- Subagent sonnet, high effort. FULL context: ticket, plan, final diff, review findings, live-verification report (if Phase 4 ran), existing Notion knowledge base (style guide, Knowledge Base page, Decisions database, board, Tech Debt page) — re-fetched live where possible, falling back to the cache.
- Proposes new tickets / style-guide additions / Decisions-database entries (or a Status flip on an existing row, when this work supersedes it) / Tech Debt entries / nothing. Check existing docs first so proposals are genuinely new. A live-verification failure that couldn't be resolved in-session is exactly the kind of thing worth a follow-up ticket.
- Checkpoint 3: present proposals, wait for a go. Once approved, the orchestrator (not this curator subagent) performs the writes (create cards / edit pages), then tells the user what got filed. See references/curator.md's "After approval" for why the orchestrator does the write instead of the curator.

## Handling review feedback (re-entry)
A review comment on a pipeline-opened PR is NOT a quick ad hoc patch — rerun the pipeline's phases scoped to just that feedback, the same rigor as the original ticket at a smaller size, instead of editing the branch directly.

1. Trigger: a `<github-webhook-activity>` review-comment event on a PR this pipeline opened (requires having subscribed at "Opening the PR"). This event IS the "someone left feedback, go handle it" signal — don't wait for the user to separately ask.
2. Scope: read the comment(s) as a smaller version of Checkpoint 1's gap-finding. **Read ALL unresolved comments/threads on the PR at once, not just the one whose webhook just fired** — fetch the PR's full review-comment list before dispatching, and hand the whole set to one round. Standing instruction, 2026-08-26: a fixed cost (session-start hook, fresh Notion cache, re-grepping the codebase, a full test run) attaches to every dispatch regardless of how small its scope is, so reacting to one comment at a time when three arrived within the same review multiplies that cost for nothing — a token-usage audit found this exact pattern (rebase, then a rename, then a redesign, then its implementation, all on the same PR, each its own dispatch) driving the majority of one session's usage. If the ask is unambiguous, move straight to a short mini-plan covering everything outstanding; if genuinely ambiguous, ask — Checkpoint 1 still applies, just scaled to the size of the feedback.
3. Mini-plan (Phase 1, scoped): a short addendum to what the feedback asks for and the commit(s) it implies, appended to the SAME Notion card's existing `## Plan` section — not a new plan from scratch. Checkpoint 2 still applies: show it, wait for a go, before touching code, even for a one-line fix. Rerunning the skill means the checkpoints come with it, not just the code-producing phases.
4. Developer (Phase 2, scoped): new commit(s) on the SAME branch, addressing only the feedback, test-first, same lint+test gate before each commit as always. If any of these are `git commit --fixup=<sha>` against a commit already on the branch, squash before pushing — same non-interactive `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash origin/main` as "Opening the PR" step 1, and same rule: no `fixup!` commit ever reaches the pushed branch.
5. Reviewer (Phase 3): re-reviews the WHOLE branch again, not just the new commits — a fix for one comment can break something the first pass already approved. Same blind, read-only rules: fresh subagent, no plan, no developer rationale, no running anything. Same one-round rule: findings go back to the developer for one fix pass, then straight to the PR — no second re-entry review round.

   **Narrow exception, orchestrator's own call, not a subagent's:** skip the fresh dispatch and verify the round's diff directly instead (read it, reason about it, done) when ALL of: the round's diff is small (a handful of files, not a redesign), it's a mechanical or tightly-scoped change (comment trimming, a redirect target, mirroring an existing already-shipped pattern elsewhere in the same codebase — not new business logic), and the branch's last full Reviewer round already confirmed the rest of the branch sound. Used three times in C-27/C-7's generation-7 rounds (a comment-only trim, a one-line redirect fix, a byte-for-byte mirror of `Admin::ExternalRequestsController`'s tab pattern) with no issues missed. This is a cost call, not a rigor downgrade — if the diff introduces anything genuinely new (a new method, a new validation, new branching logic), that's not this case; dispatch the fresh Reviewer as normal. When in doubt, dispatch — the exception is for when a full Opus pass would clearly be reviewing something it already reviewed, not a way to skip review on new work.
6. Tester (Phase 4): disabled — skip, same as the first pass (see Phase 4).
7. Gatekeeper (Phase 5): re-runs its branch-currency gate against the new commits before calling the round done — a fix isn't "handled" just because it was pushed. Skip it only if it already passed earlier in the same round and nothing pulled from main in between.
8. Curator (Phase 6): only worth rerunning if the feedback + fix revealed something genuinely new to capture — skip it for a purely mechanical round (e.g. a rename) rather than re-checking the knowledge base for nothing.
9. Reply on the PR thread once the round resolves the feedback (per this environment's PR-babysitting conventions) — the pushed commits are the record, the reply is just the "handled" signal.

## Model and effort summary
Planner opus/high; Developer sonnet/medium; Reviewer opus/high; Tester sonnet/medium (**disabled**, see Phase 4); Gatekeeper — orchestrator, no subagent/model of its own, git hygiene only (see Phase 5); Curator sonnet/high. If a model isn't available, fall back to the closest stronger model and say so rather than silently downgrading the reviewer. Reviewer is the one phase that must not be downgraded further as a future cost cut without the user explicitly signing off — see the 2026-08-26 cost pass note above.

## Notion status transitions
Planner starts → In progress. PR opens as a draft after clean review — card stays In progress. Gatekeeper marks the PR ready for review → card moves to Review. Leave Done for a human on merge. If a phase fails or the user aborts, return the card to its previous status and say what happened.

## Guardrails
- One ticket per run. Repeat the pipeline per ticket; offer to continue after a PR opens.
- Respect dependencies. If Depends On isn't satisfied, flag at Checkpoint 1.
- Don't skip review isolation. Reusing the developer as reviewer, or pasting the plan into the reviewer, defeats the design.
- Never hardcode the live-verification credentials anywhere (skill files, commits, PR bodies, Notion pages, logs) — env vars only, read at the point of use.
- Stacked PRs merge bottom-up, always. Never merge a PR based on another still-open PR before that base merges.
- A review-feedback re-entry round doesn't skip Checkpoints 1/2 just because it's smaller than a full ticket — they still apply, scaled down.
- No merge commits, anywhere. Reconciling a branch with main is always `git rebase`, never `git merge`; PR merges always use `merge_method: "rebase"`.
- A PR doesn't leave draft state without the Gatekeeper's explicit say-so. Don't undraft one manually mid-pipeline as a shortcut, even under time pressure.
