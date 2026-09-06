#!/usr/bin/env bash
# One command for a UI-capture run: boots the app, merges the core surface
# with the ticket's Capture plan, runs capture.mjs, builds result.json, and
# always tears the server and run database down again.
#
# Usage:
#   script/ui_capture/run.sh --ticket <id> --targets <path> --out <dir> [--budget <seconds>]
#
# --targets points at the ticket's own Capture plan (the D2-shaped JSON the
# orchestrator writes to tmp/ui-capture/<TASK_ID>.json). run.sh adds the
# core surface itself, from UiCapture::CoreTargets. Always run this from the
# ticket branch's own checkout -- it resolves the core surface and captures
# whatever code is checked out right here, not necessarily the branch named
# in --ticket.
#
# Exit codes: 0 success, 1 usage error, 2 boot failure, 3 capture failure,
# 4 budget expired. A capture FAILURE (this script's own exit code) never
# blocks a PR by itself -- that is a decision the Gatekeeper makes by
# reading result.json's per-target status, not by reading this exit code.
set -uo pipefail

usage() {
  echo "Usage: $0 --ticket <id> --targets <path> --out <dir> [--budget <seconds>]" >&2
  exit 1
}

TICKET=""
TARGETS_FILE=""
OUT_DIR=""
BUDGET=600
while [ $# -gt 0 ]; do
  case "$1" in
    --ticket) TICKET="$2"; shift 2 ;;
    --targets) TARGETS_FILE="$2"; shift 2 ;;
    --out) OUT_DIR="$2"; shift 2 ;;
    --budget) BUDGET="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[ -n "$TICKET" ] && [ -n "$TARGETS_FILE" ] && [ -n "$OUT_DIR" ] || usage
[ -f "$TARGETS_FILE" ] || { echo "targets file not found: $TARGETS_FILE" >&2; exit 1; }

# A non-numeric or non-positive --budget would otherwise become 0 in the
# arithmetic below and corrupt result.json's budget_seconds field.
case "$BUDGET" in
  ''|*[!0-9]*) echo "[run.sh] invalid --budget '$BUDGET', defaulting to 600" >&2; BUDGET=600 ;;
