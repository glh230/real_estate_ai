#!/usr/bin/env bash
# =============================================================================
# helpers.sh — shared utilities for all collectors
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOGS_DIR="$REPO_ROOT/logs"
DATA_DIR="$REPO_ROOT/data"
CONFIG_DIR="$REPO_ROOT/scripts/config"
LOCK_FILE="/tmp/real_estate_collector.lock"

# Ensure log dir exists
mkdir -p "$LOGS_DIR"

# ---------------------------------------------------------------------------
log() {
  local level="$1"; shift
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [$level] $*" | tee -a "$LOGS_DIR/collector.log"
}

log_info()  { log "INFO " "$@"; }
log_warn()  { log "WARN " "$@"; }
log_error() { log "ERROR" "$@"; }

# ---------------------------------------------------------------------------
# Acquire an exclusive lock so two cron runs don't stomp each other
acquire_lock() {
  if [ -f "$LOCK_FILE" ]; then
    local pid
    pid=$(cat "$LOCK_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      log_warn "Collector already running (PID $pid). Exiting."
      exit 0
    else
      log_warn "Stale lock found (PID $pid). Removing."
      rm -f "$LOCK_FILE"
    fi
  fi
  echo $$ > "$LOCK_FILE"
  trap 'rm -f "$LOCK_FILE"' EXIT
}

# ---------------------------------------------------------------------------
# Download a URL and save to target dir, skip if already downloaded today
# Usage: fetch_document <url> <data_subdir> [filename_override]
fetch_document() {
  local url="$1"
  local subdir="$2"
  local override_name="${3:-}"
  local dest_dir="$DATA_DIR/$subdir"
  mkdir -p "$dest_dir"

  local filename
  if [ -n "$override_name" ]; then
    filename="$override_name"
  else
    # derive a safe filename from URL + today's date
    local url_hash
    url_hash=$(echo -n "$url" | md5sum | cut -c1-8)
    local ext="${url##*.}"
    [ ${#ext} -gt 5 ] && ext="bin"
    filename="$(date -u +%Y%m%d)_${url_hash}.${ext}"
  fi

  local dest="$dest_dir/$filename"

  if [ -f "$dest" ]; then
    log_info "Already downloaded: $filename — skipping"
    return 0
  fi

  log_info "Downloading: $url → $dest"
  if curl -fsSL --max-time 60 --retry 3 --retry-delay 5 \
      -A "Mozilla/5.0 (compatible; RealEstateBot/1.0)" \
      -o "$dest" "$url"; then
    log_info "Saved: $dest"
    echo "$dest"   # return path
  else
    log_error "Failed to download: $url"
    rm -f "$dest"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Parse an RSS/Atom feed and echo each <link> found
parse_rss_links() {
  local feed_url="$1"
  curl -fsSL --max-time 30 "$feed_url" \
    | grep -oP '(?<=<link>)[^<]+' \
    | grep -v '^$'
}

# ---------------------------------------------------------------------------
# Git add + commit + push any new files
commit_and_push() {
  cd "$REPO_ROOT" || return 1
  git add data/ logs/
  local changed
  changed=$(git diff --cached --name-only | wc -l)
  if [ "$changed" -eq 0 ]; then
    log_info "Nothing new to commit."
    return 0
  fi
  local msg="chore: auto-ingest ${changed} file(s) — $(date -u +"%Y-%m-%d %H:%M UTC")"
  git commit -m "$msg"
  if git push origin main; then
    log_info "Pushed $changed new file(s) to GitHub."
  else
    log_error "Git push failed."
    return 1
  fi
}
