`timescale 1ns/1ps

module tb_tristate;
    localparam int WIDTH = 8;

    logic [WIDTH-1:0] A, B;
    logic enable_and, enable_or;
    tri [WIDTH-1:0] and_bus, or_bus;

    tristate_demo #(.WIDTH(WIDTH)) dut (
        .A(A),
        .B(B),
        .enable_and(enable_and),
        .enable_or(enable_or),
        .and_bus(and_bus),
        .or_bus(or_bus)
    );

    initial begin
        $dumpfile("build/tristate/tristate.vcd");
        $dumpvars(0, tb_tristate);

        A = 8'hAA;
        B = 8'h0F;

        enable_and = 0;
        enable_or  = 0;
        #10;

        if (and_bus !== 8'hzz || or_bus !== 8'hzz)
            $fatal(1, "FAIL: buses no estan en alta impedancia");

        enable_and = 1;
        #10;

        if (and_bus !== 8'h0A || or_bus !== 8'hzz)
            $fatal(1, "FAIL: AND");

        enable_and = 0;
        enable_or  = 1;
        #10;

        if (and_bus !== 8'hzz || or_bus !== 8'hAF)
            $fatal(1, "FAIL: OR");

        enable_or = 0;
        #10;

        if (and_bus !== 8'hzz || or_bus !== 8'hzz)
            $fatal(1, "FAIL: desconexion final");

        $display("PASS: TRISTATE AND/OR");
        $finish;
    end
endmodule
