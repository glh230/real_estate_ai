#!/usr/bin/env bash
# =============================================================================
# collect_zoning.sh
# Downloads zoning and land use data from city/county GIS open data portals.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/helpers.sh"

log_info "=== Zoning Collector START ==="

mapfile -t URLS < <(
  jq -r '.sources[] | select(.type=="zoning" and .enabled==true) | .urls[]?' \
    "$CONFIG_DIR/sources.json"
)

if [ ${#URLS[@]} -eq 0 ]; then
  log_warn "No zoning URLs configured yet — add GIS/open-data portal exports to sources.json."
  exit 0
fi

for url in "${URLS[@]}"; do
  fetch_document "$url" "zoning"
done

log_info "=== Zoning Collector END ==="
