#!/usr/bin/env bash
# Runs the visible Supabase e2e flow (integration_test/supabase_e2e_test.dart)
# against a real LecheControl Supabase project and a real, pre-seeded e2e
# user. Skips (does not fail) if credentials are not set — safe to leave
# wired into CI before the seed user exists.
#
# Required dart-defines (env vars below map 1:1 to them):
#   LECHE_SUPABASE_URL        Supabase project URL (LecheControl project,
#                              NOT HatoControl's).
#   LECHE_SUPABASE_ANON_KEY   Supabase anon/publishable key for that project.
#   LECHE_E2E_EMAIL           Email of a pre-seeded Supabase user (see
#                              docs/QA_AUTOMATION.md for the seed SQL).
#   LECHE_E2E_PASSWORD        Password for that user.
#
# Optional:
#   LECHE_E2E_SLOW_MS         Pause (ms) after each step, for demoing on a
#                              simulator (default: 0, no pause).
#   DEVICE                    Target device id/name for `flutter test -d`
#                              (default: macos).
#
# Usage:
#   # Preferred: put credentials in gitignored .local/e2e_credentials.env
#   ./scripts/run_e2e.sh
#
#   # Or export env vars manually:
#   LECHE_SUPABASE_URL=... LECHE_SUPABASE_ANON_KEY=... \
#   LECHE_E2E_EMAIL=... LECHE_E2E_PASSWORD=... \
#   ./scripts/run_e2e.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# Auto-load local credentials if present (never committed — see .gitignore .local/)
if [[ -f .local/e2e_credentials.env ]]; then
  # shellcheck disable=SC1091
  set -a
  # shellcheck disable=SC1091
  source .local/e2e_credentials.env
  set +a
fi

DEVICE="${DEVICE:-macos}"
LECHE_SUPABASE_URL="${LECHE_SUPABASE_URL:-}"
LECHE_SUPABASE_ANON_KEY="${LECHE_SUPABASE_ANON_KEY:-}"
LECHE_E2E_EMAIL="${LECHE_E2E_EMAIL:-}"
LECHE_E2E_PASSWORD="${LECHE_E2E_PASSWORD:-}"
LECHE_E2E_SLOW_MS="${LECHE_E2E_SLOW_MS:-0}"

# Hard guard: never point e2e at HatoControl by accident
if [[ "$LECHE_SUPABASE_URL" == *"geocoundyilwxrnbhcqu"* ]]; then
  echo "ABORT: LECHE_SUPABASE_URL apunta al proyecto de HatoControl."
  echo "Usá solo supabase-LecheControl (yskvlaovqvjfodiroaqz)."
  exit 1
fi

if [[ -z "$LECHE_E2E_EMAIL" || -z "$LECHE_E2E_PASSWORD" ]]; then
  echo "LECHE_E2E_EMAIL / LECHE_E2E_PASSWORD no están definidos."
  echo "Este e2e se salta (no falla). Ver docs/QA_AUTOMATION.md para sembrar"
  echo "un usuario de prueba y correrlo de verdad."
  exit 0
fi

if [[ -z "$LECHE_SUPABASE_URL" || -z "$LECHE_SUPABASE_ANON_KEY" ]]; then
  echo "Falta LECHE_SUPABASE_URL / LECHE_SUPABASE_ANON_KEY: sin esto la app"
  echo "arranca en modo offline/demo y el login real no va a funcionar."
  exit 1
fi

echo "== pub get =="
flutter pub get

echo "== e2e Supabase visible ($DEVICE) project=$LECHE_SUPABASE_URL =="
# LECHE_DB_NAME aísla el SQLite del e2e para no mezclar datos demo/pendientes
# de corridas manuales (eso disparaba RLS al subir filas ajenas).
E2E_DB_NAME="${LECHE_DB_NAME:-lechecontrol_e2e}"
flutter test -d "$DEVICE" integration_test/supabase_e2e_test.dart \
  --dart-define=LECHE_SUPABASE_URL="$LECHE_SUPABASE_URL" \
  --dart-define=LECHE_SUPABASE_ANON_KEY="$LECHE_SUPABASE_ANON_KEY" \
  --dart-define=LECHE_E2E_EMAIL="$LECHE_E2E_EMAIL" \
  --dart-define=LECHE_E2E_PASSWORD="$LECHE_E2E_PASSWORD" \
  --dart-define=LECHE_E2E_SLOW_MS="$LECHE_E2E_SLOW_MS" \
  --dart-define=LECHE_DB_NAME="$E2E_DB_NAME"

echo "OK — e2e Supabase passed."
