module test_tb();

    reg clk;
    top dut(clk);

    initial begin
        $dumpfile("test_tb.vcd");
        $dumpvars(0, dut);
        clk = 0;
        repeat(36)
            #1 clk = ~clk;
        $finish;
    end

endmodule