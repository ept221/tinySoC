module test_tb();

    reg clk;
    wire p0;
    wire p1;
    wire p2;
    wire p3;
    wire p4;
    wire p5;
    wire p6;
    wire p7;
    top dut(clk,p0,p1,p2,p3,p4,p5,p6,p7);

    initial begin
        $dumpfile("test_tb.vcd");
        $dumpvars(0, dut);
        clk = 0;
        repeat(5000)
            #1 clk = ~clk;
        $finish;
    end

endmodule