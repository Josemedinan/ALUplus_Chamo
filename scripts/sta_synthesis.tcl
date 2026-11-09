# STA pre-placement de la netlist mapeada de ALU+ CHAMO.
# Ejecutar en OpenSTA/OpenROAD desde la raiz del repositorio.
# Variable STA_LIBERTY_FILES: una o mas rutas Liberty separadas por ':'.
# IMPORTANTE: sin SPEF ni ubicacion fisica, no equivale al STA post-routing.
if {![info exists ::env(STA_LIBERTY_FILES)] || $::env(STA_LIBERTY_FILES) eq ""} {
    error "Defina STA_LIBERTY_FILES con ruta(s) a Liberty SKY130HD"
}
foreach lib [split $::env(STA_LIBERTY_FILES) ":"] {
    if {$lib eq ""} { continue }
    if {![file exists $lib]} { error "No existe Liberty: $lib" }
    puts "LIBERTY_USADA: $lib"
    read_liberty $lib
}
# OpenROAD requiere tecnologia física para enlazar instancias a celdas OpenDB.
# Buscar exclusivamente dentro de directorios conocidos de ORFS (no recorrer HOME).
set platform_roots [list \
    /OpenROAD-flow-scripts/flow/platforms/sky130hd \
    /OpenROAD-flow-scripts/flow/platforms/sky130hd/lef \
    /opt/ORFS/flow/platforms/sky130hd \
    /opt/ORFS/flow/platforms/sky130hd/lef]
if {[info exists ::env(ORFS_SKY130HD_PLATFORM)] && $::env(ORFS_SKY130HD_PLATFORM) ne ""} {
    set platform_roots [linsert $platform_roots 0 $::env(ORFS_SKY130HD_PLATFORM)]
}
set tech_lef ""
set cells_lef ""
foreach root $platform_roots {
    foreach d [list $root [file join $root lef]] {
        foreach name {sky130_fd_sc_hd.tlef sky130_fd_sc_hd__nom.tlef tech.lef} {
            set p [file join $d $name]
            if {$tech_lef eq "" && [file isfile $p]} { set tech_lef $p }
        }
        foreach name {sky130_fd_sc_hd.lef sky130_fd_sc_hd__nom.lef} {
            set p [file join $d $name]
            if {$cells_lef eq "" && [file isfile $p]} { set cells_lef $p }
        }
    }
}
if {$tech_lef eq "" || $cells_lef eq ""} {
    error "LEF_SKY130HD_NO_ENCONTRADO: busque en /OpenROAD-flow-scripts/flow/platforms/sky130hd/lef, o defina ORFS_SKY130HD_PLATFORM."
}
puts "TECH_LEF_USADO: $tech_lef"
read_lef $tech_lef
puts "CELLS_LEF_USADO: $cells_lef"
read_lef $cells_lef
read_verilog deliverables/ALUplus_CHAMO_synthesis.v
link_design alu_plus_16
read_sdc deliverables/synthesis.sdc
puts "\n===== LIMITACION: STA sin parasitismos extraidos ni placement ====="
puts "===== CHEQUEO RESTRICCIONES ====="
check_setup
puts "===== RELOJ/RESTRICCIONES ====="
report_clock_properties
puts "===== PEOR CAMINO SETUP ====="
report_checks -path_delay max -group_path_count 1
puts "===== SLACK SETUP ====="
report_worst_slack -max
puts "===== PERIODO MINIMO ESTIMADO (sin RC extraido) ====="
report_clock_min_period
puts "===== PEOR CAMINO HOLD ====="
report_checks -path_delay min -group_path_count 1
puts "===== SLACK HOLD ====="
report_worst_slack -min

puts "===== NOTA DE RESET ====="
puts "Recovery/removal: su cobertura depende de los arcos de la Liberty y del modelo de reset. Revisar por separado."
