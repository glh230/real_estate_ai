#!/usr/bin/env bash
# Real Estate Data Collector — run the URL-based scraper, commit and push to GitHub,
# then print a summary for the OpenClaw cron job. .err files are ignored.
# The script performs the commit so the flow always completes; the agent only posts to Slack.
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

# 3) Commit and push in this script so the flow always runs (do not rely on the agent)
COMMIT_URL=""
if [ -n "$DATE" ] && [ "$NEW_FILES" -gt 0 ] && git rev-parse --is-inside-work-tree &>/dev/null; then
  # Ensure git can make a commit (user.name/user.email)
  if [ -z "$(git config user.name 2>/dev/null)" ]; then
    git config user.name "OpenClaw Collector" 2>/dev/null || true
  fi
  if [ -z "$(git config user.email 2>/dev/null)" ]; then
    git config user.email "collector@openclaw" 2>/dev/null || true
  fi
  git add "collected/$DATE/"
  if ! git diff --staged --quiet 2>/dev/null; then
    if git commit -m "Collect real estate data $DATE"; then
      if git push 2>/dev/null; then
        COMMIT_URL="$(git log -1 --format="${GITHUB_REPO}/commit/%H")"
      else
        COMMIT_URL="(push failed — check remote and auth)"
      fi
    else
      COMMIT_URL="(commit failed)"
    fi
  fi
fi
if [ -z "$COMMIT_URL" ] && [ -n "$DATE" ] && [ "$NEW_FILES" -gt 0 ]; then
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    COMMIT_URL="(not a git repo — clone the repo into this workspace)"
  else
    COMMIT_URL="(no new changes to commit or commit/push failed)"
  fi
fi

# 4) Summary for Slack (agent uses these lines)
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
echo "GITHUB_COMMIT_URL: ${COMMIT_URL:- (none)}"
echo "SLACK_LINE: :file_folder: New files downloaded: $NEW_FILES (collected/${DATE:-none})"
echo ""
echo "——— End summary ———"
