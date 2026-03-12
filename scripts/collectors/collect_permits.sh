#!/usr/bin/env bash
# =============================================================================
# collect_permits.sh
# Downloads building permit data from open data portals.
# Many cities expose permits via Socrata (data.cityname.gov) as CSV/JSON.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/helpers.sh"

log_info "=== Permits Collector START ==="

mapfile -t URLS < <(
  jq -r '.sources[] | select(.type=="permits" and .enabled==true) | .urls[]?' \
    "$CONFIG_DIR/sources.json"
)

if [ ${#URLS[@]} -eq 0 ]; then
  log_warn "No permit URLs configured yet — add Socrata/open-data endpoints to sources.json."
  exit 0
fi

for url in "${URLS[@]}"; do
  fetch_document "$url" "permits"
done

log_info "=== Permits Collector END ==="
