#!/usr/bin/env bash
# Install dependencies for NC Real Estate collectors (jq for JSON, etc.).
# Run on the host or in your Docker image so collect_*.sh scripts work.
set -euo pipefail
if command -v apt-get &>/dev/null; then
  apt-get update -qq
  apt-get install -y -qq jq
  echo "Installed jq: $(jq --version)"
elif command -v brew &>/dev/null; then
  brew install jq
  echo "Installed jq: $(jq --version)"
else
  echo "No apt-get or brew found. Install jq manually: https://stedolan.github.io/jq/download/"
  exit 1
fi
