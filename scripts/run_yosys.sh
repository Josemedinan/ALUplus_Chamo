#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p reports netlist
# Sintesis generica sin tecnologia: las cifras NO son area SKY130.
yosys -l reports/yosys_generic.log -p '
  read_verilog -sv rtl/cla_adder.sv rtl/restoring_divider.sv rtl/alu_plus.sv rtl/alu_plus_sync.sv
  hierarchy -check -top alu_plus_sync -chparam WIDTH 16
  synth -top alu_plus_sync
  check
  stat
  write_verilog -noattr netlist/alu_plus_sync_generic.v
'
