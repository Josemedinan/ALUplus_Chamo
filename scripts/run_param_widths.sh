#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/parameter_tests
python3 - <<'PY'
from pathlib import Path
source = Path("tb/tb_alu_plus.sv").read_text()
old = "localparam int WIDTH = 16;"
if old not in source:
    raise SystemExit("ERROR: no se encontro declaracion esperada de WIDTH")
Path("build/parameter_tests/tb_alu_plus_param.sv").write_text(
    source.replace(old, "parameter int WIDTH = 16;", 1)
)
PY
for W in 8 16 32; do
  echo "=== WIDTH=$W ==="
  verilator --binary --timing --assert -Wno-fatal \
    --top-module tb_alu_plus -GWIDTH="$W" \
    --Mdir "build/parameter_tests/obj_$W" -o simulation \
    rtl/cla_adder.sv rtl/restoring_divider.sv rtl/alu_plus.sv \
    rtl/alu_plus_sync.sv build/parameter_tests/tb_alu_plus_param.sv \
    > "build/parameter_tests/build_$W.log" 2>&1
  "build/parameter_tests/obj_$W/simulation"
done
echo "PARAMETRIZATION_REGRESSION_COMPLETED"
