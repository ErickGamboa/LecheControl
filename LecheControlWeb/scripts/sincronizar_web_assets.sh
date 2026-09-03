#!/usr/bin/env bash
#
# Resincroniza lo que este proyecto tiene copiado del móvil:
#
#   1. Los PNG que declara `pubspec.yaml` (Flutter solo encuentra
#      Image.asset('assets/...') en el paquete que corre, no en sus
#      dependencias de ruta, así que hay que tenerlos acá).
#   2. `sqlite3.wasm` y `drift_worker.js`, en las versiones EXACTAS que
#      resolvió el `pubspec.lock` del móvil.
#
# Correlo después de cambiar un PNG en el móvil o de subir la versión de
# drift o de sqlite3. Un worker de otra versión no falla al compilar: falla
# en el navegador, al abrir la base.
#
#   ./scripts/sincronizar_web_assets.sh
#
set -euo pipefail

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
movil="$raiz/../LecheControlMovil"

if [[ ! -f "$movil/pubspec.lock" ]]; then
  echo "No encuentro $movil/pubspec.lock" >&2
  echo "Los dos proyectos tienen que estar uno al lado del otro en el mismo" >&2
  echo "repositorio. Si cloná solo el proyecto web, no compila." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Assets declarados. Solo los que están en el pubspec de ESTE proyecto: la
#    idea es no arrastrar la carpeta completa y meter en el bundle imágenes
#    que la app nunca abre.
# ---------------------------------------------------------------------------
echo "== Assets =="
declarados=$(sed -n 's#^ *- assets/\(.*\)$#\1#p' "$raiz/pubspec.yaml")

if [[ -z "$declarados" ]]; then
  echo "  (el pubspec no declara ningún asset)"
fi

for archivo in $declarados; do
  origen="$movil/assets/$archivo"
  destino="$raiz/assets/$archivo"
  if [[ ! -f "$origen" ]]; then
    echo "  FALTA en el móvil: assets/$archivo" >&2
    exit 1
  fi
  if [[ -f "$destino" ]] && cmp -s "$origen" "$destino"; then
    echo "  igual     assets/$archivo"
  else
    cp "$origen" "$destino"
    echo "  copiado   assets/$archivo"
  fi
done

# Avisar de archivos que quedaron en assets/ pero ya nadie declara.
for existente in "$raiz"/assets/*; do
  [[ -e "$existente" ]] || continue
  nombre="$(basename "$existente")"
  if ! grep -q "assets/$nombre" "$raiz/pubspec.yaml"; then
    echo "  SOBRA (no declarado, se puede borrar): assets/$nombre"
  fi
done

# ---------------------------------------------------------------------------
# 2. sqlite3.wasm y drift_worker.js, leyendo las versiones del lock del móvil.
# ---------------------------------------------------------------------------
version_de() {
  awk -v clave="  $1:" '
    $0 == clave { dentro = 1; next }
    dentro && /^    version:/ { gsub(/"/, "", $2); print $2; exit }
    dentro && /^  [a-z]/ { exit }
  ' "$movil/pubspec.lock"
}

v_drift=$(version_de drift)
v_sqlite=$(version_de sqlite3)

if [[ -z "$v_drift" || -z "$v_sqlite" ]]; then
  echo "No pude leer las versiones de drift/sqlite3 del pubspec.lock" >&2
  exit 1
fi

echo "== Base local en el navegador =="
echo "  drift $v_drift  /  sqlite3 $v_sqlite  (del pubspec.lock del móvil)"

bajar() {
  local url="$1" destino="$2"
  local tmp
  tmp="$(mktemp)"
  if ! curl -fsSL -o "$tmp" "$url"; then
    echo "  NO SE PUDO BAJAR: $url" >&2
    rm -f "$tmp"
    exit 1
  fi
  if [[ -f "$destino" ]] && cmp -s "$tmp" "$destino"; then
    echo "  igual     web/$(basename "$destino")"
    rm -f "$tmp"
  else
    mv "$tmp" "$destino"
    echo "  bajado    web/$(basename "$destino")"
  fi
}

bajar \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$v_sqlite/sqlite3.wasm" \
  "$raiz/web/sqlite3.wasm"

bajar \
  "https://github.com/simolus3/drift/releases/download/drift-$v_drift/drift_worker.js" \
  "$raiz/web/drift_worker.js"

# El .wasm tiene que empezar con el número mágico de WebAssembly. Si el
# release no existe, GitHub devuelve una página HTML con código 200 y sin esta
# comprobación se guardaría como si fuera el módulo.
if [[ "$(head -c 4 "$raiz/web/sqlite3.wasm" | od -An -tx1 | tr -d ' \n')" != "0061736d" ]]; then
  echo "  web/sqlite3.wasm no es un módulo WebAssembly válido" >&2
  exit 1
fi

echo
echo "Listo. Ahora: flutter build web"
