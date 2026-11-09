#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${STA_LIBERTY_FILES:?Defina STA_LIBERTY_FILES=/ruta/a/sky130.lib (varias rutas separadas por :)}"
if command -v sta >/dev/null 2>&1; then
  STA_BIN=sta
elif command -v openroad >/dev/null 2>&1; then
  STA_BIN=openroad
else
  echo "ERROR: no se encontro 'sta' ni 'openroad' en PATH" >&2
  exit 1
fi
mkdir -p reports
echo "Analizando netlist sintetizada con: $STA_BIN"
echo "Liberty(s): $STA_LIBERTY_FILES"
echo "STA pre-placement: sin SPEF, no directamente equivalente a STA post-routing"
"$STA_BIN" -exit scripts/sta_synthesis.tcl 2>&1 | tee reports/sta_synthesis_preplacement.txt
