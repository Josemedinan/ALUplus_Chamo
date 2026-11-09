`default_nettype none
// SOLO demostracion para simulacion 4 estados, EXCLUIR de sintesis ASIC.
module tristate_demo #(parameter int WIDTH=8) (
    input wire [WIDTH-1:0] A, B,
    input wire enable_and, enable_or,
    output tri [WIDTH-1:0] and_bus, or_bus
);
    assign and_bus = enable_and ? (A & B) : {WIDTH{1'bz}};
    assign or_bus  = enable_or  ? (A | B) : {WIDTH{1'bz}};
endmodule
`default_nettype wire
