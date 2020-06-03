module test_tb();

reg [3:0] inSelect;
reg [3:0] outAselect;
reg [3:0] outBselect;
reg [7:0] in;
reg [3:0] incSelect;
reg write_en;
reg inc;
reg dec;
reg clk;
wire outA;
wire outB;
wire outC;	

top dut(inSelect,outAselect,outBselect, in, incSelect, write_en, inc, dec, clk, outA, outB, outC);

initial begin
	$dumpfile("test_tb.vcd");
    $dumpvars(0, dut);

    in = 0;
    incSelect = 0;
    inSelect = 0;
    outAselect = 4'd0;
    outBselect = 4'd1;
    clk = 0;
    write_en = 0;
    inc = 1;
    dec = 0;
    #10
    clk = 1;
    #1
    clk = 0;
    inc = 0;
    #10
    $finish;
end

endmodule