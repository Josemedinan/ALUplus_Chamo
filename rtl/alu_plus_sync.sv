`default_nettype none
// Un registro en entradas y otro en salidas; latencia observable: 2 flancos.
module alu_plus_sync #(
    parameter int WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [WIDTH-1:0] A,
    input wire [WIDTH-1:0] B,
    input wire [2:0] ALUControl,
    output logic valid_out,
    output logic [WIDTH-1:0] Result,
    output logic N, Z, C, V,
    output logic div_by_zero
);
    logic [WIDTH-1:0] a_q, b_q;
    logic [2:0] control_q;
    logic valid_q;
    wire [WIDTH-1:0] result_comb;
    wire n_comb,z_comb,c_comb,v_comb,div0_comb;
    alu_plus #(.WIDTH(WIDTH)) u_alu (
        .A(a_q), .B(b_q), .ALUControl(control_q), .Result(result_comb),
        .N(n_comb), .Z(z_comb), .C(c_comb), .V(v_comb),
        .div_by_zero(div0_comb)
    );
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_q <= '0;
            b_q <= '0;
            control_q <= '0;
            valid_q <= 1'b0;
            valid_out <= 1'b0;
            Result <= '0;
            N <= 1'b0;
            Z <= 1'b1;
            C <= 1'b0;
            V <= 1'b0;
            div_by_zero <= 1'b0;
        end else begin
            a_q <= A;
            b_q <= B;
            control_q <= ALUControl;
            valid_q <= valid_in;
            Result <= result_comb;
            N <= n_comb;
            Z <= z_comb;
            C <= c_comb;
            V <= v_comb;
            div_by_zero <= div0_comb;
            valid_out <= valid_q;
        end
    end
endmodule
`default_nettype wire
