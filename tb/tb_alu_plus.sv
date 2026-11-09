`timescale 1ns/1ps
module tb_alu_plus;
    localparam int WIDTH = 16;
    logic [WIDTH-1:0] A, B;
    logic [2:0] ALUControl;
    wire [WIDTH-1:0] Result;
    wire N,Z,C,V,div_by_zero;
    int checked = 0;
    alu_plus #(.WIDTH(WIDTH)) dut (.*);

    task automatic check(input logic [WIDTH-1:0] a, b, input logic [2:0] op);
        logic [WIDTH-1:0] expected;
        logic [WIDTH:0] wide_result;
        logic expected_c, expected_v, sub;
        begin
            A=a; B=b; ALUControl=op; #1;
            expected='0; expected_c=0; expected_v=0;
            wide_result='0; sub=(op==3'b011);
            case (op)
                3'b000: expected=a&b;
                3'b001: expected=a|b;
                3'b010: expected=a+b;
                3'b011: expected=($signed(a)<$signed(b)) ? 1 : 0;
                3'b101: expected=(b==0) ? '1 : a/b;
                3'b110: expected=(b==0) ? a : a%b;
                default: expected='0;
            endcase
            if (op==3'b010 || sub) begin
                wide_result={1'b0,a}+{1'b0,(sub ? ~b : b)}+{{WIDTH{1'b0}},sub};
                expected_c=wide_result[WIDTH];
                expected_v=sub ? ((a[WIDTH-1]^b[WIDTH-1]) & (wide_result[WIDTH-1]^a[WIDTH-1])) :
                          ((~(a[WIDTH-1]^b[WIDTH-1])) & (wide_result[WIDTH-1]^a[WIDTH-1]));
            end
            assert(Result===expected && N===expected[WIDTH-1] &&
                   Z===(expected=='0) && C===expected_c && V===expected_v &&
                   div_by_zero===((op==3'b101 || op==3'b110) && b==0))
            else $fatal(1,"FAIL op=%b A=%h B=%h result=%h expected=%h flags=%b%b%b%b",
                        op,a,b,Result,expected,N,Z,C,V);
            checked++;
        end
    endtask
    initial begin
        A='0; B='0; ALUControl='0;
        for (int op=0; op<8; op++) begin
            check('0,'0,3'(op));
            check('1,16'h0001,3'(op));
            check(16'h8000,16'h7fff,3'(op));
            check(16'h7fff,16'h8000,3'(op));
            check(16'h8000,16'hffff,3'(op));
            check(16'h1234,16'h0003,3'(op));
            check(16'h1234,16'h0000,3'(op));
            for (int j=0;j<200;j++) begin
                check(16'($urandom),16'($urandom),3'(op));
            end
        end
        $display("PASS: %0d vectors WIDTH=%0d",checked,WIDTH);
        $finish;
    end
endmodule
