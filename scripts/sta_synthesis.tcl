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
