create_clock -name clk -period 100 [get_ports clk]

set_input_delay 2 -clock clk [get_ports {A* B* ALUControl* valid_in}]
set_output_delay 2 -clock clk [get_ports {Result* N Z C V valid_out div_by_zero}]
