read_verilog -sv rtl/cla_adder.sv rtl/restoring_divider.sv rtl/alu_plus.sv rtl/alu_plus_sync.sv

hierarchy -check -top alu_plus_sync

synth -top alu_plus_sync -flatten -noabc

dfflibmap -liberty $::env(LIBERTY)
abc -liberty $::env(LIBERTY)

clean
check -assert
stat -liberty $::env(LIBERTY)

write_verilog -noattr -noexpr build/sky130/alu_plus_sync_mapped.v
