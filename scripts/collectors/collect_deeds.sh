#!/usr/bin/env bash
# =============================================================================
# collect_deeds.sh
# Downloads deed transfer / sale records.
# Common sources: county recorder RSS feeds, bulk CSV exports.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/helpers.sh"

log_info "=== Deeds Collector START ==="

mapfile -t URLS < <(
  jq -r '.sources[] | select(.type=="deeds" and .enabled==true) | .urls[]?' \
    "$CONFIG_DIR/sources.json"
)

if [ ${#URLS[@]} -eq 0 ]; then
  log_warn "No deed URLs configured yet — add county recorder feeds to sources.json."
  exit 0
fi

for url in "${URLS[@]}"; do
  # If it looks like an RSS feed, parse links first
  if echo "$url" | grep -qiE '(rss|feed|atom)'; then
    log_info "Parsing RSS feed: $url"
    while IFS= read -r link; do
      fetch_document "$link" "deeds"
    done < <(parse_rss_links "$url")
  else
    fetch_document "$url" "deeds"
  fi
done

log_info "=== Deeds Collector END ==="
