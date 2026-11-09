#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== VALIDACION ESTATICA DE RESET Y SDC ==="
python3 scripts/audit_reset.py

echo
echo "=== ENTREGABLES DE IMPLEMENTACION ==="
for f in \
  deliverables/ALUplus_CHAMO_synthesis.v \
  deliverables/ALUplus_CHAMO_postroute.v \
  deliverables/ALUplus_CHAMO_final.gds \
  deliverables/ALUplus_CHAMO_final.odb \
  deliverables/synthesis.sdc \
  deliverables/final.sdc; do
  test -s "$f" || { echo "ARCHIVO_AUSENTE: $f" >&2; exit 1; }
  echo "OK: $f"
done

echo
echo "=== INTEGRIDAD DE ENTREGABLES ==="
(
  cd deliverables
  shasum -a 256 -c SHA256SUMS.txt
)

# Descubrimiento opcional de Liberty instalada: no modifica la tecnologia de la corrida.
if [ -z "${STA_LIBERTY_FILES:-}" ]; then
  for root in "$HOME/.ciel" "$HOME/.volare" "$HOME/oss-cad-suite" "/opt/sky130"; do
    [ -d "$root" ] || continue
    candidate=$(find "$root" -type f -name 'sky130_fd_sc_hd__tt_025C_1v80.lib' -print -quit 2>/dev/null || true)
    if [ -n "$candidate" ]; then
      export STA_LIBERTY_FILES="$candidate"
      echo "LIBERTY_DETECTADA: $STA_LIBERTY_FILES"
      break
    fi
  done
fi

if [ -n "${STA_LIBERTY_FILES:-}" ]; then
  echo
  echo "=== STA PRE-PLACEMENT DE SINTESIS ==="
  bash scripts/run_sta_synthesis.sh
else
  echo
  echo "STA_SINTESIS_NO_EJECUTADO: definir STA_LIBERTY_FILES con Liberty SKY130HD"
  echo "La auditoria estatica NO certifica recovery/removal ni reset release."
fi
echo "VALIDACIONES_DISPONIBLES_FINALIZADAS"
