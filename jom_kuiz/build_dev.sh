#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# build_dev.sh — Build Jom Kuiz APK (debug) with Supabase credentials baked in.
#
# Usage:
#   bash build_dev.sh                   # builds APK
#   bash build_dev.sh --release         # builds release APK
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "ERROR: SUPABASE_URL is not set."
  exit 1
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "ERROR: SUPABASE_ANON_KEY is not set."
  exit 1
fi

echo "→ Building APK for ${SUPABASE_URL}"

flutter build apk \
  --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
  --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" \
  "$@"

echo "✓ Build complete: build/app/outputs/flutter-apk/"
