#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_dev.sh — Launch Jom Kuiz in development mode.
#
# Reads SUPABASE_URL and SUPABASE_ANON_KEY from the environment (Replit
# Secrets or a locally exported .env) and passes them as --dart-define flags.
#
# Usage:
#   bash run_dev.sh                     # Flutter chooses available device
#   bash run_dev.sh -d chrome           # Run on Chrome (web)
#   bash run_dev.sh -d <device-id>      # Run on a specific device/emulator
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "ERROR: SUPABASE_URL is not set. Export it or add it to Replit Secrets."
  exit 1
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "ERROR: SUPABASE_ANON_KEY is not set. Export it or add it to Replit Secrets."
  exit 1
fi

echo "→ Supabase URL : ${SUPABASE_URL}"
echo "→ Anon key     : ${SUPABASE_ANON_KEY:0:20}..."

flutter run \
  --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
  --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" \
  "$@"
