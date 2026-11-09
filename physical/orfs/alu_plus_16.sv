module alu_plus_16 (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    input  wire [15:0] A,
    input  wire [15:0] B,
    input  wire [2:0] ALUControl,
    output wire valid_out,
    output wire [15:0] Result,
    output wire N, Z, C, V,
    output wire div_by_zero
);

    alu_plus_sync #(.WIDTH(16)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .A(A),
        .B(B),
        .ALUControl(ALUControl),
        .valid_out(valid_out),
        .Result(Result),
        .N(N),
        .Z(Z),
        .C(C),
        .V(V),
        .div_by_zero(div_by_zero)
    );

endmodule
