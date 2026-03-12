#!/usr/bin/env bash
# =============================================================================
# collect_public_records.sh
# Fetches official public real estate records (deeds, transfers, filings).
# Sources are defined in scripts/config/sources.json
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/helpers.sh"

log_info "=== Public Records Collector START ==="

# ---- Read enabled URLs from config ----------------------------------------
if ! command -v jq &>/dev/null; then
  log_error "jq is required. Install with: apt-get install -y jq"
  exit 1
fi

mapfile -t URLS < <(
  jq -r '.sources[] | select(.type=="public_records" and .enabled==true) | .urls[]?' \
    "$CONFIG_DIR/sources.json"
)

if [ ${#URLS[@]} -eq 0 ]; then
  log_warn "No public_records URLs configured in sources.json — add some to start collecting."
  exit 0
fi

for url in "${URLS[@]}"; do
  fetch_document "$url" "public_records"
done

log_info "=== Public Records Collector END ==="
