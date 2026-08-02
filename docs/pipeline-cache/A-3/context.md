# Drafting app — project context (cached 2026-08-02, source: https://app.notion.com/p/3a94af79fc0180f68bd6e37f39723fc8)

# Multi-game player DB + placement-based scoring
**Status:** planning (approved direction, not yet implemented) · **Date:** 2026-07-26

The Kanban board (https://app.notion.com/p/3a94af79fc01801ea781c9195643d5a0) holds the 26 PR-sized stories (Epics A–D) with Status / Epic / Priority / Depends-On and per-card done criteria. This page is the durable context + session summary behind it.

## Session summary
Planning session output: a refactor of Pokémon TCG off fragile HTML scraping onto a reusable **multi-game import architecture** (DI adapters + JSON client + batched jobs + `ExternalRequest` audit log + admin pages), onboarding **Riftbound** (eloshowdown ELO API) as a second player DB, and a clean domain split — **ratings (CP/ELO) → `ExternalScore` → pricing**, and **tournament placements → new `Result` model → scoring**. Direction is approved; nothing implemented yet. The board's 26 stories are the implementation plan.

## Decisions log (most recent wins)
- **Scoring is placement-based, size-weighted**, not a rating delta. New `Result` (player + tournament + placement + `field_size`); scorer weights placement by tournament size (high finish in a small event counts less); encapsulated per game in a `Scoring::Strategy`. Old `Player#score_difference` scoring retired.
- **Cost from the season distribution** — `CostCalculator` uses median & average of the game/season's `ExternalScore`s (new `Players::SeasonStats`), configurable per game, not a single snapshot.
- **`ExternalScore` becomes an append-only time series** — drop `(score, player_id)` uniqueness (blocks repeated/equal ELO snapshots), append only on change, add nullable `season`.
- **Seasons are per-game & configurable** — Pokémon uses a season cutoff; **Riftbound is seasonless** (frequent ELO snapshots, no two-season averaging).
- **Pricing rules are an injected param**, defaulting to `[Players::ScalingPriceRule.new]` — NOT a `Game#pricing_rules` method (rejected).
- **Tournament results = one shared scraping pattern for both games** via an adapter `results(tournament:)` contract + per-game `ResultsScraper` on a shared base (Nokogiri contained here only). mew `finishes` route rejected. **Riftbound results are in scope.**
- **Adapter is dependency-injected** into `ExternalData::Interface`, `OfflineAdapter` default (frozen-hash registry rejected).
- **Imports run in a batched background-job layer**, triggered from admin pages, every fetch recorded in a new `ExternalRequest` audit model. No request-cycle scraping.

## Key facts about the current code (verified)
- `Game` is `PTCG` only; routes are generic (`scope ':game'`), so `/RIFT` resolves once a `RIFT` `Game` row exists — no routing changes.
- `external_url = "#{game.base_uri}#{external_id}"`; Pokémon `external_id` is `/players/{id}` and must stay that way — the mew JSON base must **not** overwrite `Game.base_uri`.
- Scoring today: `SalaryDrafts::Scorer` (`scorer.rb:15`) → `Player#score_difference` → `latest_score_before`. Cost today: `CostCalculator#calculate_cost` (`cost_calculator.rb:12`), single snapshot. Both being replaced.
- Pricing hardcoded at `salary_draft.rb:11`, `:15`, `rosters_controller.rb:83`.
- Only **upcoming** tournaments are scraped today; **no results/standings ingested** anywhere — `Result` ingestion is new for both games.
- Cron references a **non-existent** task (`update_upcoming_tournaments`); real task is `update_tournaments` — being fixed to enqueue jobs.
- Gemfile: `httparty` + `nokogiri`; **no webmock/VCR** (specs stub HTTParty); **no job framework wired yet** — confirm/add a queue adapter.

## Workflow conventions (enforce during build)
- **Small PRs; stack only where relevant, ~2 in flight before review.** Rough order A → B → C → D; prefer land-and-review over deep stacking.
- **Specs ship with the logic** in the same PR.
- **Pre-commit gate: `rubocop` AND `rspec` must pass before every commit.** No unjustified rubocop `disable`s.

## Environment caveats
- Live `mew.limitlesstcg.com` and `eloshowdown.com` are **blocked in-session (403 via proxy)** — confirm exact JSON field names and result-page markup against live sources at build time and capture as fixtures.
- **No job framework wired yet** — confirm/add a queue adapter (A-4).
- **No webmock/VCR** — HTTP specs stub HTTParty.
- `config/credentials/test.key` gitignored/absent handling — see hook; not relevant, already resolved this session.

## Open items
None blocking. Confirm at build time: queue adapter choice; exact result-page markup and rating JSON field names; the placement→points weighting curve (tunable).

Related page: "Session Handover — ticket-pipeline skill + C-3 dry-run (2026-07-30)" — https://app.notion.com/p/3ad4af79fc0181c588cbef0d0f2ec059
