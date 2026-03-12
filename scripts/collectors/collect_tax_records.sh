#!/usr/bin/env bash
# =============================================================================
# collect_tax_records.sh
# Downloads property tax assessment records from county assessor open data.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/helpers.sh"

log_info "=== Tax Records Collector START ==="

mapfile -t URLS < <(
  jq -r '.sources[] | select(.type=="tax_records" and .enabled==true) | .urls[]?' \
    "$CONFIG_DIR/sources.json"
)

if [ ${#URLS[@]} -eq 0 ]; then
  log_warn "No tax record URLs configured yet — add county assessor feeds to sources.json."
  exit 0
fi

for url in "${URLS[@]}"; do
  fetch_document "$url" "tax_records"
done

log_info "=== Tax Records Collector END ==="
