# H-4 review — round 1

Branch: `h-4-feature-specs-salary-draft-participation-viewing` (4 commits, `686635a..b47833c`)
Diff: 4 new files, +80 lines, spec-only. No production code changed.
Reviewed read-only against the ticket, the cached Notion context/decisions/style guide, and the diff.

**Verdict: 1 BLOCKING, 6 NON-BLOCKING.**

---

## Done-criteria walk

Ticket: "each page above has a feature spec that covers its main flow", for
`salary_drafts` index + show and `participations` index + show (including the roster view).

| Page | Spec | Covered |
|---|---|---|
| salary_drafts#index | `spec/features/salary_drafts_index_spec.rb` | yes |
| salary_drafts#show | `spec/features/salary_drafts_show_spec.rb` | yes |
| participations#index | `spec/features/participations_index_spec.rb` | yes |
| participations#show + roster view | `spec/features/participations_show_spec.rb` | yes (roster view via `player.name` and `1 / 3`) |

All four pages have a spec. The letter of the done criteria is met. Finding 1 below is
about whether one of those specs actually pins what its name claims.

## Decisions database

Nothing in the cached Decisions table bears on this branch. It is spec-only, touches no
adapter, pricing rule, season, scorer, or external client. No Active row is contradicted
and no Superseded approach is reintroduced.

## Style guide

Checked and clean on the rules that apply:

- **"Feature-spec assertions check literal copy, not `I18n.t`/`I18n.l`"** — honoured. Every
  content assertion in all four files uses a factory-set value or a literal (`'1 / 3'`).
  `I18n.t('devise.sessions.sign_in')` appears only as a `click_button` locator, which the
  rule explicitly permits.
- **"Structure each example in four phases ... separated by blank lines"** — all four
  examples are Given / blank / When / blank / Then.
- **"Example names describe outcomes, not technical details"** — all four do. (See
  finding 3 for one name that describes more outcome than the example checks.)
- **"Limit assertions per example ... multiple expectations acceptable in
  request/integration specs"** — max is 5, under the repo's `RSpec/MultipleExpectations: 6`.
- **"No `let!`"** — no `let!` anywhere; three of four files use plain locals.
- **"Factories: deterministic base, randomized traits"** — the specs override the
  `salary_draft` factory's `rand(...)` price cap and roster size with literals, which is
  the right move for content assertions.

## Commit history

Good. Four commits, one new spec file each, ordered index → show → index → show, plain
imperative subjects, no `fixup!`, no mixed concerns. Each commit is plausibly green on its
own because each adds an independent spec file over unchanged production code.

---

# BLOCKING

## 1. `spec/features/participations_show_spec.rb:21-22` — the two "draft details" assertions cannot fail

The example is named "shows the draft's details and the participation's roster", and lines
21-22 are the half that is supposed to check the draft's details:

```ruby
expect(page).to have_content(salary_draft.price_cap.to_s)    # "250"
expect(page).to have_content(salary_draft.roster_size.to_s)  # "3"
```

Both are bare page-wide substring matches, and the roster view rendered lower down the same
page already emits both numbers on its own. `app/views/rosters/_roster.html.erb:46` renders
`"#{roster.players.count} / #{roster.draft.roster_size}"` → `1 / 3`, and
`app/views/rosters/_roster.html.erb:54` renders
`"#{roster.total_cost} / #{roster.draft.price_cap}"` → `0.0 / 250`.

Concrete failing scenario the spec would not catch: delete lines 19-30 of
`app/views/participations/show.html.erb` — the whole price-cap and roster-size block of the
draft-details table — and this spec stays green. `250` still comes from the roster partial's
total-cost line and `3` still comes from its roster-size line. The page would silently stop
showing the draft's details and CI would say nothing.

Line 22 is additionally subsumed by line 24 within the spec itself: `have_content('1 / 3')`
already guarantees a `3` on the page, so line 22 can never fail while line 24 passes. It is
dead weight as written.

Fix: scope the two assertions to the details table so they check the right element rather
than the page, for example

```ruby
within('table.table-bordered') do
  expect(page).to have_content(salary_draft.price_cap.to_s)
  expect(page).to have_content(salary_draft.roster_size.to_s)
end
```

Changing the literal values does not help here — the roster partial echoes whatever the
draft holds, so the assertions have to be scoped, not re-valued.

---

# NON-BLOCKING

## 2. `participations_index_spec.rb:18-19` and `participations_show_spec.rb:17-18` — sign-in has no synchronisation barrier

```ruby
click_button I18n.t('devise.sessions.sign_in')
visit game_participations_path(game:)
```

Both specs are `:js` (Cuprite). `click_button` returns once the click is dispatched; it does
not wait for the sign-in POST and its redirect to finish. The next line starts a fresh
navigation on top of that in-flight one. If the session cookie is not set yet, the
participations page hits `authenticate_user!` (`app/controllers/participations_controller.rb:3`),
redirects to the sign-in form, and `have_content(tournament.name)` fails.

The repo's own `spec/features/sign_in_spec.rb:13` has exactly the barrier these two drop —
it asserts the signed-in flash after `click_button`. That spec is not `:js`, so it does not
need it; these two are, so they do.

Failure mode is an intermittent red on CI that reproduces on nobody's machine. Fix: add
`expect(page).to have_content(I18n.t('devise.sessions.signed_in'))` between the
`click_button` and the `visit`. Both examples stay inside `RSpec/ExampleLength: 20`
afterwards (18 → 19 lines for the show spec).

## 3. `salary_drafts_index_spec.rb:4,6` — "upcoming" is in the example name but nothing tests it

The name promises "lists the game's upcoming salary drafts". The example creates exactly one
tournament, dated `1.year.from_now`, and checks its draft appears. Nothing distinguishes
upcoming from past, and nothing distinguishes this game from another.

