#!/usr/bin/env bash
# Boots the app for a UI-capture run: builds assets, seeds a fresh run
# database, starts the server, and waits for it to answer. Run with --stop
# to tear the same run down again.
#
# Usage:
#   script/ui_capture/boot.sh --ticket <id> [--dir <path>]
#   script/ui_capture/boot.sh --ticket <id> [--dir <path>] --stop
#
# --dir sets where boot.sh keeps its own state and logs. Pass the SAME
# --dir run.sh uses as its --out, so both scripts agree on one directory to
# erase afterward; without it, boot.sh picks tmp/ui-capture/<sanitized
# ticket>, for standalone use.
#
# On success (start mode) this prints two lines to stdout:
#   BASE_URL=http://127.0.0.1:<port>
#   TEST_ENV_NUMBER=_<sanitized ticket>
# A caller that queries the database directly (e.g. to resolve the core
# capture surface) must set TEST_ENV_NUMBER to that value first, or it
# queries the shared, unseeded test database instead of this run's own.
set -uo pipefail

usage() {
  echo "Usage: $0 --ticket <id> [--dir <path>] [--stop]" >&2
  exit 1
}

TICKET=""
STOP=false
DIR_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --ticket) TICKET="$2"; shift 2 ;;
    --dir) DIR_OVERRIDE="$2"; shift 2 ;;
    --stop) STOP=true; shift ;;
    *) usage ;;
  esac
done
[ -n "$TICKET" ] || usage

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# A dispatch worktree has neither node_modules nor a copy of test.key of its
# own; both are gitignored, so both come from the main checkout when this
# worktree doesn't already have them. From inside any worktree, git's common
# dir is the main checkout's .git, so its parent is the main checkout.
default_main_checkout() {
  local common_dir
  common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  [ -n "$common_dir" ] || return 1
  dirname "$common_dir"
}
MAIN_CHECKOUT="${UI_CAPTURE_MAIN_CHECKOUT:-$(default_main_checkout || echo "$REPO_ROOT")}"

SANITIZED_TICKET="$(echo "$TICKET" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"
[ -n "$SANITIZED_TICKET" ] || { echo "ticket '$TICKET' sanitizes to an empty run-db name" >&2; exit 1; }
RUN_SUFFIX="_${SANITIZED_TICKET}"

RUN_DIR="${DIR_OVERRIDE:-$REPO_ROOT/tmp/ui-capture/$SANITIZED_TICKET}"
STATE_FILE="$RUN_DIR/boot.env"
mkdir -p "$RUN_DIR"

log() { echo "[boot.sh] $*" >&2; }

# ---------------------------------------------------------------------------
# Database credentials (test env only -- this is the only bootable one here)
# ---------------------------------------------------------------------------
fetch_credentials() {
  local err
  err="$(mktemp)"
  if ! IFS='|' read -r DB_NAME DB_USERNAME DB_PASSWORD < <(
    RAILS_ENV=test bundle exec rails runner '
      db = Rails.application.credentials.db
      puts [db.name, db.username, db.password].join("|")
    ' 2>"$err"
  ) || [ -z "$DB_NAME" ]; then
    log "could not read database credentials:"
    cat "$err" >&2
    rm -f "$err"
    return 1
  fi
  rm -f "$err"
}

# ---------------------------------------------------------------------------
# --stop
# ---------------------------------------------------------------------------
stop() {
  if [ ! -f "$STATE_FILE" ]; then
    log "no boot state for ticket '$TICKET' ($STATE_FILE missing) -- nothing to stop"
    return 0
  fi
  # shellcheck disable=SC1090
  source "$STATE_FILE"

  if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    log "stopping puma (pid $SERVER_PID)"
    kill "$SERVER_PID" 2>/dev/null || true
    for _ in $(seq 1 20); do
      kill -0 "$SERVER_PID" 2>/dev/null || break
      sleep 0.5
    done
    kill -9 "$SERVER_PID" 2>/dev/null || true
  fi

  if [ -n "${RUN_DB:-}" ]; then
    if fetch_credentials; then
      log "dropping run database $RUN_DB"
      PGPASSWORD="$DB_PASSWORD" dropdb -h 127.0.0.1 -U "$DB_USERNAME" --if-exists "$RUN_DB" 2>/dev/null || true
    else
      log "could not re-read credentials to drop $RUN_DB -- drop it by hand"
    fi
  fi

  rm -f "$STATE_FILE"
}

if [ "$STOP" = true ]; then
  stop
  exit 0
fi

# ---------------------------------------------------------------------------
# Failure trap -- from here on, any non-zero exit drops the run database and
# kills the server, even though the state file (which --stop normally reads)
# isn't written until the very end of a successful boot.
# ---------------------------------------------------------------------------
RUN_DB=""
SERVER_PID=""
CLEANED_UP=false
cleanup_on_failure() {
  local rc=$?
  [ "$rc" -eq 0 ] && return
  [ "$CLEANED_UP" = true ] && return
  CLEANED_UP=true
  log "boot failed (exit $rc) -- cleaning up"
  if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
  if [ -n "$RUN_DB" ] && [ -n "${DB_USERNAME:-}" ]; then
    PGPASSWORD="${DB_PASSWORD:-}" dropdb -h 127.0.0.1 -U "$DB_USERNAME" --if-exists "$RUN_DB" 2>/dev/null || true
  fi
}
trap cleanup_on_failure EXIT

