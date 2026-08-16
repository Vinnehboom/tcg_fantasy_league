# Drafting app — project context (cached at A-8 pipeline start)

Source: https://app.notion.com/p/3a94af79fc0180f68bd6e37f39723fc8

# Multi-game player DB + placement-based scoring
**Status:** planning (approved direction, not yet implemented) · **Date:** 2026-07-26

## Session summary
Planning session output: a refactor of Pokémon TCG off fragile HTML scraping onto a reusable
multi-game import architecture (DI adapters + JSON client + batched jobs + `ExternalRequest`
audit log + admin pages), onboarding Riftbound (eloshowdown ELO API) as a second player DB,
and a clean domain split — ratings (CP/ELO) → `ExternalScore` → pricing, and tournament
placements → new `Result` model → scoring. Direction is approved; nothing implemented yet.
The board's 26 stories are the implementation plan.

## Decisions log (most recent wins)
- Scoring is placement-based, size-weighted, not a rating delta. New `Result` (player +
  tournament + placement + `field_size`); scorer weights placement by tournament size;
  encapsulated per game in a `Scoring::Strategy`. Old `Player#score_difference` retired.
- Cost from the season distribution — `CostCalculator` uses median & average of the
  game/season's `ExternalScore`s (new `Players::SeasonStats`), configurable per game.
- `ExternalScore` becomes an append-only time series — drop `(score, player_id)` uniqueness,
  append only on change, add nullable `season`.
- Seasons are per-game & configurable — Pokémon uses a season cutoff; Riftbound is seasonless.
- Pricing rules are an injected param, defaulting to `[Players::ScalingPriceRule.new]` — NOT
  a `Game#pricing_rules` method (rejected).
- Tournament results = one shared scraping pattern for both games via an adapter
  `results(tournament:)` contract + per-game `ResultsScraper` on a shared base. Riftbound
  results are in scope.
- Adapter is dependency-injected into `ExternalData::Interface` (`adapter: OfflineAdapter.new`
  default; contract is instance methods `players` + `upcoming_tournaments`). No branch
  anywhere selects an adapter — resolver service, frozen-hash registry, candidate array +
  predicate, `Game` DB column, and `safe_constantize` were all rejected (A-2 Checkpoint 1;
  tell-don't-ask framing). The game→adapter mapping lives in per-game composition roots.
- Imports run in a batched background-job layer, triggered from admin pages, every fetch
  recorded in a new `ExternalRequest` audit model. No request-cycle scraping.
- The fetch half is a per-host client plus an injected retry policy.
  `ExternalData::JsonApiClient.new(base_uri:, retry_policy:)` is a plain reusable object.
  `ApplicationService`/`.call` was considered and rejected for it (A-1 Checkpoint 2).

## Key facts about the current code (verified at earlier caching time — re-verify anything load-bearing)
- `Game` is `PTCG` only; routes are generic (`scope ':game'`).
- `external_url = "#{game.base_uri}#{external_id}"`; Pokémon `external_id` is `/players/{id}`.
- Scoring today: `SalaryDrafts::Scorer` → `Player#score_difference` → `latest_score_before`.
  Cost today: `CostCalculator#calculate_cost`, single snapshot. Both being replaced.
- Only upcoming tournaments are scraped today; no results/standings ingested anywhere.
- Cron fixed by A-2 — `config/schedule.rb` calls real tasks; being converted to enqueue real
  jobs (A-7, done).
- No `Game` row is seeded anywhere yet (D-1's `games.yml` seed still pending).
- Gemfile: `httparty` + `nokogiri`; no webmock/VCR (specs stub HTTParty); job framework status
  should be reconfirmed if relevant to this ticket (A-4 added `ExternalData::ImportJob`).

## Workflow conventions (enforce during build)
- Small PRs; stack only where relevant, ~2 in flight before review. Rough order A → B → C → D;
  prefer land-and-review over deep stacking.
- Specs ship with the logic in the same PR.
- Pre-commit gate: `rubocop` AND `rspec` must pass before every commit. No unjustified
  rubocop `disable`s.

## Environment caveats
- Live `mew.limitlesstcg.com` and `eloshowdown.com` are blocked in-session (403 via proxy) —
  not relevant to A-8 (no external fetch involved).
- No webmock/VCR — HTTP specs stub HTTParty. Not relevant to A-8.
- `config/credentials/test.key` is gitignored and absent in a fresh worktree — copy from the
  main checkout's `config/credentials/test.key` before running specs.

## A-3 — ExternalRequest audit model (Done, merged, PR #29) — relevant decisions
- D1 schema: `external_requests` table — `game_id` (string FK), `kind` integer enum, `status`
  integer enum (default `running`), `records_processed` integer (default 0), `started_at`
  (`null: false`), `finished_at` (nullable), `error` text (nullable), `response_body` jsonb
  (nullable), `source_url` string (nullable), polymorphic `requestable` (optional),
  `t.timestamps`. Indexes: `game_id`, polymorphic `[requestable_type, requestable_id]`.
- D2: `kind`/`status` are integer-backed Rails enums with explicit hashes
  (`enum kind: { players: 0, tournaments: 1 }`, `enum status: { running: 0, success: 1,
  failure: 2 }`).
- D4: Lifecycle — model has `mark_success(records_processed:)`, `mark_failure(error:)`, both
  plain names (no bang), keyword args. `ExternalData::RequestRecorder#record(...)` service
  wraps the create/close lifecycle.
- D5: `Game has_many :external_requests, dependent: :restrict_with_error` — changed from
  `:destroy` specifically so audit rows are never destroyed as a side effect of deleting a
  `Game`; this is the FK-restrict workaround A-8's card explicitly references and is meant to
  give a real deletion path for.
- Validations follow `Participation`: presence on `kind`/`status`/`started_at`, numericality
  (only_integer, >= 0) on `records_processed`.
- I18n: `activerecord.models.external_request` + `activerecord.attributes.external_request.*`
  already present in `config/locales/activerecord.en.yml`.
- Risks noted at the time: `Game`'s `:restrict_with_error` means a `Game` can never be
  destroyed once it has any request history — "acceptable since `Game` rows are static seed
  data ... but worth knowing if that assumption ever changes." A-8 is the ticket that gives
  audit rows an actual deletion path instead of leaving this as a permanent block.

## A-6 — Admin fetch-history views (Status: Review, PR #35, NOT yet merged to main)
- Two admin pages over `ExternalRequest`: tabbed-by-game index + a bare-minimum show page.
- Index columns (D3): Kind, Status, Records processed, Started at, Finished at, Duration,
  truncated Error. `response_body`/`source_url` only on `show`.
- No schema changes in A-6 — reuses A-3's `ExternalRequest` as-is.
- Since this PR is unmerged, A-8 must not assume `admin/external_requests_controller.rb` or
  its views exist in the codebase A-8 branches from (main). A-8 should only need to touch the
  model/migration layer (and optionally the `RequestRecorder`/`Game` association) to satisfy
  its own done-criteria; it is not responsible for wiring soft-delete into A-6's UI, which
  hasn't landed yet.
- Interesting precedent noted for possible reuse: A-6 added `#kind_label`/`#status_label` on
  the model going through `I18n.t(..., scope: %i[activerecord enums external_request kind])`.
  Not directly relevant to A-8 unless a similar model-level convenience method makes sense for
  soft-delete state (developer/planner judgment call).
