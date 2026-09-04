# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Demo dataset

The demo dataset gives every screen real data to show: players, tournaments,
salary drafts, and a scored leaderboard. It comes from the real import jobs,
against a synthetic adapter instead of a live API call. Local development
uses this synthetic adapter by default, so it makes no live HTTP call at
all.

To add the demo dataset, run this command:

```
rake demo:seed
```

This command is additive and idempotent. Run it more than once. It adds no
duplicate rows. It also refreshes each game's upcoming tournament dates, so
they stay a valid number of days in the future.

CAUTION: `rake demo:reseed` erases every table in the database, including
the users table. To reset the database and reseed it, run this command:

```
rake demo:reseed CONFIRM=yes
```

Without `CONFIRM=yes`, the command makes no change. It prints the database
name and the number of tables to erase instead.

The historical part of the demo dataset (past tournaments and their scores)
is create-once. Its dates do not move with each `demo:seed` run, so they age
over time. Use `demo:reseed` to bring them back to a fresh, current state.

To reset and reseed from Ruby code, without the rake task, run these four
calls in order:

```ruby
Demo::Reset.call(confirm: true)
Demo::Seeder.call
Demo::History.call
Demo::DraftSeeder.call
```

### Demo accounts

The seed data creates these accounts:

| Username             | Password         | Role  |
|----------------------|------------------|-------|
| `demo`               | `demopass`       | User  |
| `admin`              | `adminpass`      | Admin |
| `demo_player_1`..`4` | `demoplayerpass` | User  |

Sign in as `demo` to see a populated participations page: a completed,
scored roster on a past tournament's draft, and a submitted roster on an
upcoming one. `demo_player_1` through `demo_player_4` fill out the rest of
the leaderboard.

### Where the data is safe to use

The synthetic adapter and `Demo::Seeder` both refuse to run in production.
Each check is independent of the other. The reset step of `demo:reseed`
goes further. It refuses to run outside development and test, since it
erases every table. A demo dataset in the production database is not
reversible.

