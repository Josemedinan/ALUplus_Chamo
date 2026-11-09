`default_nettype none
// CLA por bloques de 4 bits; WIDTH parametrizable, incluido WIDTH no multiplo de 4.
module cla_adder #(
    parameter int WIDTH = 8
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             cin,
    output wire [WIDTH-1:0] sum,
    output wire             cout
);
    localparam int GROUPS = (WIDTH + 3) / 4;
    wire [WIDTH-1:0] p = a ^ b;
    wire [WIDTH-1:0] g = a & b;
    wire [GROUPS:0] group_c;
    assign group_c[0] = cin;

    for (genvar k = 0; k < GROUPS; k++) begin : groups
        localparam int START = k * 4;
        localparam int N = (WIDTH - START >= 4) ? 4 : (WIDTH - START);
        wire [N:0] c;
        wire [N-1:0] pg = p[START +: N];
        wire [N-1:0] gg = g[START +: N];
        assign c[0] = group_c[k];
        for (genvar j = 0; j < N; j++) begin : bits
            // Expresion carry look-ahead local (no cadena de full adders).
            wire [j:0] terms;
            for (genvar t = 0; t <= j; t++) begin : gen_terms
                if (t == j) begin
                    assign terms[t] = gg[t];
                end else begin
                    assign terms[t] = (&pg[j:t+1]) & gg[t];
                end
            end
            assign c[j+1] = (|terms) | ((&pg[j:0]) & c[0]);
            assign sum[START+j] = pg[j] ^ c[j];
        end
        assign group_c[k+1] = c[N];
    end
    assign cout = group_c[GROUPS];
endmodule
`default_nettype wire
