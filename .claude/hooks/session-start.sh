#!/bin/bash
# Prepares the test environment (Rails credentials, Postgres, gems, JS assets,
# test DB schema) so `bundle exec rspec` / `bundle exec rubocop` work without
# manual setup. Every step is best-effort: a failure here shouldn't block the
# session from starting, it should just leave the old (manual-setup) friction
# in place.
set -uo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# 1. Rails test credentials key, from the TCG_FANTASY_LEAGUE_TEST_KEY secret.
# Lets Rails decrypt the already-committed config/credentials/test.yml.enc
# instead of needing a throwaway local key regenerated every session.
if [ -n "${TCG_FANTASY_LEAGUE_TEST_KEY:-}" ] && [ ! -f config/credentials/test.key ]; then
  mkdir -p config/credentials
  printf '%s' "$TCG_FANTASY_LEAGUE_TEST_KEY" > config/credentials/test.key
  chmod 600 config/credentials/test.key
fi

# 2. Postgres: install if missing, relax local auth to trust (throwaway
# container, local-socket-only, fine for a test DB), start the service.
export DEBIAN_FRONTEND=noninteractive
if ! command -v pg_config >/dev/null 2>&1 || ! command -v psql >/dev/null 2>&1; then
  sudo apt-get update -qq || true
  sudo apt-get install -y -qq postgresql libpq-dev || true
fi

sudo service postgresql start >/dev/null 2>&1 || true

PG_HBA=$(sudo -u postgres psql -tAc 'SHOW hba_file;' 2>/dev/null | tr -d '[:space:]')
if [ -n "$PG_HBA" ] && sudo test -f "$PG_HBA"; then
  sudo sed -i -E 's/^(local[[:space:]]+all[[:space:]]+all[[:space:]]+)\S+/\1trust/' "$PG_HBA" || true
  sudo service postgresql restart >/dev/null 2>&1 || true
fi

# 3. Ruby gems.
if command -v bundle >/dev/null 2>&1; then
  bundle install --quiet || true
fi

# 3b. Work around a PATH quirk in this environment: rbenv installs gem
# executables (rubocop, rspec, rails, ...) under the Ruby install's bin/, but
# `bundle exec` only looks in GEM_HOME/bin, so `bundle exec rubocop` fails
# with "command not found" even though the gem is installed. Symlinking fixes
# it for both our own commands and the repo's husky pre-commit hook.
RBENV_BIN="$(rbenv prefix 2>/dev/null)/bin"
GEM_BIN="$(ruby -e 'puts Gem.dir' 2>/dev/null)/bin"
if [ -d "$RBENV_BIN" ] && [ -n "$GEM_BIN" ]; then
  mkdir -p "$GEM_BIN"
  for f in "$RBENV_BIN"/*; do
    name="$(basename "$f")"
    [ -e "$GEM_BIN/$name" ] || ln -s "$f" "$GEM_BIN/$name"
  done
fi

# 4. Create/update the local Postgres role to match the decrypted test
# credentials, so `bin/rails db:*` and specs can actually connect.
if [ -f config/credentials/test.key ] && command -v bundle >/dev/null 2>&1; then
  DB_INFO=$(RAILS_ENV=test bundle exec rails runner \
    'creds = Rails.application.credentials.db; puts [creds.username, creds.password].join("\t")' \
    2>/dev/null || true)
  DB_USER=$(printf '%s' "$DB_INFO" | cut -f1)
  DB_PASS=$(printf '%s' "$DB_INFO" | cut -f2)
  if [ -n "$DB_USER" ]; then
    sudo -u postgres psql -v ON_ERROR_STOP=0 -c \
      "DO \$\$ BEGIN CREATE ROLE \"$DB_USER\" WITH LOGIN SUPERUSER PASSWORD '$DB_PASS'; EXCEPTION WHEN duplicate_object THEN NULL; END \$\$;" \
      >/dev/null 2>&1 || true
  fi
fi

# 5. JS assets — request specs 404 on application.css/js without this.
if [ -f package.json ] && command -v yarn >/dev/null 2>&1; then
  yarn install --silent || true
  yarn build >/dev/null 2>&1 || true
  yarn build:css >/dev/null 2>&1 || true
fi

# 6. Test DB schema.
if command -v bundle >/dev/null 2>&1; then
  RAILS_ENV=test bundle exec rails db:prepare >/dev/null 2>&1 || true
fi

exit 0
