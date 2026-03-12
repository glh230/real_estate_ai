#!/usr/bin/env bash
# =============================================================================
# collect_foreclosures.sh
# Downloads foreclosure notices from legal notice databases and HUD feeds.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/helpers.sh"

log_info "=== Foreclosures Collector START ==="

mapfile -t URLS < <(
  jq -r '.sources[] | select(.type=="foreclosures" and .enabled==true) | .urls[]?' \
    "$CONFIG_DIR/sources.json"
)

if [ ${#URLS[@]} -eq 0 ]; then
  log_warn "No foreclosure URLs configured yet — add HUD/legal notice feeds to sources.json."
  exit 0
fi

for url in "${URLS[@]}"; do
  if echo "$url" | grep -qiE '(rss|feed|atom)'; then
    log_info "Parsing RSS feed: $url"
    while IFS= read -r link; do
      fetch_document "$link" "foreclosures"
    done < <(parse_rss_links "$url")
  else
    fetch_document "$url" "foreclosures"
  fi
done

log_info "=== Foreclosures Collector END ==="