Concrete failing scenario the spec would not catch: change
`app/controllers/salary_drafts_controller.rb:4` from `@game.upcoming_drafts.page(...)` to
`SalaryDraft.all.page(...)` — both the "upcoming" filter and the game scope are gone, and
this spec still passes.

The `starting_date: 1.year.from_now` on line 6 reads as if it is doing work in the example,
but its only job is to keep the draft inside the `upcoming` scope — that is, to avoid the
one behaviour the name claims to cover. This brushes the style guide's "No tautological
specs".

`spec/features/tournaments_index_spec.rb` has the same shape, so this is consistent with
existing precedent rather than a new mistake. Cheapest strengthening is one extra line: a
second draft on a past-dated tournament, plus `expect(page).to have_no_content(...)` for it.

## 4. `participations_index_spec.rb:8-11` — the game scope is never exercised

Both participations are built on tournaments in the same `game`, so only the
`current_user.participations` half of `ParticipationsController#index` is tested. The
`.where('tournament.game': @game)` clause on `app/controllers/participations_controller.rb:8`
could be deleted outright and this spec stays green.

The plan's stated intent for this example is user scoping, and it does that well. But the
page is game-scoped by URL, and giving `other_tournament` a second game costs one line
(`create(:game, id: 'RIFT')` or similar) while making the same two assertions cover both
filters at once.

## 5. `participations_index_spec.rb:21-22` — negative assertion first, without the reason that justifies it elsewhere

```ruby
expect(page).to have_no_content(other_tournament.name)
expect(page).to have_content(tournament.name)
```

`spec/features/players_index_spec.rb:31-36` uses this same ordering and carries a five-line
comment explaining why: there the page is already rendered and the negative is the only
assertion that waits for the Turbo round-trip to land. That reasoning does not transfer
here. This example does a plain `visit`, with no pending round-trip, so negative-first buys
nothing and gives up something: `have_no_content` is satisfied by any state in which the
text is absent, including a page that has not painted the table yet. Positive-first would
prove the participations table rendered before asserting what is missing from it.

Low probability in practice because Cuprite's `visit` blocks on page load, but the ordering
is strictly worse than the alternative and, unlike `players_index_spec`, carries no comment
saying why it was chosen. A reader coming to this file cold will assume the
`players_index_spec` rationale applies.

## 6. `participations_index_spec.rb:15-18`, `participations_show_spec.rb:14-17` — third copy of the sign-in block

The `visit new_user_session_path` / `fill_in` / `fill_in` / `click_button` block now appears
three times: `sign_in_spec.rb:7-11` and both new files. The style guide's Structure rule says
duplication is fine through the first two occurrences and to reassess on the third. This is
the third. A `sign_in_as(user)` helper in `spec/support/` would also give finding 2 a single
place to fix.

Not blocking — the rule says reassess, not extract, and `sign_in_spec.rb`'s copy is arguably
the subject under test rather than setup.

## 7. Small nits

- `participations_index_spec.rb:6` and `participations_show_spec.rb:8` —
  `create(:user, password: 'testtest')` is redundant. `spec/factories/users.rb:5` already
  defaults `password { 'testtest' }`. It does make the value visible next to the `fill_in`
  on the following lines, and `sign_in_spec.rb:4` does the same, so this is defensible; it is
  still a value repeated in two places that must agree.
- `participations_index_spec.rb:9` — `'Someone Else\'s Regionals'` escapes a quote where
  `"Someone Else's Regionals"` would not need to. Rubocop's `single_quotes` style accepts a
  double-quoted string that contains an apostrophe. The same branch already uses the
  double-quoted form for the same problem at `salary_drafts_index_spec.rb:4`, so the two are
  inconsistent with each other.
- `salary_drafts_index_spec.rb:6` uses `1.year.from_now` (a time) for a `date` column, where
  `tournaments_index_spec.rb:6` uses `1.year.from_now.to_date`. Harmless — Rails casts it —
  but it diverges from the neighbouring spec for no reason.
- `salary_drafts_show_spec.rb:12-13` and `salary_drafts_index_spec.rb:12-13` share the milder
  form of finding 1: `have_content('250')` and `have_content('4')` are page-wide substring
  matches on numbers that render as bare `<td>` values in adjacent rows
  (`app/views/salary_drafts/show.html.erb:27,33`; `app/views/salary_drafts/_table.html.erb:30,33`).
  Swapping those two `<td>` bodies leaves both specs green. Less severe than finding 1
  because nothing else on those pages is guaranteed to supply the numbers, but scoping with
  `within` or `have_css('tr', text: ...)` would make them real. `have_content('4')` in
  particular is a single character matched against the whole page.

---

## What is good

Worth saying plainly, because it is most of the branch:

- The four files are the right four files, named to the repo's existing
  `<resource>_<action>_spec.rb` convention, one per commit.
- The literal-copy rule from the style guide (added 2026-08-29 after commit f2df4e9 fixed
  this exact mistake) is followed correctly, including the subtle part — `I18n.t` kept as a
  locator but never as an expected value.
- `participations_index_spec` picks the right behaviour to demonstrate. User scoping is what
  that page is for, and testing it with a real second user's participation rather than an
  empty-list check is the stronger choice.
- `participations_show_spec` is right to assert `player.name` and the `1 / 3` fraction
  instead of the computed cost. `RosterPlayer#decorated_player_cost` runs through
  `Players::CostCalculator` and a pricing rule; pinning its output here would couple a view
  spec to pricing internals that other Active decisions are actively changing.
- Deterministic literals replace the `salary_draft` factory's `rand` defaults everywhere
  they are asserted.
- Commit history is clean and each commit stands alone.
