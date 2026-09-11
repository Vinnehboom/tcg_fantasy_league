# Orchestrator handoff note

Written by `/handoff`. Overwritten at each handoff — this describes the
present, not the history. Durable lessons belong in the
`kanban-automation` plugin (`Vinnehboom/claude-automation`), not here and
no longer in `.claude/skills/`.

**Generation:** 12
**Predecessor session:** `session_01TszSKdDfJUu2bdj6dR6Y3V` (generation 11)
**Handoff trigger:** cost ceiling. Generation 11's `get_session` read
`cost_usd` $95.27 against `orchestrator_cost_ceiling_usd` $50 — well past
the line by the time step 0 caught it (a long unattended stretch running
three tickets through the pipeline back to back). Fold this into a
sharper mid-cycle re-check if it recurs — see "Pending automation work".
**Repo / branch:** `Vinnehboom/tcg_fantasy_league` · `main`.
`orchestrator_branch` in `.claude/kanban-cycle.json` reads `main` and is
current.

Everything not listed below is re-derived live by `/kanban-cycle` (board,
pull requests, active agents) or already written into the plugin's skill
files. Read those, not a summary of them.

## Open questions awaiting the user

None outstanding. Every question raised this generation (P-6's retention
window, P-6's Convention-check + file-overlap self-approval, P-3's
objection-route placeholder, P-6's Render cron tier) got a real answer
from Vinnie in session — see "In-flight nuance" for what each answer
means for reading current state correctly.

**Soft item, not a blocking question:** P-4 ("Legitimate interests
assessment and DPIA") and P-5 ("Record of processing, processor
contracts, breach procedure") were flagged to Vinnie as *possibly* not
coding tickets at all (paperwork/analysis, like P-1/P-13) but never
actually confirmed either way. Don't dispatch either to `/ticket-pipeline`
without checking first — ask Vinnie, or read the card closely for
something a PR could actually satisfy.

## In-flight nuance that live state would misread

- **Three ticket-linked PRs are open at once — #112, #113, #114 — one
  more than `max_open_prs` (2) allows.** This is a real process slip from
  this generation, not a state to "fix" by closing anything: P-3's PR
  (#113) opened mid-generation, pushing `open_count` to 2 (at cap) with
  #112 already open; P-6 had already been dispatched and stacked on P-3's
  branch by that point, and its PR (#114) opened without re-checking the
  cap against the now-larger count. **Do not dispatch a new ticket-linked
  PR until at least one of the three merges** — step 4's room check
  correctly reads `open_count = 3 >= max_open_prs = 2` right now, so this
  self-corrects the moment `/kanban-cycle` runs step 4 normally. The
  lesson (recompute `open_count` including a PR opened earlier in the
  *same* session, not just at cycle start, before dispatching the next
  ticket) is worth a line in `kanban-cycle` SKILL.md if it recurs — not
  filed this generation, cost ceiling.
- **#114 (P-6) is stacked on #113 (P-3)'s branch — merge #113 first,
  bottom-up, per the skill's stacked-PR rule.** #112 (P-12) is
  independent of both and can merge in any order relative to them.
- **#114 (P-6) has a real, known production gap, not a placeholder one:**
  its Render cron service needs a paid Render plan (cron services don't
  exist on the free tier, and the blueprint is `plan: free` throughout).
  Vinnie's explicit call, 2026-09-11: ship it anyway, track the Render
  upgrade separately. Until that upgrade happens, the retention job is
  defined but does not actually run in production — this is Vinnie's ops
  task, not something `/ticket-pipeline` can do, so there's no follow-up
  ticket to file for it.
- **P-2b (`Depends On` now `P-1`, not `P-2`) is the standing tracker for
  every bracketed placeholder across `/privacy`, `/terms`, and (as of this
  generation) `/player-information`** — widened twice this generation, once
  for P-3's placeholders and once for P-6's retention line. Its Notion
  card is current; nothing more to do until P-1 lands.
- **P-2c (new this generation) — "Write and review the Terms of Service
  copy" — is genuinely blocked on Vinnie supplying real, legally-reviewed
  text.** No dependency card produces this fact the way P-1 produces the
  entity identity; don't dispatch it expecting a plan to emerge, the
  planner will stop immediately for the same reason P-2b's first attempt
  did.
- **Standing policy, not yet in the Decisions database:** ship every
  compliance/legal-content ticket with bracketed placeholders for any
  fact this pipeline can't determine, paired with a blocking follow-up
  ticket per the 2026-09-10 Style Rule — never defer or hold the ticket
  waiting for real-world facts. Vinnie confirmed this directly, twice,
  this generation (on P-2b and again generalized to P-3/P-6-adjacent
  work). It should be a Decisions-database row so `/ticket-pipeline`'s
  planner cites it instead of re-deriving it each time — not filed this
  generation, see "Pending automation work".
- **A Stop-hook "uncommitted changes" nudge is not instruction to commit
  and push blindly.** Hit three times this generation (twice in
  dispatched worktrees, once in this orchestrator's own main checkout):
  `db:prepare`/`db:schema:load` dirtied `db/schema.rb` with a DIFFERENT
  open PR's not-yet-merged migration. Local `HEAD` matched `origin/main`
  correctly each time — the fix was `git diff db/schema.rb` to confirm
  the phantom change, then `git checkout -- db/schema.rb` to discard it.
  This is now documented in `kanban-cycle` SKILL.md's environment-facts
  list (see "Pending automation work" — already merged, not just
  proposed).

## Pending automation work

- **`Vinnehboom/claude-automation#12`** — already merged this generation
  (checked its `validate` check, green, merged via the repo's
  skill-files-only whitelist). Documents the `db/schema.rb` contamination
  hazard above, a `git worktree add -b` wrong-upstream hazard (a stacked
  dispatch's `git worktree add -b <branch> origin/<other-ticket's-branch>`
  silently set the new branch's push upstream to the OTHER ticket's
  branch — caught before the first push, this time), and generalizes
  "don't wait for the next scheduled firing" to apply whenever room opens
  up, not only mid-cycle after a merge. Nothing outstanding here.
- **Log the placeholder-over-defer policy above as a Decisions-database
  row.** Not done this generation (cost ceiling caught it first). Cite
  the 2026-09-10 Style Rule ("ship an unknown fact as a bracketed
  placeholder...") as the mechanism, and record that Vinnie has now
  confirmed it applies generally to compliance-ticket unknowns, not just
  the ticket it was first stated on.
- **Investigate a sharper mid-cycle cost-ceiling check.** This generation
  ran three tickets end-to-end (P-3 review+fix+PR, P-6 plan+build+review+
  fix+PR, plus triage on P-12) across a long unattended stretch before
  step 0 next got a chance to read `cost_usd` — by then it was nearly 2x
  the ceiling. Worth considering whether step 0's check should also run
  after finishing a ticket's Gatekeeper phase (PR opened), not only at
  the top of a scheduled cycle, given the new "don't wait for next cycle"
  eagerness this generation's `#12` PR just encoded. Not filed as a
  concrete skill change — flagging the question, not the answer.

## Recently merged (context, not a substitute for reading live state)

- `Vinnehboom/claude-automation#12` (this generation's lessons) — merged.
- Nothing on `tcg_fantasy_league` merged this generation — `#112`, `#113`,
  `#114` are all still open (see "In-flight nuance" above for why there
  are three at once).
