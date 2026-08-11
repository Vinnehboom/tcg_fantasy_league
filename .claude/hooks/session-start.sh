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

# 1b. Git commit signing (SSH), from the TCG_FANTASY_LEAGUE_GIT_SIGNING_KEY
# secret. Writes the private key to a session-local file and configures
# repo-local SSH commit signing so pushed commits show as "Verified" on
# GitHub. Skipped (not a failure) if the secret isn't set — commits just
# stay unsigned, same as before this was added.
if [ -n "${TCG_FANTASY_LEAGUE_GIT_SIGNING_KEY:-}" ]; then
  if ! command -v ssh-keygen >/dev/null 2>&1; then
    sudo apt-get update -qq || true
    sudo apt-get install -y -qq openssh-client || true
  fi
  SIGNING_KEY_PATH="$HOME/.ssh/tcg_fantasy_league_signing"
  mkdir -p "$HOME/.ssh"
  printf '%s\n' "$TCG_FANTASY_LEAGUE_GIT_SIGNING_KEY" > "$SIGNING_KEY_PATH"
  chmod 600 "$SIGNING_KEY_PATH"
  git config gpg.format ssh
  git config user.signingkey "$SIGNING_KEY_PATH"
  git config commit.gpgsign true
  # This environment's own global gitconfig points gpg.ssh.program at a
  # platform-managed signer (/tmp/code-sign, tied to Claude's own identity)
  # that silently ignores a custom user.signingkey — it neither errors nor
  # produces a valid signature for it. Override it repo-locally to plain
  # ssh-keygen so the key above actually gets used.
  git config gpg.ssh.program "$(command -v ssh-keygen)"
fi

# 2. Postgres: install if missing, relax local auth to trust (throwaway
# container, local-socket-only, fine for a test DB), start the service.
export DEBIAN_FRONTEND=noninteractive
# Don't gate on `command -v pg_config`: postgresql-common ships a pg_config
# shim independent of whether libpq-dev's headers are actually installed, so
# that check can pass while libpq-fe.h is still missing — which breaks the
# `pg` gem's native build in step 3 silently (masked by `|| true`) and
# cascades into every later step that assumes bundle install succeeded.
# Check for the header file itself instead.
if [ ! -f /usr/include/postgresql/libpq-fe.h ] || ! command -v psql >/dev/null 2>&1; then
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

# 7. Coding Style Guide reminder. This hook can't fetch Notion content itself
# (no API credentials available to the shell — Notion access only exists
# inside the agent's own tool calls), so instead it surfaces the canonical
# page reference from .claude/coding-style.json as context, telling the
# agent to pull it in as one of its first actions. Printed on stdout so
# Claude Code injects it into the session's context.
if [ -f .claude/coding-style.json ]; then
  STYLE_GUIDE_URL=$(grep -o '"notion_page_url"[[:space:]]*:[[:space:]]*"[^"]*"' .claude/coding-style.json | sed -E 's/.*"([^"]+)"$/\1/')
  if [ -n "$STYLE_GUIDE_URL" ]; then
    cat <<EOF
Before making code changes in this repo, fetch the Coding Style Guide from Notion ($STYLE_GUIDE_URL) via the notion-fetch tool and treat its Style Rules as binding project style guidance alongside repo conventions — it's the shared source of truth the ticket-pipeline skill also reads before implementing tickets. Skip this fetch only if Notion tools are unavailable this session.
EOF
  fi
fi

exit 0
