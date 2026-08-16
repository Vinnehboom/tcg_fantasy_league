# A-8 — Soft deletion for ExternalRequest audit rows

Source: https://app.notion.com/p/3b14af79fc0181e78e61f922bcd3bd31

## Properties
- Task ID: A-8
- Epic: A - Import infrastructure
- Priority: Normal
- Status: Not started (at pipeline start)
- Depends On: A-3 (Done, merged to main via PR #29)

## Card body

Add real soft-deletion for `ExternalRequest` (e.g. a `deleted_at` column + default-scope
exclusion, or an existing gem convention if one gets adopted elsewhere first — pick one and
justify against the repo's existing gems, don't add a new gem just for this) so admin
fetch-history views (A-6) can hide/retire noisy or bad audit rows without physically deleting
them, and so the FK-restrict workaround on `Game`'s association (`dependent:
:restrict_with_error`, added in A-3/D5 specifically to stop audit rows from being destroyed as
a side effect of deleting their parent) has a real deletion path instead of just blocking
`Game` destruction forever.

**Done:** a soft-deleted `ExternalRequest` is excluded from default queries but recoverable;
hard delete is no longer the only way to remove a bad audit row.

*Raised 2026-08-03 while planning A-3, per Vinnie's request.*

## Plan (posted to Notion card as a comment — see "Notion write permission" note below)

**Checkpoint 1:** No open questions requiring a human answer. The one genuine fork in this
ticket — hand-roll `deleted_at` + scopes vs. adopt an existing soft-deletion gem — was already
resolved by Vinnie's direct steer mid-planning: use an existing gem (`discard` or
`paranoia`/`acts_as_paranoid`), not a hand-rolled implementation.

### Goal
Give `ExternalRequest` real soft-deletion: a discarded row is excluded from default queries but
recoverable, so a bad/noisy audit row can be retired without physically destroying it, and so
`Game`'s `dependent: :restrict_with_error` (A-3/D5) stops being a permanent block once a game's
audit history has all been discarded.

Done when: a spec proves a discarded `ExternalRequest` is excluded from `ExternalRequest.all`
and from `Game#external_requests` by default, is reachable and restorable via an explicit
"include discarded" query, and that hard `#destroy` still works as a separate, unaffected path.

### Decisions
- D1 — Use the `discard` gem (2.0.0), not a hand-rolled `deleted_at` implementation, and not
  `paranoia`/`acts_as_paranoid`. No soft-deletion gem or hand-rolled pattern exists anywhere in
  the repo today. `discard` (MIT, `activerecord >= 7.0, < 9.0`, compatible with Rails 7.1.3,
  actively maintained) is a small `include Discard::Model` concern: `discarded_at` column,
  `kept`/`discarded` scopes, `#discard`/`#undiscard` (+ bang variants), `#discarded?`/`#kept?`
  — and does NOT override `#destroy` (unlike `paranoia`, rejected for exactly that reason —
  too much magic, makes hard delete a special case instead of the Rails default).
- D2 — Column stays `discarded_at` (gem's default name), not the card's illustrative
  `deleted_at` example.
- D3 — Add `default_scope -> { kept }` explicitly on `ExternalRequest` (discard does not do
  this by itself). Satisfies "excluded from default queries" for `ExternalRequest.all` /
  `Game#external_requests` / future Kaminari `.page` calls without every call site opting in.
  Trade-off: reaching a discarded row needs `.with_discarded`.
- D4 — Emergent `Game` interaction, no `Game` code change needed: default_scope means
  `dependent: :restrict_with_error`'s existence check only counts kept rows, so once every
  `ExternalRequest` under a `Game` is discarded, `Game#destroy` is no longer blocked. Spec in
  `game_spec.rb` proves it.
- D5 — No new wrapper methods on `ExternalRequest` — use `discard`'s own verbs directly.
  `RequestRecorder` untouched (only ever creates rows, never discards).
- D6 — Index the new column (`discarded_at`) — unlike A-3's deferral, the query shape here is
  concrete and universal (every query filters on it via default_scope).
- D7 — I18n: add `activerecord.attributes.external_request.discarded_at`.

### Branch
`feat/A-8-soft-delete-external-requests`, cut from latest `origin/main` (not stacked on A-6,
which is unmerged; A-8 depends only on A-3).

### Commits
1. "Add discard gem to ExternalRequest" — Gemfile/Gemfile.lock (`bundle add discard`),
   migration (`discarded_at:datetime`, indexed), model (`include Discard::Model`,
   `default_scope -> { kept }`), locale entry, factory `:discarded` trait,
   `external_request_spec.rb` (default scope exclusion, `.with_discarded` reachability,
   discard/undiscard round-trip, real `#destroy` still works), regenerated `db/schema.rb`.
2. "Cover Game destroy once its audit trail is fully discarded" — `game_spec.rb` only, no
   production code: new context proving a `Game` whose only `ExternalRequest` is discarded is
   no longer blocked from destruction. Developer must verify discard's actual API
   (`bundle show discard`) before writing commit 1, not from memory.

Each commit: `bundle exec rubocop` + `bundle exec rspec` green before committing.

### Open alternatives
- Two commits vs. one (commit 2 is spec-only; developer's call if it feels too thin alone).
- No admin UI for restoring discarded rows in this ticket (A-6 unmerged) — model capability
  only, per done-criteria.
- Mixed kept/discarded `ExternalRequest`s under one `Game` still blocks destroy (implied by
  D3/D4, not separately spec'd unless cheap to add).

### Risks
- `discard` 2.0.0 is a recent release — verify exact scope/method names against the installed
  gem source, not memory.
- `default_scope` is a known Rails sharp edge — accepted deliberately per D3.
- No backfill concern — `discarded_at` nullable with no default, existing rows implicitly kept.

## Notion write permission note
`mcp__Notion__notion-update-page` (insert_content / update_properties) returned `MCP error
-32003: MCP tool call requires approval` on every attempt during this pipeline run —
`mcp__Notion__notion-create-comment` worked fine. The plan above was posted to the card as a
comment instead of the page body, and Status/Assign could not be flipped programmatically.
Needs the orchestrator/Vinnie to either grant that tool or apply those edits manually.

## Notes from surrounding context (verified in repo at cache time)
- `app/models/external_request.rb` (on `main`) currently has no soft-delete concept at all.
- `Game has_many :external_requests, dependent: :restrict_with_error` (`app/models/game.rb`).
- No soft-delete gem (`paranoia`, `discard`, etc.) is in the `Gemfile` on `main`. No
  `default_scope`/`deleted_at` pattern exists anywhere else in the repo to match.
- A-6 (Admin fetch-history views, PR #35) is still open/unmerged on `main` as of this cache —
  its `admin/external_requests` controller/views do not exist on `main`. A-8 depends only on
  A-3, not A-6, so this ticket should not assume A-6's admin code is present.
