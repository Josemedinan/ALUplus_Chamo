#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p reports
for top in tb_alu_plus tb_alu_plus_sync; do
  verilator --binary --timing --assert -Wno-fatal --top-module "$top" \
      --Mdir "build/$top" -o simulation \
      rtl/cla_adder.sv rtl/restoring_divider.sv rtl/alu_plus.sv \
      rtl/alu_plus_sync.sv "tb/$top.sv" \
      > "reports/${top}_build.log" 2>&1
  "build/$top/simulation" | tee "reports/${top}_run.log"
done
