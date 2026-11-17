#!/usr/bin/env bash
set -euo pipefail

# Move to project root (one level above .agents)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

INTERVAL_SECONDS="${INTERVAL_SECONDS:-300}"

run_poll() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running factory-watcher..."
  agy -p "Run the factory-watcher skill against .agents/factory.config.json." --dangerously-skip-permissions
  local exit_code=$?
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished (exit code: $exit_code)."
  return $exit_code
}

if [[ "${1:-}" == "--once" ]]; then
  run_poll
  exit $?
fi

echo "=================================================="
echo " Antigravity Headless Software Factory"
echo " Project : $(pwd)"
echo " Interval: ${INTERVAL_SECONDS}s (Ctrl+C to stop)"
echo "=================================================="

while true; do
  run_poll || true
  echo ""
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting ${INTERVAL_SECONDS}s before next poll..."
  sleep "$INTERVAL_SECONDS"
done
