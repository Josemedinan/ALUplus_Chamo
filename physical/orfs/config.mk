export DESIGN_NAME = alu_plus_16
export DESIGN_NICKNAME = chamo
export PLATFORM = sky130hd

export VERILOG_FILES = \
    /workspace/rtl/cla_adder.sv \
    /workspace/rtl/restoring_divider.sv \
    /workspace/rtl/alu_plus.sv \
    /workspace/rtl/alu_plus_sync.sv \
    /workspace/physical/orfs/alu_plus_16.sv

export SDC_FILE = /workspace/physical/orfs/constraint.sdc

export CORE_UTILIZATION = 30
export DIE_ASPECT_RATIO = 1