set -e

# ---------------------------------------------------------------------------
# Node modules + built assets
# ---------------------------------------------------------------------------
if [ ! -d "$REPO_ROOT/node_modules" ]; then
  if [ -d "$MAIN_CHECKOUT/node_modules" ]; then
    log "symlinking node_modules from $MAIN_CHECKOUT"
    ln -s "$MAIN_CHECKOUT/node_modules" "$REPO_ROOT/node_modules"
  else
    log "installing node_modules (no main checkout to symlink from)"
    npm install
  fi
fi

if [ ! -f "$REPO_ROOT/config/credentials/test.key" ] && [ -f "$MAIN_CHECKOUT/config/credentials/test.key" ]; then
  log "copying test.key from $MAIN_CHECKOUT"
  cp "$MAIN_CHECKOUT/config/credentials/test.key" "$REPO_ROOT/config/credentials/test.key"
fi

log "building JS and CSS"
npm run build >"$RUN_DIR/build-js.log" 2>&1
npm run build:css >"$RUN_DIR/build-css.log" 2>&1

fetch_credentials || exit 2

# ---------------------------------------------------------------------------
# Seed a fresh run database directly. (No template database: measured at
# ~12s for a cold `rake demo:seed`, which does not justify a template's
# staleness risk.)
# ---------------------------------------------------------------------------
RUN_DB="${DB_NAME}${RUN_SUFFIX}"
PGPASSWORD="$DB_PASSWORD" dropdb -h 127.0.0.1 -U "$DB_USERNAME" --if-exists "$RUN_DB"
log "seeding $RUN_DB"
TEST_ENV_NUMBER="$RUN_SUFFIX" RAILS_ENV=test bundle exec rails db:create db:schema:load
TEST_ENV_NUMBER="$RUN_SUFFIX" RAILS_ENV=test bundle exec rake demo:seed

# ---------------------------------------------------------------------------
# Free port + server start, retried in case a concurrent dispatch takes the
# port between the bind-and-close check and puma actually binding it.
# ---------------------------------------------------------------------------
free_port() {
  ruby -rsocket -e '
    s = Socket.new(:INET, :STREAM)
    s.bind(Addrinfo.tcp("127.0.0.1", 0))
    puts s.local_address.ip_port
    s.close
  '
}

PIDFILE="$RUN_DIR/server.pid"
BASE_URL=""
START_ATTEMPTS=3
for attempt in $(seq 1 "$START_ATTEMPTS"); do
  PORT="$(free_port)"
  rm -f "$PIDFILE"

  log "starting puma on port $PORT against $RUN_DB (attempt $attempt/$START_ATTEMPTS)"
  if ! TEST_ENV_NUMBER="$RUN_SUFFIX" RAILS_ENV=test bundle exec rails server \
    -e test -b 127.0.0.1 -p "$PORT" -P "$PIDFILE" -d --no-log-to-stdout \
    >"$RUN_DIR/server-boot.log" 2>&1; then
    log "puma failed to start on port $PORT, retrying"
    continue
  fi

  CANDIDATE_URL="http://127.0.0.1:${PORT}"
  for _ in $(seq 1 60); do
    [ -f "$PIDFILE" ] && break
    sleep 0.5
  done
  if [ ! -f "$PIDFILE" ]; then
    log "puma never wrote a pidfile on port $PORT, retrying"
    continue
  fi
  SERVER_PID="$(cat "$PIDFILE")"

  READY=false
  for _ in $(seq 1 60); do
    if curl -fsS -o /dev/null -w '%{http_code}' "$CANDIDATE_URL/up" 2>/dev/null | grep -q '^200$'; then
      READY=true
      break
    fi
    kill -0 "$SERVER_PID" 2>/dev/null || break
    sleep 0.5
  done

  if [ "$READY" = true ]; then
    BASE_URL="$CANDIDATE_URL"
    break
  fi

  log "puma on port $PORT never answered /up, retrying"
  kill "$SERVER_PID" 2>/dev/null || true
  SERVER_PID=""
done

[ -n "$BASE_URL" ] || { log "could not start puma after $START_ATTEMPTS attempts"; exit 2; }

cat > "$STATE_FILE" <<EOF
SERVER_PID=$SERVER_PID
RUN_DB=$RUN_DB
BASE_URL=$BASE_URL
EOF

log "ready: $BASE_URL (db $RUN_DB, pid $SERVER_PID)"
echo "BASE_URL=$BASE_URL"
echo "TEST_ENV_NUMBER=$RUN_SUFFIX"
