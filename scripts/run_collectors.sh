#!/usr/bin/env bash
# =============================================================================
# run_collectors.sh — MAIN ENTRY POINT
# Runs all enabled collectors in sequence, then commits + pushes new data.
# Called by the OpenClaw cron job every 5 minutes.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

# Only one instance at a time
acquire_lock

log_info "========================================="
log_info "Real Estate Data Collector — $(date -u)"
log_info "========================================="

# Set git identity for auto-commits
cd "$REPO_ROOT" || exit 1
git config user.email "bot@real-estate-ai" 2>/dev/null || true
git config user.name  "RealEstateBot"      2>/dev/null || true

# Pull latest before collecting (avoid merge conflicts)
git pull --rebase origin main 2>&1 | while IFS= read -r line; do log_info "[git] $line"; done

# ---- Run each collector ---------------------------------------------------
COLLECTORS=(
  "collect_public_records.sh"
  "collect_permits.sh"
  "collect_deeds.sh"
  "collect_foreclosures.sh"
  "collect_tax_records.sh"
  "collect_zoning.sh"
)

FAILED=0
for collector in "${COLLECTORS[@]}"; do
  script="$SCRIPT_DIR/collectors/$collector"
  if [ -x "$script" ]; then
    log_info "--- Running: $collector ---"
    if bash "$script"; then
      log_info "--- $collector: OK ---"
    else
      log_error "--- $collector: FAILED ---"
      FAILED=$((FAILED + 1))
    fi
  else
    log_warn "Skipping $collector — not executable or not found"
  fi
done

# ---- Commit & push any new files -----------------------------------------
commit_and_push

log_info "========================================="
log_info "Collection run complete. Failures: $FAILED"
log_info "========================================="

exit $FAILED
