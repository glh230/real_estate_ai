#!/usr/bin/env bash
# Print a one-line summary of the latest URL collection for the Slack report.
# Run from real_estate_ai repo root on the OpenClaw VM. Include this output
# in the "New Files Downloaded" section so Slack shows URL collection stats.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
STATE="$REPO_ROOT/collected/.collect_state.json"
if [ ! -f "$STATE" ]; then
  echo "URL collection: 0 new files (no run yet — run scripts/collect_from_urls.py first)"
  exit 0
fi
# Last run date (ISO) -> YYYY-MM-DD
LAST_RUN="$(jq -r '.last_run // ""' "$STATE")"
DATE=""
if [ -n "$LAST_RUN" ]; then
  DATE="${LAST_RUN:0:10}"
fi
if [ -z "$DATE" ] || [ ! -d "$REPO_ROOT/collected/$DATE" ]; then
  echo "URL collection: 0 new files (no collected date folder)"
  exit 0
fi
COUNT="$(find "$REPO_ROOT/collected/$DATE" -maxdepth 1 -name "*.txt" 2>/dev/null | wc -l)"
COUNT="${COUNT// /}"
echo "URL collection: ${COUNT} new files in collected/${DATE}/"
