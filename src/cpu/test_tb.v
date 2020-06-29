module test_tb();

    reg clk = 0;
    
    wire [15:0] iMemAddress;
    wire [15:0] iMemOut;
    wire iMemReadEnable;

    wire [15:0] dMemIOAddress;
    wire [7:0] dMemIOIn;
    wire [15:0] dMemIOOut;
    wire dMemIOWriteEn;
    wire dMemIOReadEn;

    reg interrupt_0 = 0;
    reg interrupt_1 = 0;
    reg interrupt_2 = 0;

    cpu my_cpu(.clk(clk),
               .iMemAddress(iMemAddress),
               .iMemOut(iMemOut),
               .iMemReadEnable(iMemReadEnable),

               .dMemIOAddress(dMemIOAddress),
               .dMemIOIn(dMemIOIn),
               .dMemIOOut(dMemIOOut),
               .dMemIOWriteEn(dMemIOWriteEn),
               .dMemIOReadEn(dMemIOReadEn),

               .interrupt_0(interrupt_0),
               .interrupt_1(interrupt_1),
               .interrupt_2(interrupt_2)
    );

    i_ram my_i_ram(.din(16'd0),
                   .w_addr(iMemAddress),
                   .w_en(1'b0),
                   .r_addr(iMemAddress),
                   .r_en(iMemReadEnable),
                   .clk(clk),
                   .dout(iMemOut)
    );

    d_ram my_d_ram(.din(dMemIOIn),
                   .w_addr(dMemIOAddress),
                   .w_en(dMemIOWriteEn),
                   .r_addr(dMemIOAddress),
                   .r_en(dMemIOReadEn),
                   .clk(clk),
                   .dout(dMemIOOut)
    );

    initial begin
        $dumpfile("test_tb.vcd");
        $dumpvars(0, my_cpu);
        interrupt_0 = 1;
        repeat (15) begin
            #1 clk = ~clk;
        end
        #1 clk = ~clk;
        #1 clk = ~clk;
        repeat (15) begin
            #1 clk = ~clk;
        end
        repeat (15) begin
            #1 clk = ~clk;
        end
        $finish;
    end


endmodule