#!/usr/bin/env bash
# Real Estate Data Collector — run the URL-based scraper only. .err files are ignored for counts.
# OpenClaw agent is responsible for: git add, commit, push, and posting the commit link to Slack.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
GITHUB_REPO="${REAL_ESTATE_AI_GITHUB_REPO:-https://github.com/glh230/real_estate_ai}"

echo "——— Real Estate Data Collector ———"
echo ""

# 1) Run the URL-based collector
if ! python3 scripts/collect_from_urls.py; then
  echo "WARNING: URL collector had one or more failures (see above)."
fi
echo ""

# 2) Determine collection date and count (non-.err only)
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
  NEW_FILES="$(find "$REPO_ROOT/collected/$DATE" -maxdepth 1 -type f ! -name "*.err" 2>/dev/null | wc -l)"
  NEW_FILES="${NEW_FILES// /}"
fi

# 3) Summary for the agent (agent does git add / commit / push and posts to Slack)
echo "COMMITTABLE_FILES:"
if [ -n "$DATE" ] && [ -d "$REPO_ROOT/collected/$DATE" ]; then
  find "$REPO_ROOT/collected/$DATE" -maxdepth 1 -type f ! -name "*.err" 2>/dev/null | while read -r f; do
    echo "  collected/$DATE/$(basename "$f")"
  done
fi
echo "NEW_FILES_DOWNLOADED: $NEW_FILES"
echo "COLLECTION_DATE: ${DATE:- none}"
[ -n "$DATE" ] && echo "COLLECTION_DIR: collected/$DATE/"
[ -n "$DATE" ] && echo "GITHUB_COLLECTED_LINK: ${GITHUB_REPO}/tree/main/collected/${DATE}"
echo "SLACK_LINE: :file_folder: New files downloaded: $NEW_FILES (collected/${DATE:-none})"
echo ""
echo "——— End summary ———"
