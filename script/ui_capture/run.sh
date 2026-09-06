#!/usr/bin/env bash
# Transitional shim. The driver moved to the kanban-automation plugin, in
# scripts/ui_capture/. This file forwards to it, unchanged arguments and all.
#
# It exists because the local .claude/skills/ copies of ticket-pipeline still
# name this path, and the Routines still call those copies. Delete this file
# in the same pull request that deletes .claude/skills/ticket-pipeline --
# the plugin's own copy of that skill already calls the driver directly, as
# ${CLAUDE_PLUGIN_ROOT}/scripts/ui_capture/run.sh.
#
# Set UI_CAPTURE_DRIVER to point at a run.sh by hand.
set -uo pipefail

find_driver() {
  [ -n "${UI_CAPTURE_DRIVER:-}" ] && { echo "$UI_CAPTURE_DRIVER"; return; }
  [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -x "$CLAUDE_PLUGIN_ROOT/scripts/ui_capture/run.sh" ] \
    && { echo "$CLAUDE_PLUGIN_ROOT/scripts/ui_capture/run.sh"; return; }

  # The install path carries the plugin version, so read it rather than
  # writing a version out here and going stale on the next release.
  local installed="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json"
  if [ -f "$installed" ] && command -v jq >/dev/null; then
    jq -r '.plugins["kanban-automation@vinnie-automation"][]?.installPath // empty' "$installed" 2>/dev/null \
      | while read -r p; do
          [ -x "$p/scripts/ui_capture/run.sh" ] && { echo "$p/scripts/ui_capture/run.sh"; break; }
        done
  fi
}

DRIVER="$(find_driver | head -1)"
if [ -z "$DRIVER" ]; then
  cat >&2 <<'MSG'
[run.sh] the UI capture driver is not on disk.

It ships with the kanban-automation plugin, in scripts/ui_capture/. This
project only supplies .claude/ui-capture.json, script/ui_capture/boot.sh,
and script/ui_capture/core_targets.sh.

Install the plugin, or point UI_CAPTURE_DRIVER at a checkout of it.
MSG
  exit 1
fi

exec "$DRIVER" "$@"
