#!/usr/bin/env bash
# Runs the app in debug mode against the real LecheControl Supabase project,
# reading credentials from gitignored .local/e2e_credentials.env so they never
# have to be typed (or committed).
#
# Without these dart-defines the app boots with SupabaseConfig.estaConfigurado
# == false and the login screen shows "Esta app todavía no tiene un proyecto
# de Supabase configurado" — see lib/config/supabase_config.dart.
#
# Required (env vars map 1:1 to dart-defines):
#   LECHE_SUPABASE_URL        Supabase project URL (LecheControl project,
#                              NOT HatoControl's).
#   LECHE_SUPABASE_ANON_KEY   Supabase anon/publishable key for that project.
#
# Optional:
#   DEVICE                    Target device id for `flutter run -d`
#                              (default: the only attached Android emulator,
#                              else you must pass it).
#   LECHE_DEMO                Set to true to seed demo data.
#
# Usage:
#   ./scripts/run_dev.sh
#   DEVICE=emulator-5554 ./scripts/run_dev.sh
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

DEVICE="${DEVICE:-}"
LECHE_SUPABASE_URL="${LECHE_SUPABASE_URL:-}"
LECHE_SUPABASE_ANON_KEY="${LECHE_SUPABASE_ANON_KEY:-}"
LECHE_DEMO="${LECHE_DEMO:-false}"

# Hard guard: never point the app at HatoControl by accident
if [[ "$LECHE_SUPABASE_URL" == *"geocoundyilwxrnbhcqu"* ]]; then
  echo "ABORT: LECHE_SUPABASE_URL apunta al proyecto de HatoControl."
  echo "Usá solo supabase-LecheControl (yskvlaovqvjfodiroaqz)."
  exit 1
fi

if [[ -z "$LECHE_SUPABASE_URL" || -z "$LECHE_SUPABASE_ANON_KEY" ]]; then
  echo "Falta LECHE_SUPABASE_URL / LECHE_SUPABASE_ANON_KEY."
  echo "Poné ambos en .local/e2e_credentials.env, por ejemplo:"
  echo
  echo "  LECHE_SUPABASE_URL=https://yskvlaovqvjfodiroaqz.supabase.co"
  echo "  LECHE_SUPABASE_ANON_KEY=<anon-key>"
  echo
  echo "Sin esto la app arranca en modo offline y el login real no funciona."
  exit 1
fi

if [[ -z "$DEVICE" ]]; then
  echo "== flutter run (device autodetectado) project=$LECHE_SUPABASE_URL =="
  set --
else
  echo "== flutter run -d $DEVICE project=$LECHE_SUPABASE_URL =="
  set -- -d "$DEVICE"
fi

flutter run "$@" \
  --dart-define=LECHE_SUPABASE_URL="$LECHE_SUPABASE_URL" \
  --dart-define=LECHE_SUPABASE_ANON_KEY="$LECHE_SUPABASE_ANON_KEY" \
  --dart-define=LECHE_DEMO="$LECHE_DEMO"
