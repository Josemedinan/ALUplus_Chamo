# Punto de partida: 100 ns = 10 MHz. Ajustar tras revisar el timing real.
create_clock -name clk -period 100 [get_ports clk]
set_input_delay 2 -clock clk [get_ports {A* B* ALUControl* valid_in}]
set_output_delay 2 -clock clk [get_ports {Result* N Z C V div_by_zero valid_out}]
