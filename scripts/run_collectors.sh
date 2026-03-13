#!/usr/bin/env bash
# Real Estate Data Collector — run the URL-based scraper and print a summary
# for the OpenClaw cron job so the agent can post an accurate Slack update.
# .err files are ignored (not counted, not committed).
# Invoked from: /home/node/.openclaw/workspace/real_estate_ai/scripts/run_collectors.sh
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "——— Real Estate Data Collector ———"
echo ""

# Run the URL-based collector (top 100 URLs, subset per run → collected/<date>/)
if ! python3 scripts/collect_from_urls.py; then
  echo "WARNING: URL collector had one or more failures (see above)."
fi
echo ""

# Summary for Slack: count only non-.err files (errors are ignored for commit and count)
STATE="$REPO_ROOT/collected/.collect_state.json"
NEW_FILES=0
DATE=""
if [ -f "$STATE" ]; then
  if command -v jq &>/dev/null; then
    LAST_RUN="$(jq -r '.last_run // ""' "$STATE")"
    DATE="${LAST_RUN:0:10}"
  fi
  if [ -z "$DATE" ] && [ -d "$REPO_ROOT/collected" ]; then
    DATE="$(find "$REPO_ROOT/collected" -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)"
    DATE="${DATE##*/}"
  fi
fi
if [ -n "$DATE" ] && [ -d "$REPO_ROOT/collected/$DATE" ]; then
  # Count only committable files (exclude .err)
  NEW_FILES="$(find "$REPO_ROOT/collected/$DATE" -maxdepth 1 -type f ! -name "*.err" 2>/dev/null | wc -l)"
  NEW_FILES="${NEW_FILES// /}"
  # List of files added (for Slack: link to commit or list); one per line, relative path
  echo "COMMITTABLE_FILES:"
  find "$REPO_ROOT/collected/$DATE" -maxdepth 1 -type f ! -name "*.err" 2>/dev/null | while read -r f; do
    echo "  collected/$DATE/$(basename "$f")"
  done
fi
echo "NEW_FILES_DOWNLOADED: $NEW_FILES"
echo "COLLECTION_DATE: ${DATE:- none}"
[ -n "$DATE" ] && echo "COLLECTION_DIR: collected/$DATE/"
GITHUB_REPO="${REAL_ESTATE_AI_GITHUB_REPO:-https://github.com/glh230/real_estate_ai}"
[ -n "$DATE" ] && echo "GITHUB_COLLECTED_LINK: ${GITHUB_REPO}/tree/main/collected/${DATE}"
echo "GITHUB_COMMIT_LINK_HINT: After push, run: git log -1 --format=${GITHUB_REPO}/commit/%H"
echo "SLACK_LINE: :file_folder: New files downloaded: $NEW_FILES (collected/${DATE:-none})"
echo ""
echo "——— End summary ———"
