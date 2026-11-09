`timescale 1ns/1ps
module tb_alu_plus_sync;
    localparam int WIDTH=16;
    logic clk=0, rst_n=0, valid_in=0;
    logic [WIDTH-1:0] A=0,B=0;
    logic [2:0] ALUControl=0;
    wire valid_out,N,Z,C,V,div_by_zero;
    wire [WIDTH-1:0] Result;
    alu_plus_sync #(.WIDTH(WIDTH)) dut (.*);
    always #5 clk=~clk;
    initial begin
        repeat(2) @(negedge clk);
        rst_n=1;
        A=16'd20; B=16'd3; ALUControl=3'b101; valid_in=1;
        @(negedge clk);
        A=16'd20; B=16'd3; ALUControl=3'b110; valid_in=1;
        @(negedge clk);
        assert(valid_out && Result==16'd6 && !div_by_zero)
            else $fatal(1,"FAIL DIV expected 6 result %0d valid=%b",Result,valid_out);
        valid_in=0;
        @(negedge clk);
        assert(valid_out && Result==16'd2 && !div_by_zero)
            else $fatal(1,"FAIL MOD expected 2 result %0d valid=%b",Result,valid_out);
        @(negedge clk);
        assert(!valid_out) else $fatal(1,"FAIL valid pipeline");
        $display("PASS: sync pipeline DIV/MOD");
        $finish;
    end
endmodule
