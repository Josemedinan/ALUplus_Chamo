#!/usr/bin/env bash
set -u
for cmd in code verilator yosys openroad klayout; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] $cmd: $(command -v "$cmd")"
  else
    echo "[NO] $cmd (puede estar dentro de OSS-CAD-Suite/Nix/contendor)"
  fi
done
for d in "$HOME/.ciel/sky130A" "$HOME/.ciel/sky130B" "$HOME/.volare/sky130A"; do
  [ ! -d "$d" ] || echo "[PDK] $d"
done
