#!/usr/bin/env bash
# Prints this app's core capture surface as a JSON array on stdout: every GET
# route that renders a page, resolved from Rails.application.routes.routes by
# UiCapture::CoreTargets, with each dynamic segment filled from seeded demo
# data. Named by core_targets_command in .claude/ui-capture.json.
#
# Every route this leaves out is logged to stderr by name. run.sh passes that
# through.
#
# TEST_ENV_NUMBER must already be exported -- boot.sh prints it and run.sh
# exports it. Without it this resolves against the shared, unseeded test
# database instead of this run's own, and every :game-scoped route silently
# drops out.
set -uo pipefail

if [ -z "${TEST_ENV_NUMBER:-}" ]; then
  echo "[core_targets] TEST_ENV_NUMBER is not set -- boot.sh prints it and run.sh exports it" >&2
  exit 1
fi

RAILS_ENV=test exec bundle exec rails runner '
  resolver = UiCapture::CoreTargets.new
  targets = resolver.call
  resolver.skipped.each { |line| warn "[core_targets] #{line}" }
  puts targets.to_json
'
