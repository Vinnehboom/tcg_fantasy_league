# A-3 — ExternalRequest audit model

URL: https://app.notion.com/p/3a94af79fc01815e8d34e5b87c9978be

## Properties
- Task ID: A-3
- Epic: A - Import infrastructure
- Priority: High
- Status: Not started
- Depends On: —

## Body
ExternalRequest model+migration (game_id, kind, status, records_processed, timing, error, source_url) + lifecycle helper.
**Done:** success & failure records with counts/timing.

## Plan

**Checkpoint 1 answers:** (1) Live verification — accept spec suite + CI as evidence; Gatekeeper explicitly skips the Phase 4 evidence gate for this ticket (no UI ships in A-3). (2) `kind` enum ships with just `players`/`tournaments`; `results` gets added when a ticket first needs it, not seeded speculatively.

### Goal
Add an `ExternalRequest` audit record — one row per external fetch — plus the lifecycle helper that opens it, times it, and closes it as a success (with a processed count) or a failure (with an error message). This is the write-side substrate A-4 (batched import jobs), A-5 (admin triggers) and A-6 (fetch-history views) all build on. No job framework, no HTTP, no UI in this ticket.

Done when: a spec proves a fetch recorded through the helper produces a **success** row carrying `records_processed` and start/finish timing, and a failing fetch produces a **failure** row carrying the error text and timing — and the error still reaches the caller.

### Decisions
- **D1 — Schema.** `external_requests`: `game_id` (string FK, `games.id` is a string PK), `kind` integer enum, `status` integer enum (default `running`), `records_processed` integer (`default: 0`), `started_at` datetime (`null: false`), `finished_at` datetime (nullable), `error` text (nullable), `source_url` string (nullable), `t.timestamps`. No extra indexes beyond `game_id` — deferred to A-6 with real query shapes.
- **D2 — `kind`/`status` are integer-backed Rails enums** with explicit hashes, matching `Participation`'s working precedent: `enum kind: { players: 0, tournaments: 1 }`, `enum status: { running: 0, success: 1, failure: 2 }`. Rejected string-backed enums (breaks repo precedent) and copying `Tournament#format` (maps ints onto a string column — a latent bug, not a pattern to copy).
- **D3 — Timing is `started_at` + `finished_at`; duration derived** via `#duration_seconds`, nil while unfinished. Kept distinct from `created_at` since A-4 may create the row at enqueue time and start it later. Rejected persisting a duration column (derivable, can drift).
- **D4 — Lifecycle in two pieces.** Model: `mark_success(records_processed:)`, `mark_failure(error:)` — plain names, no bang, keyword args. Service: `ExternalData::RequestRecorder#record(game:, kind:, source_url: nil, &block)` — creates the row running, yields, closes it success with the block's return value as the count, or closes it failure and re-raises on `StandardError`. Only the yield is inside the rescue. Namespaced `ExternalData::` alongside `Interface`/adapters; instance-based so A-4 can inject it like `SalaryDraft` injects `pricing_rules:`. Rejected a bare start/finish pair (a crashing caller leaves a row stuck `running`), swallowing the exception, and `ApplicationService`/`.call` (no precedent in `app/services`).
- **D5 — `Game has_many :external_requests, dependent: :destroy`** (matches `Player has_many :external_scores`; deliberately not `:nullify` like `Game has_many :players` — that one already contradicts `players.game_id null: false`, not to be copied).
- **D6 — Validations follow `Participation`**: presence on `kind`/`status`/`started_at`, numericality (`only_integer`, `>= 0`) on `records_processed`. Rejected `enum ..., validate: true` (swaps failure mode to silent `:inclusion` invalid record, breaks presence matchers).
- **D7 — I18n.** `activerecord.models.external_request` + `activerecord.attributes.external_request.*` added now in `config/locales/activerecord.en.yml`, singular key. Enum label translations deferred to A-6.

### Branch
`feat/A-3-external-request-audit-model`, cut from latest `origin/main` (no dependency, not stacked). Migrations must run as `RAILS_ENV=test bundle exec rails db:migrate` (only `config/credentials/test.key` exists in-session) and the regenerated `db/schema.rb` must be committed since CI runs `db:schema:load`.

### Commits
1. **"Add ExternalRequest audit model"** — migration, `app/models/external_request.rb`, `Game` association, activerecord locale entries, `spec/factories/external_requests.rb` (no traits), `spec/models/external_request_spec.rb` (shoulda associations/validations, `#duration_seconds`, `#mark_success`, `#mark_failure`, four-phase/outcome-named/no `let!`), `spec/models/game_spec.rb` gains the association example.
2. **"Record external fetches through a request recorder"** — `app/services/external_data/request_recorder.rb`, `spec/services/external_data/request_recorder_spec.rb` (`freeze_time`/`travel`, success context: status/count/duration/game+kind+url recorded/returns request; failure context: status/error stored/duration recorded/re-raises). This commit's specs are what actually prove the ticket's done-criteria.

### Open alternatives (still live — developer shouldn't change unilaterally)
Seed `results` into `kind` now vs. later (resolved above: later); persist a duration column; extra indexes (`[:game_id, :started_at]`, `status`); string-backed enums; nullable `records_processed` to distinguish unknown-from-zero; a `tournament_id`/polymorphic subject column; truncating `error`; deferring I18n to A-6; `enum status: {...}, instance_methods: false` to suppress the generated `success!`/`failure!` writers.

### Risks
Enum bang methods (`success!`/`failure!`) can half-close a record if called directly instead of through the recorder — mitigated by the recorder being the only writer. Audit rows aren't transaction-safe if a caller wraps `recorder.record` in a rollback-able transaction — flag for A-4, worth a curator note. Integer enum values are append-only. The recorder's block must return an Integer count — `ExternalData::Interface#save_objects` currently returns a logger call's value, not a count (`app/services/external_data/interface.rb:33-44`) — flag for A-4. `game_id` needs `type: :string` on `t.references :game` or the FK breaks against the string-PK `games` table — most likely migration mistake. Regenerated `db/schema.rb` should be diffed to confirm only the new table + version bump changed. Unbounded `error` text accepted for now.
