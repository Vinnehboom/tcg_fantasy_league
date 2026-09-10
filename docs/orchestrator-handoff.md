# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in the
`kanban-automation` plugin (`Vinnehboom/claude-automation`), not here and
no longer in `.claude/skills/`.

**Generation:** 11
**Predecessor session:** `session_01WjMuzgPXtaeURJmswzmGsd` (generation 10)
**Handoff trigger:** cost ceiling. Generation 10's `get_session` read
`cost_usd` $49.98 against `orchestrator_cost_ceiling_usd` $50 — close
enough to the line, with context at 600K/1M tokens and a container
restart plus a stuck subagent permission prompt already behind it, that
step 0 called it rather than waiting to technically cross $50 mid-cycle.
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` · `main`.
`orchestrator_branch` in `.claude/kanban-cycle.json` reads `main` and is
current.

Everything not listed below is re-derived live by `/kanban-cycle` (board,
pull requests, active agents) or already written into the plugin's skill
files. Read those, not a summary of them.

## Open questions awaiting the user

1. **P-2's Curator proposals (Checkpoint 3)** — presented to Vinnie in
   session, no go-ahead yet. If he approves, write these (the orchestrator
   writes, not a curator subagent):
   - Style guide addition: ship an unknown business fact (legal text, an
     address, a policy) as a clearly bracketed placeholder plus a
     blocking go-live follow-up ticket, rather than inventing it or
     blocking the current ticket. (Confirmed reusable — P-2b already
     exists in exactly this shape.)
   - Knowledge Base page note: a page with no single game (`/privacy`,
     `/terms`, `landing`) needs `render layout: 'no_header'`, because the
     header partial calls `game_root_path` and fails on a `nil` `@game`.
   - Tech Debt entry: this session's locally cached copy of the
     `kanban-automation` plugin is missing `boot.sh`, though
     `claude-automation#10` merged it upstream — broke UI capture on both
     P-2 and P-11 (`run.sh` exit 2, boot failure). **Possibly moot for
     you**: a fresh session (this one) reloads the plugin from the
     marketplace, so try a capture on the next ticket before assuming
     this is still broken — file the entry only if it recurs.
   - Tech Debt entry: a long Notion comment on a ticket card can silently
     truncate partway through (confirmed on P-2's reviewer comment, cut
     off after finding 5 of 10 — the same review posted in full as a
     GitHub PR review comment, so nothing was actually lost that time).
2. **P-11's Curator proposals (Checkpoint 3)** — presented, no go-ahead
   yet. If approved:
   - New ticket: "Sequence noindex before Disallow on the player pages" —
     `robots.txt`'s `Disallow: /*/players` stops a crawler from ever
     re-fetching a page, so it never sees a `noindex` tag added there;
     an already-indexed player URL stays indexed. Fix: ship `noindex`
     alone first, wait for a recrawl, then add `Disallow`. Depends on
     P-11 (done). Vinnie may instead choose "won't fix, accepted" — frame
     the card to allow that outcome.
   - Knowledge Base note: same `Disallow`-vs-`noindex` interaction,
     written as a durable fact for future SEO/privacy tickets.
   - Tech Debt entry: `yield :head` exists only in `_base.html.erb`, not
     `admin.html.erb` — a `content_for(:head)` block in an admin view is
     silently dropped. Low priority.
3. **P-12 needs a direct Checkpoint 2 go-ahead — not self-approved.** See
   "In-flight nuance" below for why the board won't show this waiting.

## In-flight nuance that live state would misread

- **P-12's Notion card Status still reads "Not started," but a complete,
  final plan is already written under its `## Plan` heading** (I wrote it
  myself, directly, after the dispatch that produced it got stuck on a
  permission prompt and never flipped the Status — see below). Checkpoint
  1 is already resolved (Vinnie's answers: no real SMTP, use
  `deliver_later` and file the missing config as tech debt; backfill
  `confirmed_at` from each row's own `created_at`, no real user data to
  protect; keep Devise's 30-minute session timeout default; strict 0-day
  confirmation grace period, no `allow_unconfirmed_access_for`) — **do
  not re-ask it.** The plan itself classifies the ticket **High risk**
  (touches sign-up/sign-in for every user) and explicitly does not
  self-approve at Checkpoint 2. Read the card's `## Plan` in full, then
  present it to Vinnie for a real go-ahead — don't dispatch a fresh
  Planner, the research and plan are already done and final.
  - Once Vinnie approves: dispatch a **fresh** Developer-phase agent
    (the original dispatch does not survive this handoff) pointed
    directly at the plan already on the card — branch
    `p-12-devise-hardening` off `main`, per the card's own "Branch" and
    "Commits" sections. Skip Planner, Checkpoint 1, and Checkpoint 2 in
    that dispatch's instructions; it should read the plan and start
    building.
  - Flip the card's Status to "In progress" yourself once you've
    presented it (Phase 1's own step, skipped by the interrupted
    dispatch).
- **No open pull requests right now** — both P-2 (`#109`) and P-11
  (`#110`) merged this generation, rebase-merged, Notion cards flipped to
  Done. Nothing for step 3 (PR triage) to do on `tcg_fantasy_league` at
  handoff time.
- **A dispatched subagent's tool call can sit blocked on a permission
  prompt even for a tool already in this session's own allowlist** —
  observed on a `mcp__Notion__notion-update-page` call during P-12's
  retry dispatch (writing its plan to the card), which left the whole
  session in `SESSION_STATUS_REQUIRES_ACTION` and burned a large share of
  this generation's budget before being noticed. If this recurs: a
  `get_session` call surfaces the stuck call's exact tool name and
  input under `pending_action` — if that tool is one this session already
  has allowed, the orchestrator can just call it directly with the same
  arguments to unblock and preserve the work, rather than waiting on it
  or discarding the dispatch. Worth writing into the plugin's dispatch
  mechanics if it happens a second time; not filed this generation (cost
  ceiling).

## Pending automation work

- Two lessons from this generation are candidates for a
  `claude-automation` PR but were **not** filed (cost ceiling, see above)
  — worth doing early next generation if budget allows:
  1. A plugin's local cache is a snapshot taken when a session starts (or
     last installed) and does not follow the plugin's own source repo
     mid-session — confirmed cause of the `boot.sh` capture failures
     above. Worth a line in `kanban-cycle` SKILL.md's environment-facts
     list, alongside the other "things that cost a cycle" notes.
  2. The stuck-permission-on-an-allowed-tool case just above, if it
     recurs.
- Nothing outstanding from generation 9's list — `claude-automation#10`
  and `#11` both merged, confirmed via git history on `main` of both
  repos.

## Recently merged (context, not a substitute for reading live state)

- `tcg_fantasy_league#109` (P-2 — privacy/terms pages) and `#110` (P-11 —
  robots.txt/noindex) both merged this generation. Their Curator
  Checkpoint 3s are the open questions above.
- `claude-automation#10` (boot harness) and `tcg_fantasy_league#106`
  (H-14 adoption) — both merged, predate this generation's own work.