esac
[ "$BUDGET" -gt 0 ] || { echo "[run.sh] --budget must be positive, defaulting to 600" >&2; BUDGET=600; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT" || exit 2
BOOT_SH="$SCRIPT_DIR/boot.sh"
CAPTURE_MJS="$SCRIPT_DIR/capture.mjs"
NODE_PATH_GLOBAL="$(npm root -g)"

mkdir -p "$OUT_DIR"
START_TIME=$(date +%s)

log() { echo "[run.sh] $*" >&2; }

write_result() {
  local code="$1" message="$2" manifest="[]" elapsed
  [ -f "$OUT_DIR/manifest.json" ] && manifest="$(cat "$OUT_DIR/manifest.json")"
  elapsed=$(( $(date +%s) - START_TIME ))
  jq -n --arg ticket "$TICKET" --argjson code "$code" --argjson budget "$BUDGET" \
        --argjson elapsed "$elapsed" --arg message "$message" --argjson targets "$manifest" '
    { ticket: $ticket, exit_code: $code, budget_seconds: $budget, elapsed_seconds: $elapsed,
      message: $message, targets: $targets }
  ' > "$OUT_DIR/result.json"
}

CLEANED_UP=false
cleanup() {
  [ "$CLEANED_UP" = true ] && return
  CLEANED_UP=true
  log "tearing down"
  "$BOOT_SH" --ticket "$TICKET" --dir "$OUT_DIR" --stop >/dev/null 2>&1 || true
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# ---------------------------------------------------------------------------
# Boot
# ---------------------------------------------------------------------------
BOOT_OUTPUT="$(mktemp)"
if ! "$BOOT_SH" --ticket "$TICKET" --dir "$OUT_DIR" >"$BOOT_OUTPUT" 2>&1; then
  log "boot failed"
  cat "$BOOT_OUTPUT" >&2
  rm -f "$BOOT_OUTPUT"
  write_result 2 "boot failure"
  exit 2
fi
BASE_URL="$(grep '^BASE_URL=' "$BOOT_OUTPUT" | tail -1 | cut -d= -f2-)"
TEST_ENV_NUMBER="$(grep '^TEST_ENV_NUMBER=' "$BOOT_OUTPUT" | tail -1 | cut -d= -f2-)"
rm -f "$BOOT_OUTPUT"
[ -n "$BASE_URL" ] || { log "boot produced no BASE_URL"; write_result 2 "boot produced no base URL"; exit 2; }
[ -n "$TEST_ENV_NUMBER" ] || { log "boot produced no TEST_ENV_NUMBER"; write_result 2 "boot produced no TEST_ENV_NUMBER"; exit 2; }
export TEST_ENV_NUMBER
log "booted at $BASE_URL (db suffix $TEST_ENV_NUMBER)"

# ---------------------------------------------------------------------------
# Merge the core surface with the ticket's Capture plan.
# A ticket target whose path matches a core target replaces it.
#
# TEST_ENV_NUMBER (exported above) must match what boot.sh used to seed the
# run database, or this resolves against the shared, unseeded test database
# instead -- every :game-scoped route would then silently drop.
# ---------------------------------------------------------------------------
CORE_JSON="$(mktemp)"
CORE_ERR="$(mktemp)"
if ! RAILS_ENV=test bundle exec rails runner '
  resolver = UiCapture::CoreTargets.new
  targets = resolver.call
  resolver.skipped.each { |line| warn "[core_targets] #{line}" }
  puts targets.to_json
' >"$CORE_JSON" 2>"$CORE_ERR"; then
  log "could not resolve the core capture surface"
  cat "$CORE_ERR" >&2
  rm -f "$CORE_JSON" "$CORE_ERR"
  write_result 2 "core target resolution failed"
  exit 2
fi
grep '^\[core_targets\]' "$CORE_ERR" >&2 || true
rm -f "$CORE_ERR"

TICKET_JSON="$(mktemp)"
if ! jq '.targets // []' "$TARGETS_FILE" > "$TICKET_JSON" 2>/dev/null; then
  log "targets file is not valid JSON: $TARGETS_FILE"
  write_result 1 "invalid targets file"
  exit 1
fi

MERGED_JSON="$OUT_DIR/merged-targets.json"
if ! jq -n --slurpfile core "$CORE_JSON" --slurpfile ticket "$TICKET_JSON" '
  ($core[0] | map(. + {source: "core"})) as $core_tagged |
  ($ticket[0]) as $ticket_targets |
  ($ticket_targets | map(.path)) as $ticket_paths |
  {
    targets: (
      ($core_tagged | map(select(.path as $p | ($ticket_paths | index($p)) | not)))
      + $ticket_targets
    )
  }
' > "$MERGED_JSON" 2>/dev/null; then
  log "could not merge core and ticket targets"
  write_result 1 "target merge failed"
  exit 1
fi
rm -f "$CORE_JSON" "$TICKET_JSON"

# ---------------------------------------------------------------------------
# Capture, bounded by whatever is left of the budget.
# ---------------------------------------------------------------------------
ELAPSED=$(( $(date +%s) - START_TIME ))
REMAINING=$(( BUDGET - ELAPSED ))
if [ "$REMAINING" -le 0 ]; then
  log "budget already spent before capture started"
  write_result 4 "budget expired before capture started"
  exit 4
fi

log "capturing (budget ${REMAINING}s remaining)"
CAPTURE_LOG="$OUT_DIR/capture.log"
# -k gives node a grace period to close Chromium cleanly after SIGTERM,
# then SIGKILLs the whole thing if that didn't finish in time.
NODE_PATH="$NODE_PATH_GLOBAL" timeout -k 10s "${REMAINING}s" node "$CAPTURE_MJS" \
  --targets "$MERGED_JSON" --out "$OUT_DIR" --base-url "$BASE_URL" \
  >"$CAPTURE_LOG" 2>&1
CAPTURE_RC=$?
cat "$CAPTURE_LOG" >&2

if [ "$CAPTURE_RC" -eq 124 ]; then
  log "capture exceeded its budget"
  write_result 4 "budget expired during capture"
  exit 4
elif [ "$CAPTURE_RC" -ne 0 ]; then
  log "capture failed (exit $CAPTURE_RC)"
  write_result 3 "capture failure"
  exit 3
fi

write_result 0 "ok"
log "done"
exit 0
