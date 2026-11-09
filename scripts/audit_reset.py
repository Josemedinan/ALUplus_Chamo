#!/usr/bin/env python3
"""Auditoría estática de reset y restricciones ALU+ CHAMO.

No sustituye los checks dinámicos de recovery/removal del STA de Liberty.
Salida JSON verificable por una ejecución local con Python estándar.
"""
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parents[1]
rtl = (root / "rtl/alu_plus_sync.sv").read_text()
sdc = (root / "physical/orfs/constraint.sdc").read_text()
synth_sdc = (root / "deliverables/synthesis.sdc").read_text()
final_sdc = (root / "deliverables/final.sdc").read_text()

checks = {
    "reset_async_active_low_rtl": bool(re.search(
        r"always_ff\s*@\(\s*posedge\s+clk\s+or\s+negedge\s+rst_n\s*\)", rtl
    )),
    "reset_has_explicit_branch": bool(re.search(
        r"if\s*\(\s*!rst_n\s*\)", rtl
    )),
    "clock_100ns_input_sdc": bool(re.search(
        r"create_clock[^\n]*-period\s+100(?:\.0+)?(?:\s|$)", sdc
    )),
    "synthesis_sdc_exists": "create_clock" in synth_sdc,
    "final_sdc_propagates_clock": "set_propagated_clock" in final_sdc,
    "no_blanket_reset_false_path_in_input_sdc": not bool(re.search(
        r"(?m)^\s*set_false_path[^\n]*rst_n", sdc
    )),
    "no_reset_input_delay_in_input_sdc": not bool(re.search(
        r"(?m)^\s*set_input_delay[^\n]*rst_n", sdc
    )),
}
all_ok = all(checks.values())
result = {
    "design": "ALU+ CHAMO",
    "audit": "static_reset_sdc",
    "checks": checks,
    "static_audit_pass": all_ok,
    "timing_signoff": "NOT_EVALUATED",
    "recovery_removal": "NOT_EVALUATED",
    "reset_release_synchronization": "NOT_PRESENT_IN_RTL",
    "interpretation": (
        "Las comprobaciones estaticas caracterizan el RTL y el SDC; "
        "no prueban recovery/removal ni una liberacion segura del reset."
    ),
}
print(json.dumps(result, indent=2, ensure_ascii=False))
raise SystemExit(0 if all_ok else 1)
