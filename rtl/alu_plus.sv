`default_nettype none
// Chamo: 000 AND, 001 OR, 010 ADD, 011 SLT signed,
// 100 reservado, 101 DIV, 110 MOD, 111 ZERO.
// C y V significativos solo para ADD y SLT (SLT usa A-B).
module alu_plus #(
    parameter int WIDTH = 8
) (
    input  wire [WIDTH-1:0] A,
    input  wire [WIDTH-1:0] B,
    input  wire [2:0]       ALUControl,
    output logic [WIDTH-1:0] Result,
    output wire             N,
    output wire             Z,
    output logic            C,
    output logic            V,
    output wire             div_by_zero
);
    wire do_and = ALUControl == 3'b000;
    wire do_or  = ALUControl == 3'b001;
    wire do_add = ALUControl == 3'b010;
    wire do_slt = ALUControl == 3'b011;
    wire do_div = ALUControl == 3'b101;
    wire do_mod = ALUControl == 3'b110;
    wire sub = do_slt;

    // Aislamiento de operandos: evita activaciones innecesarias de AND/OR.
    // No se modela un bus Z interno porque Yosys/ASIC no garantiza triestado interno.
    wire [WIDTH-1:0] and_a = do_and ? A : '0;
    wire [WIDTH-1:0] and_b = do_and ? B : '0;
    wire [WIDTH-1:0] or_a  = do_or  ? A : '0;
    wire [WIDTH-1:0] or_b  = do_or  ? B : '0;
    wire [WIDTH-1:0] and_result = and_a & and_b;
    wire [WIDTH-1:0] or_result = or_a | or_b;

    wire [WIDTH-1:0] b_modified = sub ? ~B : B;
    wire [WIDTH-1:0] sum;
    wire cout;
    cla_adder #(.WIDTH(WIDTH)) adder (
        .a(A), .b(b_modified), .cin(sub), .sum(sum), .cout(cout)
    );
    // Signed SLT: signo de diferencia corregido por overflow.
    wire signed_less = sum[WIDTH-1] ^
        ((A[WIDTH-1] ^ B[WIDTH-1]) & (sum[WIDTH-1] ^ A[WIDTH-1]));

    wire [WIDTH-1:0] quotient;
    wire [WIDTH-1:0] remainder;
    wire div_zero_internal;
    restoring_divider #(.WIDTH(WIDTH)) divider (
        .dividend(A), .divisor(B), .quotient(quotient),
        .remainder(remainder), .divide_by_zero(div_zero_internal)
    );
    assign div_by_zero = (do_div || do_mod) && div_zero_internal;

    always_comb begin
        Result = '0;
        case (ALUControl)
            3'b000: Result = and_result;
            3'b001: Result = or_result;
            3'b010: Result = sum;
            3'b011: Result = {{(WIDTH-1){1'b0}}, signed_less};
            3'b100: Result = '0;
            3'b101: Result = quotient;
            3'b110: Result = remainder;
            3'b111: Result = '0;
            default: Result = '0;
        endcase
        C = 1'b0;
        V = 1'b0;
        if (do_add || do_slt) begin
            C = cout;  // SLT: carry-out = NO borrow.
            V = sub ? ((A[WIDTH-1] ^ B[WIDTH-1]) &
                       (sum[WIDTH-1] ^ A[WIDTH-1]))
                    : ((~(A[WIDTH-1] ^ B[WIDTH-1])) &
                       (sum[WIDTH-1] ^ A[WIDTH-1]));
        end
    end
    assign N = Result[WIDTH-1];
    assign Z = (Result == '0);
endmodule
`default_nettype wire
